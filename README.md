# Dimmit

Menu bar app for controlling external display brightness on macOS.

https://github.com/user-attachments/assets/1209a8ab-e982-4282-a6e9-5dd79559c046

## Features

- Per-monitor brightness controls from the menu bar
- Optional brightness presets bar
- Daily brightness schedules
- Global keyboard shortcuts (brightness up/down) with configurable step size
- Launch at login

## Project Status / Disclaimer

This project is **not fully tested** and may **not work correctly in all scenarios**, hardware setups, or macOS versions.

Dimmit has only been tested on the author's personal Mac and external monitor configuration. Different monitors, adapters, docks, or macOS versions may behave differently or not work at all.

## Security / Code Signing

This app is **not signed with a paid Apple Developer account**.

When you first run Dimmit, macOS may block it. To allow it to run:

1. Open **System Settings → Privacy & Security**
2. Scroll to **Security**
3. Click **Open Anyway** next to Dimmit

You may also see warnings about an unidentified developer. This is expected for locally built or unsigned apps.

## Troubleshooting

- Keyboard shortcuts do nothing: grant Accessibility permission to Dimmit in System Settings -> Privacy & Security -> Accessibility.
- No external displays found: ensure your monitor + connection path supports DDC/CI (some docks/adapters block DDC).

## Development

### Requirements

- macOS (built with Xcode / SwiftUI)
- External monitor(s) that support DDC/CI brightness control

### Getting Started

1. Open `dimmit.xcodeproj` in Xcode.
2. Select the `dimmit` scheme.
3. Build + Run.

On first use, if you enable keyboard shortcuts you may be prompted to grant Accessibility permission.

### Rebuilding the DDC Handler (Rust)

The Swift app calls into a small Rust static library (`ddc_handler`) via a C header.

Prereqs:

- Rust toolchain (`cargo`)
- `cbindgen` (`cargo install cbindgen`)

Build and copy artifacts into the app:

```sh
./scripts/build_ddc_handler.sh
```

This script produces:

- `dimmit/Libraries/libddc_handler.a`
- `dimmit/Libraries/include/ddc_handler.h`

Note: the script currently builds for `aarch64-apple-darwin`. If you're on Intel, update the target (and any Xcode build settings) accordingly.

### Repository Layout

- `dimmit/`: macOS app (Swift/SwiftUI)
- `ddc_handler/`: Rust static library + C header generation
- `scripts/`: helper scripts (e.g. build Rust library)
