# Screens

Base frame: **iPhone 14/15** — 390×844 pt, iOS 16+, dark-mode-first design (matches a boat/marine
"cockpit at night" feel and maximizes contrast for outdoor use). All screens use safe-area
insets: top 59, bottom 34.

Figma frame naming convention: `Boat / <Screen> / <State>`.

---

## 1. Connection / Scanner — `Boat / Scanner / Default`

**Purpose**: discover nearby BLE peripherals advertising the boat's service UUID and connect.

Layout (top → bottom, `spacing.md` horizontal margins):
1. Nav bar: title "Connect to Boat" (`typography.title2`), trailing gear icon button opening
   `Boat / Settings / UUIDConfig` sheet.
2. `StatusPill` (state = `scanning` or `disconnected`), left-aligned below nav bar, `spacing.sm` top margin.
3. Section header "Nearby Devices" (`typography.footnote`, `color.text.secondary`, uppercase, letter-spacing 0.5).
4. List of `Card/DeviceRow` inside a `Card/Base` container (grouped list style), `spacing.xs` row dividers (hairline `color.border.subtle`).
   - Empty state (no devices found yet): centered illustration placeholder (BLE glyph, 64pt, `color.text.tertiary`) + caption "Searching for boats…" `typography.subheadline`.
5. Bottom-pinned `Button/Secondary` "Rescan" — full width, `spacing.md` from safe area bottom.

State variants to include as separate frames:
- `Boat / Scanner / Scanning` (StatusPill = scanning, list populating, subtle shimmer skeleton rows).
- `Boat / Scanner / Error` — banner card at top, fill `color.status.disconnected` @12%, icon +
  message text e.g. "Bluetooth is off" / "Not authorized" (`typography.footnote`, `color.status.disconnected`).

---

## 2. Main Boat Control — `Boat / Control / Default`

**Purpose**: primary operating screen once connected.

Layout (top → bottom):
1. Nav bar: title "Boat Control", trailing `StatusPill` (state = `connected`) + small gear icon (settings).
2. `BoatView` centered, `spacing.lg` top margin, sits inside the remaining vertical space above the controls.
3. Telemetry row directly under `BoatView`, horizontal `spacing.lg` between items, centered:
   - `RudderReadout` ("0°")
   - vertical divider, `color.border.subtle`
   - `RSSIBadge` ("-58 dBm")
4. `SteeringHoldArea` pinned to bottom, spanning full width, height 220, sitting flush above the
   home indicator safe area (no extra margin — large touch target for safety).

Notes:
- No scrolling; this screen must always fit one viewport (safety-critical control must never be
  clipped or require scroll).
- Boat hull rotation is purely cosmetic feedback and does not rotate the whole view — only the
  rudder blade rotates.

---

## 3. Steering held-left / held-right — active-state variants

### `Boat / Control / Steering-Left`
- Same layout as `Boat / Control / Default`.
- `SteeringHoldArea` left zone → active fill (`color.steering.left` @20%), icon/label →
  `color.steering.leftActive`.
- `RudderReadout` animates toward e.g. "32° left", accent bar grows left, colored `color.steering.left`.
- `BoatView` rudder blade rotates left and tints `color.steering.left`.

### `Boat / Control / Steering-Right`
- Mirrored: right zone active (`color.steering.right` family), rudder readout e.g. "18° right",
  rudder blade rotates right and tints `color.steering.right`.

Both frames should be placed side-by-side in Figma for easy diffing against the default state.

---

## 4. Connected / Disconnected / Reconnecting states

These are presented as **overlay/banner variants** on top of the Control screen (not separate
full navigations), since BLE state changes happen while the user is mid-session.

### `Boat / Control / Connected` (= same as Default, StatusPill state=connected)
- Baseline state, fully interactive controls.

### `Boat / Control / Reconnecting`
- `StatusPill` switches to state=`reconnecting` (pulsing amber dot).
- `SteeringHoldArea` becomes non-interactive: 50% opacity overlay `color.background.primary`,
  centered spinner + "Reconnecting…" (`typography.subheadline`, `color.text.secondary`) on top of
  the hold areas.
- `BoatView` freezes at last known rudder angle, slightly desaturated (80% opacity).

### `Boat / Control / Disconnected`
- Full-screen modal card (`Card/Base`, centered, width 320) over a dimmed background
  (`color.background.primary` @70% opacity scrim):
  - Icon: BLE-off glyph, 40pt, `color.status.disconnected`.
  - Title: "Connection Lost" `typography.title2`.
  - Body: "The boat disconnected unexpectedly." `typography.body`, `color.text.secondary`.
  - `Button/Primary` "Reconnect" + `Button/Secondary` "Back to Scanner".

Also include, for the scanner flow, a lightweight **connecting** transition state:
### `Boat / Scanner / Connecting`
- Selected `Card/DeviceRow` shows a trailing spinner replacing the RSSI badge.
- `StatusPill` at top switches to state=`connecting`.

---

## 5. Settings / BLE UUID configuration sheet — `Boat / Settings / UUIDConfig`

**Purpose**: view/edit the persisted GATT UUIDs (service + command + position characteristics).

Presented as a `Sheet/Base` (iOS `.sheet`, medium/large detent), from either Scanner or Control
screen's gear icon.

Layout:
1. Grabber + header row: title "BLE Configuration", trailing "Done" button (`Button` text style).
2. Section "Service" (`typography.footnote` uppercase header):
   - `Field/UUIDInput` — "Service UUID".
3. Section "Characteristics":
   - `Field/UUIDInput` — "Command Characteristic UUID" (phone → ESP32).
   - `Field/UUIDInput` — "Position Characteristic UUID" (ESP32 → phone).
4. Helper card (`Card/Base`, subdued): short protocol reminder text, `typography.footnote`,
   `color.text.secondary`:
   > "Command: 1 byte ASCII L / R / C. Position: angle 0–180 (90 = center), byte or ASCII."
5. Bottom-pinned `Button/Destructive` "Reset to Defaults" and, above it, `Button/Primary` "Save".

State variants:
- `Boat / Settings / UUIDConfig-Invalid` — one `Field/UUIDInput` in error state (malformed UUID),
  "Save" button disabled variant.
- `Boat / Settings / UUIDConfig-Saved` — transient success toast/snackbar at bottom: "Saved ✓",
  `color.status.connected` background @90%, `color.text.onAccent` label, auto-dismiss.

---

## Frame index (for Figma pages)

Organize as one Figma **page** called `Screens`, with frames grouped left→right in this order:

1. `Boat / Scanner / Default`
2. `Boat / Scanner / Scanning`
3. `Boat / Scanner / Error`
4. `Boat / Scanner / Connecting`
5. `Boat / Control / Default`
6. `Boat / Control / Steering-Left`
7. `Boat / Control / Steering-Right`
8. `Boat / Control / Reconnecting`
9. `Boat / Control / Disconnected`
10. `Boat / Settings / UUIDConfig`
11. `Boat / Settings / UUIDConfig-Invalid`
12. `Boat / Settings / UUIDConfig-Saved`

A second page, `Components`, should hold the Figma component set built from `components.md`.
A third page, `Tokens`, can hold color/type swatches generated from `tokens/design-tokens.json`
for quick visual reference alongside the Figma Variables panel.
