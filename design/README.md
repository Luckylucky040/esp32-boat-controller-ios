# ESP32 Boat Controller — Figma Design Spec

This folder is a **Figma-ready, text-based design package** for the iOS SwiftUI BLE boat
controller app described in PR #1. It is intended to be recreated (or imported where possible)
in Figma, and kept up to date as the app evolves.

> No binary design files (`.fig`, `.sketch`) are included on purpose — everything here is
> plain-text (JSON/Markdown/SVG) so it's diff-friendly in git and easy for anyone to translate
> into real Figma frames, styles, and variables.

## Contents

| File | Purpose |
|---|---|
| [`tokens/design-tokens.json`](tokens/design-tokens.json) | Color, typography, spacing, radius, elevation, sizing and motion tokens. Import with a "Tokens Studio for Figma" style plugin, or recreate as Figma **Variables**/**Styles** manually. |
| [`components.md`](components.md) | Reusable component specs: buttons, cards, status pill, steering hold area, boat view. |
| [`screens.md`](screens.md) | Per-screen layout specs for all 5 required screens/states. |
| [`svg/`](svg) | Lightweight SVG wireframes (1x @ iPhone 390×844 pt) for each screen — importable directly into Figma via *File → Import* or copy/paste. |

### SVG wireframe index

| File | Screen / state |
|---|---|
| `svg/scanner.svg` | Connection / Scanner — default |
| `svg/control-default.svg` | Main boat control — centered rudder |
| `svg/control-steering-left.svg` | Main control — steering held left (active) |
| `svg/control-steering-right.svg` | Main control — steering held right (active) |
| `svg/control-reconnecting.svg` | Main control — reconnecting overlay |
| `svg/control-disconnected-modal.svg` | Main control — disconnected modal |
| `svg/settings-uuid-config.svg` | Settings / BLE UUID configuration sheet |

## How to bring this into Figma

1. **Create a new Figma file** named `ESP32 Boat Controller`.
2. **Variables**: create a collection `Boat/Tokens` and add Color, Number (spacing/radius) and
   Float variables from `tokens/design-tokens.json`. Two modes: `Dark` (default, values as-is)
   and optionally `Light` later.
3. **Text styles**: create one text style per entry in the `typography` section, named
   `Boat/Title2`, `Boat/Body`, `Boat/MonoTelemetry`, etc.
4. **Import wireframes**: drag each `svg/*.svg` file into the canvas as a starting frame per
   screen (390×844, iPhone 14/15 base size), then re-skin with real Figma components using the
   tokens/components below.
5. **Build components** from `components.md` as Figma components with variants (e.g.
   `Button/Primary` with `state=default|pressed|disabled`, `StatusPill` with
   `state=connected|connecting|reconnecting|disconnected`).
6. **Assemble screens** from `screens.md`, using auto-layout frames matching the specified
   spacing tokens.

## App concept recap (source of truth: PR #1)

- iOS 16+ SwiftUI app that steers an ESP32 boat over Bluetooth LE.
- Hold-to-steer left/right controls stream `L`/`R`/`C` (center) commands at 25 Hz while pressed.
- ESP32 streams back real rudder angle (0–180°, 90 = center), driving an animated top-down boat.
- Single GATT service, two characteristics: **Command** (phone → ESP32) and **Position**
  (ESP32 → phone), UUIDs editable/persisted in-app.
- Connection states: disconnected, scanning, connecting, connected, reconnecting, error
  (Bluetooth off / unauthorized / UUID mismatch).
- RSSI polled every 2s and shown in dBm.

## Screens covered

1. **Connection / Scanner** — device discovery list + connect action.
2. **Main boat control** — top-down boat view + steering hold areas + status readout.
3. **Steering held-left / held-right** — active-state variants of screen 2.
4. **Connection status states** — connected / disconnected / reconnecting overlays & banners.
5. **Settings / BLE UUID configuration sheet** — editable service/characteristic UUIDs.

See `screens.md` for full detail on each.
