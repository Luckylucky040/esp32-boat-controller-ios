import Foundation
import CoreBluetooth
import os.log

/// A boat discovered while scanning.
struct DiscoveredBoat: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
}

/// Reusable CoreBluetooth manager that handles the link to the ESP32 boat controller.
///
/// - Scans for peripherals advertising the configured service UUID
/// - Connects and discovers the command / rudder position characteristics
/// - Sends steering commands using `.withoutResponse` so they can be streamed
///   at the maximum rate the BLE link allows (back-pressure aware)
/// - Receives continuous rudder position updates through notifications
@MainActor
final class BLEManager: NSObject, ObservableObject {

    // MARK: - Published state

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var isBluetoothReady = false
    @Published private(set) var discoveredBoats: [DiscoveredBoat] = []
    @Published private(set) var connectedBoatName: String?
    @Published private(set) var signalStrength: Int?
    @Published private(set) var rudderAngle: Int?
    @Published var lastErrorMessage: String?

    // MARK: - Configuration

    /// How long to wait between connection attempts.
    var reconnectDelay: TimeInterval = 2.0
    /// Interval between RSSI reads while connected.
    var rssiPollInterval: TimeInterval = 2.0
    /// Maximum time a scan runs before stopping automatically.
    var scanTimeout: TimeInterval = 15.0

    // MARK: - Private

    private let logger = Logger(subsystem: "com.boatcontroller.ios", category: "BLE")
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var positionCharacteristic: CBCharacteristic?

    private var scanTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var rssiTask: Task<Void, Never>?
    private var shouldAutoReconnect = false
    private var isWaitingOnWrite = false

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }

    // MARK: - Public API

    /// Starts scanning for boats advertising the configured service UUID.
    /// Stops automatically after `scanTimeout` seconds if nothing is found.
    func startScanning() {
        guard isBluetoothReady else {
            lastErrorMessage = "Bluetooth is not available. Make sure it is enabled and the app has permission."
            return
        }
        cancelReconnect()
        discoveredBoats = []
        connectionState = .scanning
        centralManager.scanForPeripherals(
            withServices: [BLEUUIDs.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        logger.info("Scanning for service \(BLEUUIDs.serviceUUID.uuidString)")

        scanTask?.cancel()
        scanTask = Task { [weak self, scanTimeout] in
            try? await Task.sleep(for: .seconds(scanTimeout))
            guard !Task.isCancelled, let self else { return }
            if self.connectionState == .scanning {
                self.stopScanning()
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        guard centralManager.isScanning || connectionState == .scanning else { return }
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
        logger.info("Stopped scanning")
    }

    /// Connects to a discovered boat.
    func connect(to boat: DiscoveredBoat) {
        guard let peripheral = centralManager
            .retrievePeripherals(withIdentifiers: [boat.id])
            .first else {
            lastErrorMessage = "Could not find the selected boat anymore. Try scanning again."
            return
        }
        connect(to: peripheral)
    }

    /// Disconnects from the boat and disables automatic reconnection.
    func disconnect() {
        shouldAutoReconnect = false
        cancelReconnect()
        stopScanning()
        if let peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        cleanup()
        connectionState = .disconnected
    }

    /// Sends a steering command to the boat.
    ///
    /// Uses `.withoutResponse` writes, which are the fastest BLE write type and
    /// are designed for streaming continuous data. If the transmit queue is
    /// momentarily full the command is dropped and retried on the next tick;
    /// because steering commands are stateless and repeated continuously while
    /// the user holds a button, dropping one is harmless and keeps latency low.
    func send(_ command: SteeringCommand) {
        guard connectionState == .ready,
              let peripheral,
              let commandCharacteristic else { return }

        if isWaitingOnWrite {
            // The link is congested; skip this tick instead of queueing up
            // stale commands that would arrive late.
            return
        }

        peripheral.writeValue(command.payload, for: commandCharacteristic, type: .withoutResponse)
        if !peripheral.canSendWriteWithoutResponse {
            isWaitingOnWrite = true
        }
    }

    // MARK: - Helpers

    private func connect(to peripheral: CBPeripheral) {
        stopScanning()
        shouldAutoReconnect = true
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        connectedBoatName = peripheral.name ?? "ESP32 Boat"
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
        logger.info("Connecting to \(peripheral.identifier.uuidString)")
    }

    private func cleanup() {
        rssiTask?.cancel()
        rssiTask = nil
        commandCharacteristic = nil
        positionCharacteristic = nil
        signalStrength = nil
        rudderAngle = nil
        isWaitingOnWrite = false
        if connectionState != .disconnected {
            connectionState = .disconnected
        }
    }

    private func scheduleReconnect() {
        guard shouldAutoReconnect, reconnectTask == nil else { return }
        logger.info("Scheduling reconnect in \(self.reconnectDelay)s")
        reconnectTask = Task { [weak self, reconnectDelay] in
            try? await Task.sleep(for: .seconds(reconnectDelay))
            guard !Task.isCancelled, let self, self.shouldAutoReconnect else { return }
            self.reconnectTask = nil
            self.startScanning()
        }
    }

    private func cancelReconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func startRSSIPolling() {
        rssiTask?.cancel()
        rssiTask = Task { [weak self, rssiPollInterval] in
            while !Task.isCancelled {
                guard let self else { return }
                self.peripheral?.readRSSI()
                try? await Task.sleep(for: .seconds(rssiPollInterval))
            }
        }
    }

    /// Decodes the rudder angle reported by the ESP32.
    ///
    /// Supported payloads:
    /// - A single byte with the angle in degrees (0...180, 90 = center)
    /// - An ASCII string such as "45" or "135"
    private func decodeRudderAngle(from data: Data?) -> Int? {
        guard let data, !data.isEmpty else { return nil }
        if data.count == 1 {
            return Int(data[0])
        }
        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let value = Int(text) {
            return value
        }
        return nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.isBluetoothReady = central.state == .poweredOn
            switch central.state {
            case .poweredOn:
                self.logger.info("Bluetooth powered on")
                if self.shouldAutoReconnect && self.connectionState == .disconnected {
                    self.startScanning()
                }
            case .poweredOff:
                self.lastErrorMessage = "Bluetooth is turned off. Enable it in Settings to control the boat."
                self.cleanup()
            case .unauthorized:
                self.lastErrorMessage = "Bluetooth permission denied. Allow access in Settings > Privacy > Bluetooth."
                self.cleanup()
            case .unsupported:
                self.lastErrorMessage = "This device does not support Bluetooth Low Energy."
                self.cleanup()
            default:
                self.cleanup()
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        Task { @MainActor in
            let name = peripheral.name
                ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
                ?? "ESP32 Boat"
            let boat = DiscoveredBoat(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
            if let index = self.discoveredBoats.firstIndex(where: { $0.id == boat.id }) {
                self.discoveredBoats[index] = boat
            } else {
                self.discoveredBoats.append(boat)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.logger.info("Connected, discovering services")
            self.connectionState = .connected
            peripheral.discoverServices([BLEUUIDs.serviceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            self.logger.error("Failed to connect: \(error?.localizedDescription ?? "unknown")")
            self.lastErrorMessage = "Could not connect to the boat. It may be out of range or busy."
            self.cleanup()
            self.scheduleReconnect()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            if let error {
                self.logger.error("Disconnected with error: \(error.localizedDescription)")
                self.lastErrorMessage = "Connection to the boat was lost."
            }
            self.cleanup()
            self.scheduleReconnect()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            if let error {
                self.logger.error("Service discovery failed: \(error.localizedDescription)")
                self.lastErrorMessage = "Connected, but the boat services could not be read."
                return
            }
            guard let service = peripheral.services?.first(where: { $0.uuid == BLEUUIDs.serviceUUID }) else {
                self.logger.error("Boat service not found on peripheral")
                self.lastErrorMessage = "This device does not look like the boat controller (service UUID mismatch)."
                return
            }
            peripheral.discoverCharacteristics(
                [BLEUUIDs.commandCharacteristicUUID, BLEUUIDs.positionCharacteristicUUID],
                for: service
            )
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        Task { @MainActor in
            if let error {
                self.logger.error("Characteristic discovery failed: \(error.localizedDescription)")
                self.lastErrorMessage = "Connected, but the boat controls could not be read."
                return
            }
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid == BLEUUIDs.commandCharacteristicUUID {
                    self.commandCharacteristic = characteristic
                } else if characteristic.uuid == BLEUUIDs.positionCharacteristicUUID {
                    self.positionCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                }
            }
            if self.commandCharacteristic != nil {
                self.connectionState = .ready
                self.lastErrorMessage = nil
                self.startRSSIPolling()
                self.logger.info("Boat is ready for steering")
            } else {
                self.lastErrorMessage = "The boat's steering characteristic was not found (UUID mismatch)."
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didUpdateValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        Task { @MainActor in
            guard error == nil,
                  characteristic.uuid == BLEUUIDs.positionCharacteristicUUID,
                  let angle = self.decodeRudderAngle(from: characteristic.value) else { return }
            self.rudderAngle = angle
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task { @MainActor in
            guard error == nil else { return }
            self.signalStrength = RSSI.intValue
        }
    }

    nonisolated func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        Task { @MainActor in
            self.isWaitingOnWrite = false
        }
    }
}

// `BLEManager` is `@MainActor`, so every mutable property is already
// main-actor confined. Declaring it `@unchecked Sendable` lets it be captured
// by CoreBluetooth (which invokes delegates off-main) and by `@Sendable` task
// closures without strict-concurrency errors, while remaining data-race safe.
extension BLEManager: @unchecked Sendable {}
