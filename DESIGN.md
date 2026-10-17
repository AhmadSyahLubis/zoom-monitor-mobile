# Zoom Monitor visual direction

Zoom Monitor is a mobile operations app for coordinating company Zoom Premium accounts, bookings, schedules, and recordings. Its identity belongs to the internal product, not to Zoom.

## Character and hierarchy

- Calm, precise, corporate. The supplied PayPal, medical, and smart-home references inform the light canvas, compact data cards, navy photo feature, and selective clear-blue emphasis. Their content and brand marks are not copied.
- Inter is the single UI typeface, bundled in `assets/fonts`. Its text shapes suit dense mobile controls; weight and spacing distinguish titles from data and actions. Keep Indonesian labels short and readable.
- Portrait phone layouts should work from 360 px. Primary tap targets are at least 44 px; content clears the floating navigation and safe areas.
- Visual dials: ENERGY 2, RHYTHM 2, MOTION 1. The focused action or operational state leads each screen; illustration stays secondary.

## Palette

| Role | Color | Use |
|---|---|---|
| Navy | `#10243F` | Dark hero, selected navigation, strong text |
| Deep blue | `#173D72` | Primary actions and focus |
| Clear blue | `#087EAE` | Availability and selected detail |
| Soft blue | `#E8F4FA` | Quiet emphasis |
| Canvas | `#F2F5F9` | Screen background |
| White | `#FFFFFF` | Cards, forms, dialogs |
| Ink | `#14273E` | Main copy |
| Muted | `#536579` | Supporting copy |
| Border | `#D8E2EB` | Card and field structure |

Semantic states retain separate text and background colors in `lib/core/theme/app_colors.dart`. Availability uses restrained teal, active meeting muted red, and scheduled muted amber. Always pair color with a written state.

## Brand and icons

The launcher icon is a custom **M** monogram in off-white and pale blue on navy. A small circular aperture at its central joint hints at a camera lens without tracing Zoom's silhouette. `tool/design_assets/zoom_monitor_mark.svg` is the editable source; `tool/generate_brand_icon.py` exports the 1024 px assets, and `flutter_launcher_icons.yaml` builds platform variants. Keep the mark centered and legible at small sizes.

The five bottom navigation symbols, status symbols, and selected action symbols are a custom family derived from the mark's diagonal joint and circular aperture. Their editable SVGs are generated in `tool/design_assets/ui/` and exported to `assets/icons/` as 3x PNGs. The 1.8 px stroke and 24 px grid keep them legible at navigation size. Phosphor remains for secondary actions. Do not add novelty symbols or decorative badges.

## Surfaces and assets

- The bottom navigation is the single persistent frosted layer. Its selected destination is a solid navy capsule with a white icon and label. Header action controls may use a light translucent surface. Content cards and forms are solid white.
- The home page starts with a light greeting, then a navy photographic action panel. This separates orientation from action and gives the photo room without covering the operational data. Account totals use a real proportional status strip rather than a decorative chart.
- Dashboard and login use meeting imagery; Search, Schedules, Recordings, and Accounts each use one compact editorial banner relevant to the page. The photo sits behind a navy legibility layer and never replaces operational data. Generation prompts are recorded in `assets/images/ASSET_SOURCES.md`.
- Empty states use four original vector scenes: account credentials, time search, calendar, and recording playback. Their repeated aperture detail links them to the app identity without implying unavailable data.
- Data cards remain opaque and scannable. Search leads with availability, schedules lead with date and topic, recordings group playback metadata, and accounts group connection status with account ID. Radius is 10–20 px by component role; the floating navigation uses 26 px. Shadows stay subtle.
- Motion is brief and functional, around 200 ms. Loading, empty, error, and success states need useful text and actions.

## Product truth

The backend currently runs on a local network. Do not imply internet-wide availability, enterprise guarantees, encryption claims, cloud capacity, auto-generated passcodes, or features unsupported by the API. Mockups must label sample data. Design actions must follow the existing Flutter routes and repositories.

Reference principles: [Apple HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/), and [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars/). The visual language is implemented with Flutter controls, without copying iOS screens.
