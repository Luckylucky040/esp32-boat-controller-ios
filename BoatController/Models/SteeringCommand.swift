import Foundation

/// Steering commands sent to the ESP32 boat controller.
///
/// The raw values are the ASCII bytes the firmware expects on the
/// command characteristic:
/// - `L` (0x4C): steer left
/// - `R` (0x52): steer right
/// - `C` (0x43): return to center / stop steering
enum SteeringCommand: UInt8, CaseIterable {
    case left = 0x4C   // 'L'
    case right = 0x52  // 'R'
    case center = 0x43 // 'C'

    var payload: Data {
        Data([rawValue])
    }

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .center: return "Center"
        }
    }
}
