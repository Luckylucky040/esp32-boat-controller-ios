import Foundation
import CoreBluetooth

/// BLE identifiers used to communicate with the ESP32 boat controller.
///
/// The defaults are the placeholder UUIDs from the companion ESP32 firmware.
/// If your firmware uses different UUIDs, change them at runtime through the
/// connection sheet in the app, or edit the default values here.
enum BLEUUIDs {

    // MARK: - Stored defaults

    private enum Key {
        static let service = "ble.serviceUUID"
        static let command = "ble.commandCharacteristicUUID"
        static let position = "ble.positionCharacteristicUUID"
    }

    static let defaultServiceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    static let defaultCommandCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"
    static let defaultPositionCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9"

    // MARK: - Configurable values

    static var serviceUUID: CBUUID {
        get { CBUUID(string: storedValue(for: Key.service, fallback: defaultServiceUUID)) }
        set { store(newValue.uuidString, for: Key.service) }
    }

    static var commandCharacteristicUUID: CBUUID {
        get { CBUUID(string: storedValue(for: Key.command, fallback: defaultCommandCharacteristicUUID)) }
        set { store(newValue.uuidString, for: Key.command) }
    }

    static var positionCharacteristicUUID: CBUUID {
        get { CBUUID(string: storedValue(for: Key.position, fallback: defaultPositionCharacteristicUUID)) }
        set { store(newValue.uuidString, for: Key.position) }
    }

    // MARK: - Validation

    static func isValid(_ string: String) -> Bool {
        let pattern = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Persistence

    private static func storedValue(for key: String, fallback: String) -> String {
        guard let value = UserDefaults.standard.string(forKey: key),
              isValid(value) else {
            return fallback
        }
        return value
    }

    private static func store(_ value: String, for key: String) {
        if isValid(value) {
            UserDefaults.standard.set(value.uppercased(), forKey: key)
        }
    }
}
