# CLAUDE.md

This file provides guidance to coding agent (like Claude Code or Codex) when working with code in this repository.

## Engineering principles

Act like a high-performing senior engineer. Be concise, direct, and execution-focused.

Prefer simple, maintainable, production-friendly solutions. Write low-complexity code that is easy to read, debug, and modify. Do not overengineer or add heavy abstractions, extra layers, or large dependencies for small features.

Keep APIs small, behavior explicit, and naming clear. Avoid cleverness unless it clearly improves the result.

Always use Conventional Commits (`feat:` / `fix:` / `docs:` / `refactor:` / `chore:` ...).

## Project overview

A macOS menu-bar utility (`NSStatusItem`-based accessory app) written in Swift 5.9 with AppKit, targeting macOS 12+. The Xcode project is generated from `project.yml` by XcodeGen.

## Build / run / package

- Debug run: `./script/build_and_run.sh` (modes: `run` / `--debug` / `--logs` / `--telemetry` / `--verify`)
- Release package: `./script/package_release.sh` → outputs `dist/TimeMenubar.app.zip`
- The scripts pin DerivedData to `build/DerivedData` via the `DERIVED_DATA_PATH` env var — do not write to the default location.

## XcodeGen workflow

`project.yml` is the single source of truth for the Xcode project. **After editing `project.yml`, run `xcodegen generate` immediately to regenerate `TimeMenubar.xcodeproj`** — otherwise the changes will not take effect. Never hand-edit `project.pbxproj`.

## Menu-bar app constraints

- `Sources/Info.plist` sets `LSUIElement=true`: the app has no Dock icon and no main window. All UI is exposed through `NSStatusItem`.
- `Sources/Resources/TimeZones.plist` is bundled into `TimeMenubarCore` and loaded from the framework bundle. **New resource files must be declared explicitly under the owning target's `sources` in `project.yml`**, otherwise they will not be bundled into the target.
- The clock refreshes every 60 seconds (minute-level display; no per-second timer needed).
- Code signing is set to development mode (`CODE_SIGN_STYLE: Manual`, identity `-`). Release signing must be configured separately.

## Code style

Indentation: 4 spaces (enforced by `.swift-format`; an automatic `PostToolUse` hook runs `xcrun swift-format -i` on edited `.swift` files).
