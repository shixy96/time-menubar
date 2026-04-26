# TimeMenubar

A lightweight macOS menu bar utility for displaying multiple time zones.

## Features

- **Dual timezone display** - Show two time zones simultaneously in the menu bar
- **Toggle visibility** - Quickly show/hide primary and secondary timezones independently
- **Persistent settings** - Your preferences are automatically saved
- **Clean menu bar integration** - Seamlessly blends with macOS menu bar

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 15.0 or later (for development)

## Installation

### Pre-built Release

Download the latest release from the [Releases page](https://github.com/shixy96/time-menubar/releases) and unzip `TimeMenubar.app` into your Applications folder.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/shixy96/time-menubar.git
cd time-menubar

# Generate the Xcode project
xcodegen generate

# Build the project
xcodebuild build -project TimeMenubar.xcodeproj -scheme TimeMenubar -configuration Release -derivedDataPath build/DerivedData

# The built app will be at:
# build/DerivedData/Build/Products/Release/TimeMenubar.app
```

## Usage

After launching the app, you'll see time(s) displayed in your menu bar.

- **Click the menu bar item** to access options
- **Toggle Primary/Secondary** to show or hide specific time zones
- The app runs silently in the background - look for the time in your menu bar

## Configuration

Time zones are defined in `Sources/Resources/TimeZones.plist`. Edit this file to customize available time zones:

```xml
<dict>
    <key>America/New_York</key>
    <string>EST</string>
</dict>
```

## Development

### Project Structure

```
TimeMenubar/
├── Sources/
│   ├── main.swift              # Application entry point
│   ├── AppDelegate.swift       # App lifecycle management
│   ├── StatusBarController.swift  # Menu bar UI controller
│   ├── TimeZoneManager.swift   # Timezone logic and persistence
│   └── Resources/
│       └── TimeZones.plist     # Timezone configuration
├── Tests/
│   └── TimeZoneManagerTests.swift  # Unit tests
└── project.yml                # XcodeGen configuration
```

### Running Tests

```bash
xcodebuild test -project TimeMenubar.xcodeproj -scheme TimeMenubarTests -configuration Debug -derivedDataPath build/DerivedData
```

### Code Style

This project uses [swift-format](https://github.com/apple/swift-format) for code formatting. Formatting is automatically applied via a hook after edits.

To format manually:

```bash
xcrun swift-format format -i Sources Tests
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. Push to your fork and submit a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Inspired by the need for a simple dual-timezone menu bar clock
