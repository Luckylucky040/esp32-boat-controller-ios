import Foundation

/// High level state of the BLE link to the boat.
enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case ready

    var statusText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning…"
        case .connecting: return "Connecting…"
        case .connected: return "Connected"
        case .ready: return "Ready"
        }
    }

    /// True once the boat is connected and the characteristics were discovered,
    /// meaning steering commands can be sent.
    var isUsable: Bool {
        self == .ready
    }
}
