# Primary / Secondary Visibility Toggle — Design

**Date:** 2026-04-26
**Status:** Approved
**Related:** `docs/superpowers/specs/2026-04-26-dual-timezone-menubar-design.md`

## 1. Goal

Allow the user to independently hide the primary or secondary time zone segment in the menu-bar status item title, while always keeping at least one segment visible. The setting must persist across app restarts.

## 2. Non-Goals

- Hiding entire submenus under `Time Zones` (the user can still pick / change zones even when a segment is hidden).
- Adding more than two segments, or per-zone color/format options.
- A preferences window. The toggle lives in the dropdown menu itself.

## 3. User Experience

### 3.1 Menu Layout

Two new checkbox items are inserted at the top of the main dropdown menu, above the existing `Time Zones` submenu:

```
[BJ 14:30 | LA 22:30]
├─ ✓ Show Primary
├─ ✓ Show Secondary
├─ ─────
├─ Time Zones ▶
├─ ─────
└─ Quit
```

- Labels are fixed strings (`Show Primary`, `Show Secondary`); they do **not** track the current city code.
- Each item's checkmark reflects the current visibility state.
- When exactly one segment is visible, the checkbox for that segment becomes disabled (grayed out). Clicking does nothing — the system simply prevents the user from hiding the last visible segment. No alert or error is shown.

### 3.2 Status Bar Title

The title is composed from the visible segments only, primary first when present:

| `showPrimary` | `showSecondary` | Title                       |
| ------------- | --------------- | --------------------------- |
| `true`        | `true`          | `BJ 14:30 \| LA 22:30`      |
| `true`        | `false`         | `BJ 14:30`                  |
| `false`       | `true`          | `LA 22:30`                  |
| `false`       | `false`         | unreachable (see §4.2)      |

When only one segment is visible, the ` | ` separator is omitted entirely.

## 4. Data Model

### 4.1 New State on `TimeZoneManager`

```swift
private(set) var showPrimary: Bool
private(set) var showSecondary: Bool

func setShowPrimary(_ visible: Bool)
func setShowSecondary(_ visible: Bool)
```

The two booleans are owned by the existing `TimeZoneManager` singleton. A separate `DisplaySettings` type is intentionally not introduced at this stage (YAGNI — only two booleans, all consumers already observe `TimeZoneManager`).

### 4.2 Invariant: At Least One Visible

Both setters enforce the same rule:

- `setShowPrimary(false)` is a no-op when `showSecondary == false`.
- `setShowSecondary(false)` is a no-op when `showPrimary == false`.

The `StatusBarController` reinforces the rule visually by disabling the checkbox of the last remaining visible segment. This produces defense in depth: even if some future caller bypasses the menu, the model itself refuses to enter the all-hidden state.

### 4.3 Persistence

UserDefaults keys (suite: standard):

- `showPrimaryTimeZone` — `Bool`
- `showSecondaryTimeZone` — `Bool`

**Read on init:**

```swift
showPrimary   = userDefaults.object(forKey: "showPrimaryTimeZone")   == nil
                  ? true : userDefaults.bool(forKey: "showPrimaryTimeZone")
showSecondary = userDefaults.object(forKey: "showSecondaryTimeZone") == nil
                  ? true : userDefaults.bool(forKey: "showSecondaryTimeZone")
```

The `object(forKey:) == nil` check distinguishes "key absent" from "key explicitly set to false", so existing users who upgrade the app see their previous behavior unchanged (both keys absent → both default to `true`).

**Write on change:** each setter calls `userDefaults.set(_:forKey:)` synchronously, then fires `onTimeZoneChanged?()`. macOS flushes UserDefaults to disk before the process exits, so a `Quit` immediately after a toggle is safe.

### 4.4 Change Notification

The existing `onTimeZoneChanged: (() -> Void)?` callback is reused. `StatusBarController` already listens to it and reacts by both refreshing the title (`updateTimeDisplay()`) and rebuilding the menu (`rebuildMenu()`). Reusing the same channel avoids a second subscription path and keeps the menu state and title state synchronized by construction.

The callback name is intentionally **not** renamed in this spec — renaming a published API is out of scope for a feature whose only consumer is internal. If a future change adds more orthogonal display settings, the callback can be renamed at that point.

## 5. Implementation Sketch

### 5.1 `Sources/TimeZoneManager.swift`

- Add private constants `showPrimaryTimeZoneKey` and `showSecondaryTimeZoneKey`.
- Add `private(set) var showPrimary: Bool` and `private(set) var showSecondary: Bool`.
- In `init()`, after loading the time zones, read the two booleans using the absent-key fallback.
- Add `setShowPrimary(_:)` and `setShowSecondary(_:)` per §4.1 / §4.2.

### 5.2 `Sources/StatusBarController.swift`

- In `createMenu()`, before the `Time Zones` item, insert:
  - A `Show Primary` `NSMenuItem` with `action: #selector(togglePrimaryVisibility)`, `target: self`, `state` = `.on`/`.off` based on `manager.showPrimary`, `isEnabled` = `false` when `manager.showPrimary && !manager.showSecondary` (the only-visible case).
  - A `Show Secondary` item built symmetrically.
  - A `NSMenuItem.separator()` between the new items and `Time Zones`.
- In `updateTimeDisplay()`, build the title from the visible segments per §3.2. Use a small array-and-join pattern rather than nested conditionals.
- Add `@objc private func togglePrimaryVisibility(_ sender: NSMenuItem)` and the secondary counterpart, each calling the matching `manager.set...` with the inverted current value.

No changes to `project.yml`, `Info.plist`, or `Sources/Resources/TimeZones.plist`.

## 6. Edge Cases

| Case                                            | Behavior                                                                                  |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Fresh install                                   | Both keys absent → both default `true` → title and menu look like today.                  |
| Upgrade from a version without the toggle       | Same as fresh install for these keys; existing time zone selections preserved.            |
| User toggles off, force-quits the app           | UserDefaults flushes on normal exit; `SIGKILL` may lose the last write — acceptable.      |
| User toggles secondary off, then changes secondary time zone | The newly-chosen zone is stored but stays hidden; toggling back on shows it.   |
| User hides primary, then primary's chosen zone observes DST change | Title still hidden; no rebuild needed beyond the existing 60 s timer tick.|
| `showSecondary == false` and user clicks `Show Secondary` | The item is enabled (it's the off one), toggles to `.on`, both segments visible.  |
| Both visible, user clicks `Show Primary`        | Item is enabled, toggles to `.off`, secondary becomes the only visible segment, secondary's checkbox is now disabled on the next menu open. |

## 7. Testing

The repository currently has no test target. A future test target should cover, at minimum:

- `TimeZoneManager.setShowPrimary(false)` is a no-op when `showSecondary == false`.
- The symmetric case for `setShowSecondary(false)`.
- The absent-key fallback in `init()` returns `true` for both flags when neither key is present.
- After `setShowPrimary(false)`, a fresh `TimeZoneManager` reads `showPrimary == false` from UserDefaults.

Until a test target exists, manual verification is required: launch the app, toggle each combination, quit, relaunch, confirm state.

## 8. Out of Scope / Future Work

- Reordering segments (always primary then secondary today).
- Custom separator characters or per-segment formatting.
- A "show date" toggle for either segment.
- Keyboard shortcuts for the toggles.
- Migrating to a dedicated `DisplaySettings` type — revisit if a third orthogonal display setting is added.
