# CrosshairOverlay

A macOS menu-bar crosshair overlay written in Swift.

CrosshairOverlay draws a click-through crosshair on the monitor that contains the pointer. It provides visual customization, saved presets, per-display and per-application profiles, global shortcuts, JSON import/export, and frontmost-app exclusions.

## Requirements

- macOS 13 or later
- Xcode command-line tools with Swift 6 support

## Build and test

```sh
swift test
swift build -c release
```

The release executable is emitted in the Swift build products directory:

```sh
"$(swift build -c release --show-bin-path)/CrosshairOverlay"
```

## Controls

- Ctrl+Shift+Command+C — toggle crosshair lines
- Ctrl+Shift+Command+H — toggle native cursor hiding
- Ctrl+Shift+Command+P — cycle presets
- Ctrl+Shift+Command+[ / ] — decrease / increase line width
- Ctrl+Shift+Command+- / = — decrease / increase opacity

## Features

- Active-monitor-only overlay rendering
- Adjustable line color, width, pattern, opacity, center gap, and cursor offset
- Multiple intersection reticles, dot color, and shade controls
- Built-in and saved named presets
- Fade after inactivity and Option-key hold-to-show
- Per-display settings and full per-application configuration profiles
- Frontmost-application exclusions
- Versioned JSON import/export for advanced settings
- Diagnostics in the menu-bar menu

## Cursor behavior

The overlay is click-through. macOS does not provide a public API that reliably hides or replaces the cursor while another application owns the foreground pointer. The optional experimental background cursor mode uses private WindowServer APIs and is not suitable for App Store distribution or guaranteed to work across macOS releases. The supported foreground-only mode avoids those APIs but cannot provide system-wide cursor control while other applications are active.

## License

No license has been selected yet. Do not reuse or redistribute this project until a license is added.
