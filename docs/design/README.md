# Boat Controller — UI Design

This folder contains a visual mockup of the app's main screen plus the exact
design specs, so you can recreate or restyle the UI in **Figma** (or any design
tool) and, if you like, have the app updated to match.

> I can't access your Figma account directly, so these files are the bridge:
> download them, then either import them into Figma or rebuild using the specs.

## Files

- [`ui-mockup.png`](ui-mockup.png) — rendered screenshot of the main screen
  (iPhone 14 logical size, 390×844 pt @2x)
- [`ui-mockup.html`](ui-mockup.html) — pixel-accurate HTML/CSS source of the
  mockup. Open it in a browser to screenshot it, **or** paste it into a Figma
  import plugin such as **html.to.design** or **Builder.io / Anima** to get
  editable Figma layers automatically.

## Screen layout (top → bottom)

| Element | Notes |
| --- | --- |
| Navigation bar | Title "Boat Controller" centered, cyan antenna button top-right |
| Status bar | 3 segments separated by thin dividers: Connection (green dot + "Ready"), Signal (📡 + "-58 dBm"), Rudder (⛵ + "45° left") |
| Boat view | Rounded "water" card with a top-down boat hull, deck, and a rotating rudder at the stern |
| Rudder readout | Large angle text (e.g. "45° left") + "RUDDER POSITION" caption |
| Steering buttons | Two large hold-to-steer buttons: LEFT (orange) and RIGHT (green) |

## Color palette (exact, from the code)

| Use | RGB | Hex |
| --- | --- | --- |
| Background gradient top | 13, 20, 33 | `#0D1421` |
| Background gradient bottom | 20, 36, 56 | `#142438` |
| Water gradient top | 13, 82, 117 | `#0D5275` |
| Water gradient bottom | 20, 122, 158 | `#147A9E` |
| Hull gradient start | 235, 240, 245 | `#EBF0F5` |
| Hull gradient end | 199, 209, 222 | `#C7D1DE` |
| Deck | 56, 69, 84 | `#384554` |
| Rudder (center/neutral) | 64, 140, 217 | `#408CD9` |
| LEFT button | 245, 115, 82 | `#F57352` |
| RIGHT button | 89, 199, 117 | `#59C775` |
| Accent (links/antenna) | 115, 191, 255 | `#73BFFF` |
| Card background | white @ 8% | `rgba(255,255,255,0.08)` |
| Card border | white @ 12% | `rgba(255,255,255,0.12)` |
| Secondary text | ~ `#9AA7B8` | `#9AA7B8` |

## Typography

- Font: SF Pro (iOS system font) — in Figma use **SF Pro** or **Inter**
- Screen title: 17 pt semibold
- Rudder angle readout: 34 pt bold, tabular figures
- Button title: 15 pt bold, letter-spacing 2
- Button hint / status labels: 11 / 9 pt semibold, letter-spacing 0.5–2
- Status values: 13 pt semibold

## Shapes & spacing

- Water card: 250×320, corner radius 24
- Buttons: 150 pt tall, corner radius 24, 16 pt gap, 16 pt side margins
- Status bar: corner radius 18, 12 pt vertical padding
- Rudder blade: ~17×51, rotates ±45° around a pivot at the stern
- Screen corners: iPhone 14 frame, 40 pt corner radius

## How to get this into Figma

1. **Fastest (editable layers):** install the **html.to.design** plugin in
   Figma → open `ui-mockup.html` in a browser → run the plugin on that page →
   it imports as editable Figma frames.
2. **Manual:** drag `ui-mockup.png` onto a Figma canvas as a reference layer,
   then rebuild with the specs above (colors/typography/spacing).
3. **Tweak the design:** if you change things in Figma and want the *app* to
   match your new design, share a screenshot and I'll update the SwiftUI views.
