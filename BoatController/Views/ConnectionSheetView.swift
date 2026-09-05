import SwiftUI

/// Sheet for scanning, connecting to the boat and configuring the BLE UUIDs.
struct ConnectionSheetView: View {

    @ObservedObject var viewModel: BoatControlViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var serviceUUID = BLEUUIDs.serviceUUID.uuidString
    @State private var commandUUID = BLEUUIDs.commandCharacteristicUUID.uuidString
    @State private var positionUUID = BLEUUIDs.positionCharacteristicUUID.uuidString

    var body: some View {
        NavigationStack {
            List {
                connectionSection
                devicesSection
                uuidSection
            }
            .navigationTitle("Boat Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var connectionSection: some View {
        Section {
            HStack {
                Label(viewModel.connectionState.statusText, systemImage: "dot.radiowaves.left.and.right")
                Spacer()
                connectionButton
            }
            if let name = viewModel.bleManager.connectedBoatName,
               viewModel.connectionState != .disconnected {
                LabeledContent("Boat", value: name)
            }
            if let rssi = viewModel.bleManager.signalStrength {
                LabeledContent("Signal", value: "\(rssi) dBm")
            }
        } header: {
            Text("Status")
        }
    }

    @ViewBuilder
    private var connectionButton: some View {
        switch viewModel.connectionState {
        case .disconnected:
            Button("Scan", action: viewModel.startScanning)
                .buttonStyle(.borderedProminent)
        case .scanning:
            Button("Stop", action: viewModel.stopScanning)
                .buttonStyle(.bordered)
        case .connecting, .connected, .ready:
            Button("Disconnect", role: .destructive, action: viewModel.disconnect)
                .buttonStyle(.bordered)
        }
    }

    private var devicesSection: some View {
        Section {
            if viewModel.bleManager.discoveredBoats.isEmpty {
                Text(viewModel.connectionState == .scanning
                     ? "Looking for your boat…"
                     : "No boats found yet. Tap Scan to search.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.bleManager.discoveredBoats) { boat in
                    Button {
                        viewModel.connect(to: boat)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "sailboat.fill")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading) {
                                Text(boat.name)
                                    .foregroundStyle(.primary)
                                Text(boat.id.uuidString)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("\(boat.rssi) dBm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        } header: {
            Text("Nearby Boats")
        }
    }

    private var uuidSection: some View {
        Section {
            uuidField(title: "Service UUID", text: $serviceUUID) {
                if BLEUUIDs.isValid(serviceUUID) {
                    BLEUUIDs.serviceUUID = .init(string: serviceUUID)
                }
            }
            uuidField(title: "Command Characteristic", text: $commandUUID) {
                if BLEUUIDs.isValid(commandUUID) {
                    BLEUUIDs.commandCharacteristicUUID = .init(string: commandUUID)
                }
            }
            uuidField(title: "Position Characteristic", text: $positionUUID) {
                if BLEUUIDs.isValid(positionUUID) {
                    BLEUUIDs.positionCharacteristicUUID = .init(string: positionUUID)
                }
            }

            Button("Reset to Defaults") {
                BLEUUIDs.serviceUUID = .init(string: BLEUUIDs.defaultServiceUUID)
                BLEUUIDs.commandCharacteristicUUID = .init(string: BLEUUIDs.defaultCommandCharacteristicUUID)
                BLEUUIDs.positionCharacteristicUUID = .init(string: BLEUUIDs.defaultPositionCharacteristicUUID)
                serviceUUID = BLEUUIDs.serviceUUID.uuidString
                commandUUID = BLEUUIDs.commandCharacteristicUUID.uuidString
                positionUUID = BLEUUIDs.positionCharacteristicUUID.uuidString
            }
        } header: {
            Text("BLE Configuration")
        } footer: {
            Text("These UUIDs must match the ones in your ESP32 firmware. Changes apply to the next scan.")
                .font(.caption)
        }
    }

    private func uuidField(title: String,
                           text: Binding<String>,
                           onCommit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("00000000-0000-0000-0000-000000000000", text: text)
                .font(.caption.monospaced())
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onSubmit(onCommit)
                .onChange(of: text.wrappedValue) { _ in onCommit() }
                .foregroundStyle(BLEUUIDs.isValid(text.wrappedValue) ? .primary : .red)
        }
    }
}

#Preview {
    ConnectionSheetView(viewModel: BoatControlViewModel())
}
