# ESP32 Boat Controller — iOS App

An iOS SwiftUI app for steering an ESP32-based boat over Bluetooth Low Energy.
Hold the left/right buttons to steer continuously, watch the animated rudder on
the top-down boat view, and see the real rudder position streamed back from the
ESP32 in real time.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![iOS Build](https://github.com/Luckylucky040/esp32-boat-controller-ios/actions/workflows/ios-ci.yml/badge.svg)

## Features

- **Hold-to-steer controls** — large left/right touch areas that stream commands
  for as long as they are held (25 Hz by default), then send a single `Center`
  command on release.
- **Live boat visualization** — top-down boat with an animated rudder that
  mirrors the actual rudder angle reported by the ESP32.
- **Rudder feedback** — numeric angle readout (`45° left`, `0°`, `45° right`)
  synchronized with the position notifications from the boat.
- **Status dashboard** — BLE connection state, live signal strength (RSSI) and
  rudder angle at a glance.
- **Robust BLE layer** — automatic reconnect, back-pressure-aware writes using
  `writeWithoutResponse` for maximum command rate, and graceful error messages.
- **Configurable UUIDs** — change the service and characteristic UUIDs in the
  app (persisted) or in code to match your firmware.

## Requirements

- Xcode 15.4+ and an iPhone running iOS 16.0+
  (BLE does **not** work in the iOS Simulator — use a real device)
- An ESP32 flashed with the boat base-unit firmware (see below)

> **No Mac?** See [Building without a Mac](#building-without-a-mac) below.

## Getting Started

1. Clone this repository.
2. Open `BoatController.xcodeproj` in Xcode.
3. Select the **BoatController** scheme and your iPhone.
4. In **Signing & Capabilities**, pick your development team.
5. Build and run (⌘R). On first launch, iOS will ask for Bluetooth permission.

Tap the **antenna icon** (top right) to open the connection sheet, press
**Scan**, and select your boat. Once the state shows **Ready**, hold the
LEFT/RIGHT buttons to steer.

## Building without a Mac

You don't need to own a Mac to build this app. This repository includes a
GitHub Actions workflow ([`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml))
that compiles the app on GitHub's hosted **macOS runner** every time you push.

- The badge at the top of this README shows the latest build result.
- Open the **Actions** tab to see build logs for each commit — a green check
  means the code compiles cleanly on real Xcode.

To get the app **onto your iPhone** you need an Apple ID for code signing:

| Approach | Cost | Notes |
| --- | --- | --- |
| Free Apple ID + [Sideloadly](https://sideloadly.io/) / AltStore (Windows) | $0 | App expires every 7 days — fine for personal tinkering; just re-install. |
| Apple Developer Program + TestFlight | $99/year | Proper signing, no weekly expiry, easy OTA installs. |

Typical no-Mac flow:

1. Push your changes — GitHub Actions builds the unsigned app automatically.
2. Add a signing step (or use Sideloadly on Windows) with your Apple ID to
   produce a signed `.ipa`.
3. Install the `.ipa` on your iPhone over USB with Sideloadly, or upload to
   TestFlight if you have a paid developer account.

## BLE Protocol

The app talks to the ESP32 over a single GATT service with two characteristics:

| Characteristic | UUID (default)                            | Direction      | Payload                                   |
| -------------- | ----------------------------------------- | -------------- | ----------------------------------------- |
| Service        | `4fafc201-1fb5-459e-8fcc-c5c9c331914b`    | —              | —                                         |
| Command        | `beb5483e-36e1-4688-b7f5-ea07361b26a8`    | Phone → ESP32  | 1 byte ASCII: `L` (left), `R` (right), `C` (center) |
| Position       | `beb5483e-36e1-4688-b7f5-ea07361b26a9`    | ESP32 → Phone  | Rudder angle 0–180 (90 = center)          |

### Steering commands

- Sent with `CBCharacteristicWriteType.withoutResponse` (the fastest BLE write)
  as a single ASCII byte: `0x4C` = `L`, `0x52` = `R`, `0x43` = `C`.
- While a button is held, the command repeats every **40 ms**. The sender is
  back-pressure aware: if the BLE transmit queue is full, a tick is skipped
  instead of queueing stale commands, keeping latency minimal.
- On release a single `C` is sent so the firmware can return the rudder to
  center (or stop steering, depending on your firmware logic).

### Rudder position updates

- The app subscribes to notifications on the position characteristic, so the
  ESP32 can stream updates continuously.
- Two payload formats are accepted:
  - **Single byte** — the angle in degrees (`0`–`180`).
  - **ASCII string** — e.g. `"45"` or `"135"`.

### Changing the UUIDs

If your firmware uses different UUIDs, either:

- **In the app:** open the connection sheet → *BLE Configuration*, edit the
  fields (validated, persisted via `UserDefaults`), or
- **In code:** edit the defaults in
  [`BoatController/Models/BLEUUIDs.swift`](BoatController/Models/BLEUUIDs.swift).

## ESP32 Firmware Sketch (reference)

Minimal [Arduino core for ESP32](https://github.com/espressif/arduino-esp32)
firmware matching this protocol (adjust the servo pin and calibration to your
hardware). If you already have a working base unit, just make sure the UUIDs and
payload formats above line up.

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ESP32Servo.h>

#define SERVICE_UUID   "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define COMMAND_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define POSITION_UUID  "beb5483e-36e1-4688-b7f5-ea07361b26a9"

static const int SERVO_PIN = 13;
static const int MIN_ANGLE = 45;    // full left
static const int MAX_ANGLE = 135;   // full right
static const int STEP = 2;          // degrees per command

Servo rudderServo;
int rudderAngle = 90;               // 0..180, 90 = center
BLECharacteristic* positionChar = nullptr;
bool clientConnected = false;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { clientConnected = true; }
  void onDisconnect(BLEServer* server) override {
    clientConnected = false;
    server->startAdvertising();     // keep advertising for auto-reconnect
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String value = c->getValue();
    if (value.length() == 0) return;
    switch (value.charAt(0)) {
      case 'L': rudderAngle = max(MIN_ANGLE, rudderAngle - STEP); break;
      case 'R': rudderAngle = min(MAX_ANGLE, rudderAngle + STEP); break;
      case 'C': rudderAngle = 90; break;
    }
    rudderServo.write(rudderAngle);
    notifyPosition();
  }
};

void notifyPosition() {
  if (clientConnected && positionChar) {
    uint8_t angle = (uint8_t)rudderAngle;
    positionChar->setValue(&angle, 1);
    positionChar->notify();
  }
}

void setup() {
  rudderServo.attach(SERVO_PIN);
  rudderServo.write(rudderAngle);

  BLEDevice::init("ESP32 Boat");
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* service = server->createService(SERVICE_UUID);

  BLECharacteristic* commandChar = service->createCharacteristic(
      COMMAND_UUID, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  commandChar->setCallbacks(new CommandCallbacks());

  positionChar = service->createCharacteristic(
      POSITION_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  positionChar->addDescriptor(new BLE2902());
  uint8_t initial = (uint8_t)rudderAngle;
  positionChar->setValue(&initial, 1);

  service->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->start();
}

void loop() {
  // Optionally call notifyPosition() periodically if the rudder can move
  // without a command (e.g. physical feedback from the boat).
}
```

## Project Structure

```
BoatController/
├── BoatControllerApp.swift        # App entry point
├── Models/
│   ├── BLEUUIDs.swift             # Configurable service/characteristic UUIDs
│   ├── SteeringCommand.swift      # L / R / C command model
│   └── ConnectionState.swift      # BLE connection state model
├── Services/
│   └── BLEManager.swift           # CoreBluetooth wrapper (scan/connect/write/notify/RSSI/reconnect)
├── ViewModels/
│   └── BoatControlViewModel.swift # Hold-to-steer loop, rudder smoothing, UI state
├── Views/
│   ├── ContentView.swift          # Main screen
│   ├── BoatView.swift             # Top-down boat + animated rudder
│   ├── SteeringControlsView.swift # Hold-to-steer buttons
│   ├── ConnectionStatusView.swift # Connection / signal / rudder status bar
│   └── ConnectionSheetView.swift  # Scanner + UUID configuration sheet
├── Assets.xcassets
└── Info.plist                     # Bluetooth usage descriptions
```

## Technical Notes

- **Modern concurrency** — the BLE layer uses `async`/`await` tasks for scan
  timeouts, reconnect backoff and RSSI polling, and delegates hop to the main
  actor via `@MainActor`.
- **Permissions** — `NSBluetoothAlwaysUsageDescription` is declared in
  `Info.plist`; iOS prompts the user on first launch.
- **Reconnection** — unexpected disconnects automatically trigger a re-scan and
  reconnect after a short delay; manual disconnect disables this.
- **Signal strength** — polled every 2 s while connected (`readRSSI()`), shown
  in the status bar and the connection sheet.

## License

MIT — feel free to adapt the app and firmware to your boat.
