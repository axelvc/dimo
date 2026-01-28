# Dimmit

> Work in progress.

Menu bar app for controlling external display brightness on macOS.

## Features

- Per-monitor brightness controls from the menu bar
- Optional brightness presets bar
- Daily brightness schedules
- Global keyboard shortcuts (brightness up/down) with configurable step size
- Optional on-screen brightness HUD
- Launch at login

## Requirements

- macOS (built with Xcode / SwiftUI)
- External monitor(s) that support DDC/CI brightness control

## Getting Started

1. Open `dimmit.xcodeproj` in Xcode.
2. Select the `dimmit` scheme.
3. Build + Run.

On first use, if you enable keyboard shortcuts you may be prompted to grant Accessibility permission.

## Rebuilding the DDC Handler (Rust)

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

## Troubleshooting

- Keyboard shortcuts do nothing: grant Accessibility permission to Dimmit in System Settings -> Privacy & Security -> Accessibility.
- No external displays found: ensure your monitor + connection path supports DDC/CI (some docks/adapters block DDC).

## Repository Layout

- `dimmit/`: macOS app (Swift/SwiftUI)
- `ddc_handler/`: Rust static library + C header generation
- `scripts/`: helper scripts (e.g. build Rust library)

## License

No license file is currently included in this repository.
