import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private let manager = TimeZoneManager.shared

    init() {
        setupStatusItem()
        setupMenu()
        updateTimeDisplay()
        startTimer()

        manager.onTimeZoneChanged = { [weak self] in
            self?.updateTimeDisplay()
            self?.rebuildMenu()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = NSFont.menuBarFont(ofSize: 0)
            button.toolTip = "TimeMenubar"
        }
    }

    private func setupMenu() {
        statusItem.menu = createMenu()
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        let showPrimaryItem = NSMenuItem(
            title: "Show Primary",
            action: #selector(togglePrimaryVisibility(_:)),
            keyEquivalent: ""
        )
        showPrimaryItem.target = self
        showPrimaryItem.state = manager.showPrimary ? .on : .off
        menu.addItem(showPrimaryItem)

        let showSecondaryItem = NSMenuItem(
            title: "Show Secondary",
            action: #selector(toggleSecondaryVisibility(_:)),
            keyEquivalent: ""
        )
        showSecondaryItem.target = self
        showSecondaryItem.state = manager.showSecondary ? .on : .off
        menu.addItem(showSecondaryItem)

        menu.addItem(NSMenuItem.separator())

        let timeZonesItem = NSMenuItem(title: "Time Zones", action: nil, keyEquivalent: "")
        timeZonesItem.submenu = createTimeZoneSubmenu()
        menu.addItem(timeZonesItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func createTimeZoneSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let primaryItem = NSMenuItem(title: "Primary Time Zone", action: nil, keyEquivalent: "")
        primaryItem.submenu = createGroupedTimeZoneMenu(
            selectedIdentifier: manager.primaryTimeZone.identifier,
            action: #selector(selectPrimaryTimeZone(_:))
        )
        submenu.addItem(primaryItem)

        let secondaryItem = NSMenuItem(title: "Secondary Time Zone", action: nil, keyEquivalent: "")
        secondaryItem.submenu = createGroupedTimeZoneMenu(
            selectedIdentifier: manager.secondaryTimeZone.identifier,
            action: #selector(selectSecondaryTimeZone(_:))
        )
        submenu.addItem(secondaryItem)

        return submenu
    }

    private func createGroupedTimeZoneMenu(selectedIdentifier: String, action: Selector) -> NSMenu {
        let menu = NSMenu()

        for group in manager.timeZoneGroups {
            let groupItem = NSMenuItem(title: group.region, action: nil, keyEquivalent: "")
            let groupMenu = NSMenu()

            for identifier in group.identifiers {
                let item = NSMenuItem(title: manager.displayName(for: identifier), action: action, keyEquivalent: "")
                item.target = self
                item.representedObject = identifier
                item.state = identifier == selectedIdentifier ? .on : .off
                groupMenu.addItem(item)
            }

            groupItem.submenu = groupMenu
            menu.addItem(groupItem)
        }

        return menu
    }

    private func rebuildMenu() {
        statusItem.menu = createMenu()
    }

    private func updateTimeDisplay() {
        let now = Date()
        var segments: [String] = []
        if manager.showPrimary {
            let time = manager.formatTime(now, in: manager.primaryTimeZone)
            let code = manager.shortCode(for: manager.primaryTimeZone.identifier)
            segments.append("\(code) \(time)")
        }
        if manager.showSecondary {
            let time = manager.formatTime(now, in: manager.secondaryTimeZone)
            let code = manager.shortCode(for: manager.secondaryTimeZone.identifier)
            segments.append("\(code) \(time)")
        }
        statusItem.button?.title = segments.joined(separator: " | ")
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeDisplay()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func selectPrimaryTimeZone(_ sender: NSMenuItem) {
        guard let identifier = sender.representedObject as? String else { return }
        manager.setPrimaryTimeZone(identifier)
    }

    @objc private func selectSecondaryTimeZone(_ sender: NSMenuItem) {
        guard let identifier = sender.representedObject as? String else { return }
        manager.setSecondaryTimeZone(identifier)
    }

    @objc private func togglePrimaryVisibility(_ sender: NSMenuItem) {
        manager.setShowPrimary(!manager.showPrimary)
    }

    @objc private func toggleSecondaryVisibility(_ sender: NSMenuItem) {
        manager.setShowSecondary(!manager.showSecondary)
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(togglePrimaryVisibility(_:)):
            // Disable when primary is the only visible segment.
            return manager.showSecondary || !manager.showPrimary
        case #selector(toggleSecondaryVisibility(_:)):
            return manager.showPrimary || !manager.showSecondary
        default:
            return true
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    deinit {
        timer?.invalidate()
    }
}
