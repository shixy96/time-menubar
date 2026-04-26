import XCTest

@testable import TimeMenubarCore

final class TimeZoneManagerTests: XCTestCase {
    private var additionalSuiteNames: [String] = []
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TimeZoneManagerTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        for suiteName in additionalSuiteNames {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        additionalSuiteNames = []
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsUseExpectedPrimaryAndSecondaryTimeZones() {
        let manager = TimeZoneManager(userDefaults: userDefaults)

        XCTAssertEqual(manager.primaryTimeZone.identifier, "Asia/Shanghai")
        XCTAssertEqual(manager.secondaryTimeZone.identifier, "America/Los_Angeles")
        XCTAssertTrue(manager.showPrimary)
        XCTAssertTrue(manager.showSecondary)
    }

    func testLoadsBundledTimeZoneGroups() {
        let manager = TimeZoneManager(userDefaults: userDefaults)

        XCTAssertEqual(manager.timeZoneGroups.map(\.region), ["Asia", "Americas", "Europe", "Oceania"])
        XCTAssertTrue(
            manager.timeZoneGroups.contains { group in
                group.identifiers.contains("Asia/Shanghai")
            }
        )
        XCTAssertTrue(
            manager.timeZoneGroups.contains { group in
                group.identifiers.contains("America/Los_Angeles")
            }
        )
    }

    func testSetTimeZonesPersistsIdentifiersAndNotifies() {
        let manager = TimeZoneManager(userDefaults: userDefaults)
        var changeCount = 0
        manager.onTimeZoneChanged = {
            changeCount += 1
        }

        manager.setPrimaryTimeZone("Europe/London")
        manager.setSecondaryTimeZone("Asia/Tokyo")

        XCTAssertEqual(manager.primaryTimeZone.identifier, "Europe/London")
        XCTAssertEqual(manager.secondaryTimeZone.identifier, "Asia/Tokyo")
        XCTAssertEqual(userDefaults.string(forKey: "primaryTimeZoneIdentifier"), "Europe/London")
        XCTAssertEqual(userDefaults.string(forKey: "secondaryTimeZoneIdentifier"), "Asia/Tokyo")
        XCTAssertEqual(changeCount, 2)
    }

    func testRestoresPersistedTimeZonesOnNextLaunch() {
        let manager = TimeZoneManager(userDefaults: userDefaults)

        manager.setPrimaryTimeZone("Europe/London")
        manager.setSecondaryTimeZone("Asia/Tokyo")

        let restoredManager = TimeZoneManager(userDefaults: userDefaults)
        XCTAssertEqual(restoredManager.primaryTimeZone.identifier, "Europe/London")
        XCTAssertEqual(restoredManager.secondaryTimeZone.identifier, "Asia/Tokyo")
    }

    func testInvalidTimeZoneIdentifierIsIgnored() {
        let manager = TimeZoneManager(userDefaults: userDefaults)
        var didNotify = false
        manager.onTimeZoneChanged = {
            didNotify = true
        }

        manager.setPrimaryTimeZone("Invalid/Zone")

        XCTAssertEqual(manager.primaryTimeZone.identifier, "Asia/Shanghai")
        XCTAssertNil(userDefaults.string(forKey: "primaryTimeZoneIdentifier"))
        XCTAssertFalse(didNotify)
    }

    func testVisibilityCannotHideBothTimeZones() {
        let manager = TimeZoneManager(userDefaults: userDefaults)
        var changeCount = 0
        manager.onTimeZoneChanged = {
            changeCount += 1
        }

        manager.setShowPrimary(false)
        manager.setShowSecondary(false)

        XCTAssertFalse(manager.showPrimary)
        XCTAssertTrue(manager.showSecondary)
        XCTAssertFalse(userDefaults.bool(forKey: "showPrimaryTimeZone"))
        XCTAssertNil(userDefaults.object(forKey: "showSecondaryTimeZone"))
        XCTAssertEqual(changeCount, 1)
    }

    func testVisibilityCannotHidePrimaryWhenSecondaryIsAlreadyHidden() {
        let manager = TimeZoneManager(userDefaults: userDefaults)

        manager.setShowSecondary(false)
        manager.setShowPrimary(false)

        XCTAssertTrue(manager.showPrimary)
        XCTAssertFalse(manager.showSecondary)
        XCTAssertNil(userDefaults.object(forKey: "showPrimaryTimeZone"))
        XCTAssertFalse(userDefaults.bool(forKey: "showSecondaryTimeZone"))
    }

    func testVisibilityPersistenceSurvivesNewManager() {
        let manager = TimeZoneManager(userDefaults: userDefaults)

        manager.setShowPrimary(false)

        let restoredManager = TimeZoneManager(userDefaults: userDefaults)
        XCTAssertFalse(restoredManager.showPrimary)
        XCTAssertTrue(restoredManager.showSecondary)
    }

    func testInitializingWithBothVisibilityFlagsOffRestoresPrimary() {
        userDefaults.set(false, forKey: "showPrimaryTimeZone")
        userDefaults.set(false, forKey: "showSecondaryTimeZone")

        let manager = TimeZoneManager(userDefaults: userDefaults)

        XCTAssertTrue(manager.showPrimary)
        XCTAssertFalse(manager.showSecondary)
        XCTAssertTrue(userDefaults.bool(forKey: "showPrimaryTimeZone"))
    }

    func testFormattingAndDisplayHelpersAreStable() {
        let manager = TimeZoneManager(userDefaults: userDefaults)
        let date = Date(timeIntervalSince1970: 0)
        let shanghai = TimeZone(identifier: "Asia/Shanghai")!

        XCTAssertEqual(manager.formatTime(date, in: shanghai), "08:00")
        XCTAssertEqual(manager.shortCode(for: "Asia/Shanghai"), "BJ")
        XCTAssertEqual(manager.shortCode(for: "Europe/Madrid"), "MAD")
        XCTAssertEqual(manager.displayName(for: "Asia/Kolkata"), "Kolkata (UTC+5:30)")
        XCTAssertEqual(manager.displayName(for: "Invalid/Zone"), "Invalid/Zone")
    }

    func testMenuBarTitleUsesVisibleSegmentsInOrder() {
        let date = Date(timeIntervalSince1970: 0)
        let bothVisibleManager = TimeZoneManager(userDefaults: userDefaults)

        XCTAssertEqual(bothVisibleManager.menuBarTitle(at: date), "BJ 08:00 | LA 16:00")

        bothVisibleManager.setShowSecondary(false)
        XCTAssertEqual(bothVisibleManager.menuBarTitle(at: date), "BJ 08:00")

        let secondaryOnlyManager = TimeZoneManager(userDefaults: makeUserDefaults())
        secondaryOnlyManager.setShowPrimary(false)
        XCTAssertEqual(secondaryOnlyManager.menuBarTitle(at: date), "LA 16:00")
    }

    func testDisplayNameUsesProvidedDateForDSTSensitiveOffsets() {
        let manager = TimeZoneManager(userDefaults: userDefaults)
        let winter = makeUTCDate(year: 2024, month: 1, day: 1)
        let summer = makeUTCDate(year: 2024, month: 7, day: 1)

        XCTAssertEqual(
            manager.displayName(for: "America/Los_Angeles", at: winter),
            "Los Angeles (UTC-8)"
        )
        XCTAssertEqual(
            manager.displayName(for: "America/Los_Angeles", at: summer),
            "Los Angeles (UTC-7)"
        )
    }

    private func makeUTCDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        return components.date!
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "TimeZoneManagerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        additionalSuiteNames.append(suiteName)
        return userDefaults
    }
}
