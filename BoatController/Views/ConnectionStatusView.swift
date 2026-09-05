import SwiftUI

/// Status bar showing BLE connection state, signal strength and rudder angle.
struct ConnectionStatusView: View {

    @ObservedObject var viewModel: BoatControlViewModel

    var body: some View {
        HStack(spacing: 0) {
            statusItem
            divider
            signalItem
            divider
            angleItem
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .padding(.horizontal)
    }

    // MARK: - Items

    private var statusItem: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusColor.opacity(0.8), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("CONNECTION")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.connectionState.statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var signalItem: some View {
        HStack(spacing: 8) {
            Image(systemName: signalIcon)
                .foregroundStyle(signalColor)
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text("SIGNAL")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(signalText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var angleItem: some View {
        HStack(spacing: 8) {
            Image(systemName: "sailboat.fill")
                .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text("RUDDER")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.rudderAngleText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 34)
    }

    // MARK: - Derived state

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .ready: return .green
        case .connected: return .mint
        case .connecting, .scanning: return .orange
        case .disconnected: return .red
        }
    }

    private var signalText: String {
        guard let rssi = viewModel.bleManager.signalStrength else { return "—" }
        return "\(rssi) dBm"
    }

    private var signalIcon: String {
        viewModel.bleManager.signalStrength == nil
            ? "antenna.radiowaves.left.and.right.slash"
            : "antenna.radiowaves.left.and.right"
    }

    private var signalColor: Color {
        guard let rssi = viewModel.bleManager.signalStrength else { return .gray }
        switch rssi {
        case ..<(-80): return .red
        case ..<(-60): return .orange
        default: return .green
        }
    }
}

#Preview {
    ConnectionStatusView(viewModel: BoatControlViewModel())
        .padding()
        .background(Color(red: 0.06, green: 0.09, blue: 0.14))
}
