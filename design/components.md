# Components

All measurements in points (pt), matching SwiftUI. Tokens referenced as `token.path`.

## Buttons

### `Button/Primary`
- Height: `sizing.primaryButtonHeight` (50), full-width minus `spacing.md` margins.
- Corner radius: `radius.md` (14).
- Fill: `color.brand.primary`; label `color.text.onAccent`, `typography.headline`.
- Pressed variant: fill `color.brand.primaryPressed`, scale 0.98.
- Disabled variant: fill at 40% opacity, label `color.text.tertiary`.
- Used for: "Connect", "Save UUIDs".

### `Button/Secondary` (outline)
- Same size as Primary. Fill: transparent. Border: 1pt `color.border.strong`.
- Label: `color.text.primary`.
- Used for: "Cancel", "Rescan".

### `Button/Destructive`
- Same size. Fill: `color.status.disconnected` at 15% opacity, label `color.status.disconnected`.
- Used for: "Disconnect", "Reset UUIDs to defaults".

## Cards

### `Card/Base`
- Fill: `color.background.elevated`.
- Corner radius: `radius.lg` (20).
- Padding: `spacing.md` (16).
- Shadow: `elevation.card`.
- Border: 1pt `color.border.subtle` (hairline, optional in dark mode).

### `Card/DeviceRow` (scanner list item)
- Layout: horizontal auto-layout, `spacing.sm` gap, height 64.
- Left: BLE glyph in 32×32 circle, fill `color.brand.primary` at 12% opacity, icon `color.brand.primary`.
- Middle (fills space): device name (`typography.headline`, `color.text.primary`), UUID or
  "Unnamed device" subtitle (`typography.footnote`, `color.text.secondary`).
- Right: RSSI value + bars (`typography.monoTelemetry` reduced to 13pt, `color.text.secondary`).
- Tap target: whole row; row highlight on press = `color.background.secondary`.

## Status Indicators

### `StatusPill`
- Pill shape, `radius.pill`, height 28, horizontal padding `spacing.sm`.
- Layout: `statusDotDiameter` (10) dot + `spacing.xxs` gap + label `typography.footnote` (semibold).
- Variants (dot + label color + fill @12% opacity of same color):
  - `connected` → `color.status.connected`, label "Connected"
  - `connecting` → `color.status.connecting`, label "Connecting…" (dot pulses, 0.8s ease-in-out loop)
  - `reconnecting` → `color.status.reconnecting`, label "Reconnecting…" (dot pulses)
  - `disconnected` → `color.status.disconnected`, label "Disconnected"
  - `scanning` → `color.status.neutral`, label "Scanning…" (dot pulses)

### `RSSIBadge`
- Icon (signal bars, 3 bars) + numeric `-NN dBm` in `typography.monoTelemetry`.
- Bar fill count mapped to RSSI: ≥ -60 dBm → 3 bars `color.status.connected`; -60…-80 → 2 bars
  `color.status.connecting`; < -80 → 1 bar `color.status.disconnected`.

### `RudderReadout`
- Centered text, `typography.monoTelemetry`, `color.text.primary`.
- Format: `"45° left"`, `"0°"`, `"45° right"` (derived from normalized -1…+1 position).
- Color accent bar underneath: left → `color.steering.left`, center → `color.steering.center`,
  right → `color.steering.right`, width proportional to |angle|/45.

## Steering Controls

### `SteeringHoldArea`
- Two zones side by side, each `sizing.steeringHoldArea` (50% width × 220 height), no gap
  (hairline divider `color.border.subtle` 1pt between them), bottom-anchored on the control screen.
- Corner radius: `radius.lg` on outer corners only (top-left+bottom-left for left zone,
  top-right+bottom-right for right zone).
- Default fill: `color.background.elevated`.
- **Left zone**
  - Icon: left chevron/arrow, 32pt, `color.steering.left`.
  - Label below icon: "LEFT" `typography.caption1`, `color.text.secondary`, letter-spacing 1.
  - Active/pressed fill: `color.steering.left` at 20% opacity; icon+label become
    `color.steering.leftActive`; subtle inner glow (`elevation.card` recolored to
    `color.steering.left` at 40% alpha).
- **Right zone**: mirrored, using `color.steering.right` / `color.steering.rightActive`.
- Interaction note (for prototype flows in Figma): zero-distance drag / press-down triggers
  active state immediately (no tap delay) — mirrors SwiftUI `DragGesture(minimumDistance: 0)`;
  release returns to default fill and a momentary "center" pulse on `RudderReadout`.

## Boat View

### `BoatView` (top-down canvas)
- Square canvas, `sizing.boatViewSize` (260×260), centered card, no fill (transparent, sits over
  `color.background.primary`) or subtle radial gradient `color.background.elevated → color.background.primary`.
- Hull: simple elongated hexagon/boat silhouette, fill `color.text.secondary` at 80% opacity,
  pointed bow facing up (12 o’clock).
- Rudder: small blade shape anchored at stern (6 o’clock), rotates ±45° from vertical based on
  live rudder angle; rotation 0° = center.
- Rudder tint follows active steering direction: neutral `color.steering.center`, while
  steering left `color.steering.left`, while steering right `color.steering.right`.
- Wake ripple lines (optional decorative): 2–3 thin arcs behind stern, `color.border.subtle`.

## Sheet Chrome

### `Sheet/Base`
- Fill: `color.background.secondary`.
- Top corners: `radius.lg`, grabber bar (36×5, `radius.pill`, `color.border.strong`) centered,
  `spacing.xs` from top.
- Header row: title `typography.title2` left-aligned, "Done"/"Cancel" text button right-aligned
  (`typography.headline`, `color.brand.primary`).
- Section padding: `spacing.md` horizontal, `spacing.lg` between sections.

### `Field/UUIDInput`
- Label above field: `typography.footnote`, `color.text.secondary` (e.g. "Command Characteristic UUID").
- Input box: height 44, `radius.sm`, fill `color.background.elevated`, border 1pt
  `color.border.subtle` (focused: `color.brand.primary`), text `typography.monoTelemetry` at 15pt,
  `color.text.primary`, monospace for UUID legibility.
- Validation state: invalid UUID → border `color.status.disconnected` + helper text below in
  `typography.caption1` / `color.status.disconnected`.
