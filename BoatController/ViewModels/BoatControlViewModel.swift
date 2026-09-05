import Foundation
import SwiftUI
import Combine

/// View model for the main boat control screen.
///
/// Bridges the `BLEManager` to the SwiftUI views and implements the
/// hold-to-steer behaviour: while a steering button is held, commands are
/// repeated at `commandInterval`; when released a single center command is sent.
@MainActor
final class BoatControlViewModel: ObservableObject {

    // MARK: - Published UI state

    @Published private(set) var steeringInput: SteeringCommand?
    /// Smoothed rudder angle in degrees (0...180, 90 = center) for the animated UI.
    @Published private(set) var displayedRudderAngle: Double = 90
    @Published var showConnectionSheet = false

    let bleManager: BLEManager

    /// Interval between steering commands while a button is held.
    /// 40 ms (25 Hz) keeps the rudder responsive without flooding the BLE link.
    var commandInterval: TimeInterval = 0.04

    private var steeringTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// Normalized rudder position for animations: -1 = full left, 0 = center, +1 = full right.
    var normalizedRudder: Double {
        (displayedRudderAngle - 90) / 45
    }

    /// Human readable angle label, e.g. "45° left", "0°", "45° right".
    var rudderAngleText: String {
        guard bleManager.rudderAngle != nil else { return "—" }
        let offset = Int(displayedRudderAngle.rounded()) - 90
        switch offset {
        case ..<0: return "\(abs(offset))° left"
        case 0: return "0°"
        default: return "\(offset)° right"
        }
    }

    var connectionState: ConnectionState { bleManager.connectionState }

    var isSteeringEnabled: Bool { bleManager.connectionState.isUsable }

    /// Creates the view model, constructing a `BLEManager` on the main actor.
    /// `BLEManager` is `@MainActor`, so it must be created in a main-actor
    /// context — which this initializer is.
    init() {
        self.bleManager = BLEManager()
        subscribe()
    }

    /// Creates the view model with an injected `BLEManager` (used by previews
    /// and tests). The caller is responsible for creating it on the main actor.
    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        subscribe()
    }

    private func subscribe() {
        // Animate the rudder smoothly towards the latest angle reported by the ESP32.
        // The `.sink` closure is `@Sendable` and nonisolated, so hop to the main
        // actor before mutating `@MainActor` state (Xcode 16 strict concurrency).
        bleManager.$rudderAngle
            .compactMap { $0 }
            .map { Double(min(180, max(0, $0))) }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] target in
                Task { @MainActor [weak self] in
                    withAnimation(.easeOut(duration: 0.15)) {
                        self?.displayedRudderAngle = target
                    }
                }
            }
            .store(in: &cancellables)

        // If the connection drops while steering, stop sending.
        bleManager.$connectionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                Task { @MainActor [weak self] in
                    if !state.isUsable {
                        self?.stopSteering(sendCenter: false)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Steering

    /// Starts continuously sending the given steering command.
    /// Call when the user presses and holds a steering button.
    func startSteering(_ command: SteeringCommand) {
        guard command != .center, isSteeringEnabled else { return }
        guard steeringInput != command else { return }
        stopSteering(sendCenter: false)

        steeringInput = command
        bleManager.send(command)

        steeringTask = Task { [weak self, commandInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(commandInterval))
                guard !Task.isCancelled, let self, self.isSteeringEnabled else { return }
                self.bleManager.send(command)
            }
        }
    }

    /// Stops steering. Sends a single center command so the firmware knows the
    /// user released the button (used when the boat should return to center).
    func stopSteering(sendCenter: Bool = true) {
        let wasSteering = steeringInput != nil
        steeringTask?.cancel()
        steeringTask = nil
        steeringInput = nil
        if sendCenter && wasSteering && isSteeringEnabled {
            bleManager.send(.center)
        }
    }

    // MARK: - Connection actions

    func startScanning() {
        bleManager.startScanning()
    }

    func stopScanning() {
        bleManager.stopScanning()
    }

    func connect(to boat: DiscoveredBoat) {
        bleManager.connect(to: boat)
    }

    func disconnect() {
        stopSteering(sendCenter: false)
        bleManager.disconnect()
    }

    func dismissError() {
        bleManager.lastErrorMessage = nil
    }
}

// `BoatControlViewModel` is `@MainActor`, so all mutable state is already
// main-actor confined. Declaring it `@unchecked Sendable` lets `@Sendable`
// Combine/task closures capture it without strict-concurrency errors.
extension BoatControlViewModel: @unchecked Sendable {}
