# Dual Time Zone Menu Bar Clock Design

## Context

The app is a macOS menu bar utility that replaces the native time display with a compact clock showing two selected time zones. The design should follow native macOS conventions and stay simple, readable, and practical.

## Design Specification

### Menu Bar Display

- **Style**: Use the native macOS time font and system color behavior.
- **Format**: `BJ 14:30 | LA 22:30` (city label plus time, separated by a vertical bar).
- **City label**: Use short, readable city labels for IANA time zone IDs, such as `BJ` for `Asia/Shanghai` and `LA` for `America/Los_Angeles`.
- **Auto refresh**: Refresh the menu bar title once per minute.

### Dropdown Menu

```text
+-----------------+
| Time Zones      | -> Submenu: grouped time zone lists by region
|-----------------|
| Quit            |
+-----------------+
```

- **Time zone submenu**: Group options by region, such as Asia, Americas, Europe, and Oceania. Show names like `Beijing (UTC+8)` and update the selected time zone when clicked.
- **Quit**: Quit the app and support Cmd+Q.

### Persistence

- Store the selected two time zones in UserDefaults.
- Restore the previous selection on the next launch.

### Technical Approach

- **Framework**: Swift + AppKit for native macOS development.
- **Menu bar**: NSStatusItem.
- **Time zone data**: Foundation TimeZone API.
- **Storage**: UserDefaults.

### File Structure

```text
TimeMenubar/
├── project.yml                 # XcodeGen configuration
├── Sources/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # App delegate
│   ├── Info.plist              # App configuration
│   ├── StatusBarController.swift # Menu bar controller
│   ├── TimeZoneManager.swift   # Time zone data and persistence
│   └── Resources/
│       └── TimeZones.plist     # Time zone group configuration
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-04-26-dual-timezone-menubar-design.md
```

## Verification

1. Run the app and verify that the menu bar shows the default two time zones.
2. Open the menu bar item, choose a new time zone, and verify that the menu bar title updates.
3. Quit the app with Cmd+Q, relaunch it, and verify that the selected time zones are restored.
4. Test several region combinations and verify that the displayed time offsets are correct.
