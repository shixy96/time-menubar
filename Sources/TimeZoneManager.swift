import Foundation

public struct TimeZoneGroup: Identifiable {
    public var id: String { region }
    public let region: String
    public let identifiers: [String]
}

public final class TimeZoneManager {
    public static let shared = TimeZoneManager()

    private let userDefaults: UserDefaults
    private let bundle: Bundle
    private let primaryTimeZoneKey = "primaryTimeZoneIdentifier"
    private let secondaryTimeZoneKey = "secondaryTimeZoneIdentifier"
    private let legacyPrimaryTimeZoneKey = "PrimaryTimeZone"
    private let legacySecondaryTimeZoneKey = "SecondaryTimeZone"
    private let showPrimaryTimeZoneKey = "showPrimaryTimeZone"
    private let showSecondaryTimeZoneKey = "showSecondaryTimeZone"
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private let fallbackPrimaryIdentifier = "Asia/Shanghai"
    private let fallbackSecondaryIdentifier = "America/Los_Angeles"

    private let cityDisplayNames: [String: String] = [
        "Asia/Shanghai": "Beijing",
        "Asia/Hong_Kong": "Hong Kong",
        "Asia/Tokyo": "Tokyo",
        "Asia/Seoul": "Seoul",
        "Asia/Singapore": "Singapore",
        "Asia/Dubai": "Dubai",
        "Asia/Kolkata": "Kolkata",
        "America/Los_Angeles": "Los Angeles",
        "America/New_York": "New York",
        "America/Chicago": "Chicago",
        "America/Vancouver": "Vancouver",
        "America/Toronto": "Toronto",
        "America/Mexico_City": "Mexico City",
        "America/Sao_Paulo": "Sao Paulo",
        "Europe/London": "London",
        "Europe/Paris": "Paris",
        "Europe/Berlin": "Berlin",
        "Europe/Moscow": "Moscow",
        "Europe/Istanbul": "Istanbul",
        "Australia/Sydney": "Sydney",
        "Australia/Melbourne": "Melbourne",
        "Pacific/Auckland": "Auckland",
    ]

    private let shortCodes: [String: String] = [
        "Asia/Shanghai": "BJ",
        "Asia/Hong_Kong": "HK",
        "Asia/Tokyo": "Tokyo",
        "Asia/Seoul": "Seoul",
        "Asia/Singapore": "SG",
        "Asia/Dubai": "Dubai",
        "Asia/Kolkata": "Kolkata",
        "America/Los_Angeles": "LA",
        "America/New_York": "NY",
        "America/Chicago": "CHI",
        "America/Vancouver": "Vancouver",
        "America/Toronto": "Toronto",
        "America/Mexico_City": "Mexico City",
        "America/Sao_Paulo": "Sao Paulo",
        "Europe/London": "London",
        "Europe/Paris": "Paris",
        "Europe/Berlin": "Berlin",
        "Europe/Moscow": "Moscow",
        "Europe/Istanbul": "Istanbul",
        "Australia/Sydney": "Sydney",
        "Australia/Melbourne": "Melbourne",
        "Pacific/Auckland": "Auckland",
    ]

    public private(set) var primaryTimeZone: TimeZone
    public private(set) var secondaryTimeZone: TimeZone
    public private(set) var showPrimary: Bool = true
    public private(set) var showSecondary: Bool = true

    public private(set) var timeZoneGroups: [TimeZoneGroup] = []

    public var onTimeZoneChanged: (() -> Void)?

    public convenience init() {
        self.init(userDefaults: .standard)
    }

    init(userDefaults: UserDefaults, bundle: Bundle = Bundle(for: BundleLocator.self)) {
        self.userDefaults = userDefaults
        self.bundle = bundle

        let primaryIdentifier =
            userDefaults.string(forKey: primaryTimeZoneKey)
            ?? userDefaults.string(forKey: legacyPrimaryTimeZoneKey)
        let secondaryIdentifier =
            userDefaults.string(forKey: secondaryTimeZoneKey)
            ?? userDefaults.string(forKey: legacySecondaryTimeZoneKey)

        primaryTimeZone = Self.timeZone(
            for: primaryIdentifier,
            fallbackIdentifier: fallbackPrimaryIdentifier
        )
        secondaryTimeZone = Self.timeZone(
            for: secondaryIdentifier,
            fallbackIdentifier: fallbackSecondaryIdentifier
        )
        loadTimeZoneGroups()
        showPrimary =
            userDefaults.object(forKey: showPrimaryTimeZoneKey) == nil
            ? true
            : userDefaults.bool(forKey: showPrimaryTimeZoneKey)
        showSecondary =
            userDefaults.object(forKey: showSecondaryTimeZoneKey) == nil
            ? true
            : userDefaults.bool(forKey: showSecondaryTimeZoneKey)
        if !showPrimary && !showSecondary {
            showPrimary = true
            userDefaults.set(true, forKey: showPrimaryTimeZoneKey)
        }
    }

    private func loadTimeZoneGroups() {
        guard let url = bundle.url(forResource: "TimeZones", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: Any],
            let groups = plist["TimeZones"] as? [[String: Any]]
        else {
            return
        }

        timeZoneGroups = groups.compactMap { dict in
            guard let region = dict["region"] as? String,
                let cities = dict["cities"] as? [String]
            else {
                return nil
            }
            let validIdentifiers = cities.filter { TimeZone(identifier: $0) != nil }
            return TimeZoneGroup(region: region, identifiers: validIdentifiers)
        }
    }

    public func setPrimaryTimeZone(_ identifier: String) {
        if let tz = TimeZone(identifier: identifier) {
            primaryTimeZone = tz
            userDefaults.set(identifier, forKey: primaryTimeZoneKey)
            onTimeZoneChanged?()
        }
    }

    public func setSecondaryTimeZone(_ identifier: String) {
        if let tz = TimeZone(identifier: identifier) {
            secondaryTimeZone = tz
            userDefaults.set(identifier, forKey: secondaryTimeZoneKey)
            onTimeZoneChanged?()
        }
    }

    public func setShowPrimary(_ visible: Bool) {
        if !visible && !showSecondary { return }
        guard visible != showPrimary else { return }
        showPrimary = visible
        userDefaults.set(visible, forKey: showPrimaryTimeZoneKey)
        onTimeZoneChanged?()
    }

    public func setShowSecondary(_ visible: Bool) {
        if !visible && !showPrimary { return }
        guard visible != showSecondary else { return }
        showSecondary = visible
        userDefaults.set(visible, forKey: showSecondaryTimeZoneKey)
        onTimeZoneChanged?()
    }

    public func displayName(for identifier: String) -> String {
        displayName(for: identifier, at: Date())
    }

    public func displayName(for identifier: String, at date: Date) -> String {
        guard let tz = TimeZone(identifier: identifier) else {
            return identifier
        }
        let cityName = cityDisplayNames[identifier] ?? Self.cityName(from: identifier)
        return "\(cityName) (\(utcOffset(for: tz, at: date)))"
    }

    public func shortCode(for identifier: String) -> String {
        shortCodes[identifier] ?? String(Self.cityName(from: identifier).prefix(3)).uppercased()
    }

    public func menuBarTitle(at date: Date = Date()) -> String {
        var segments: [String] = []
        if showPrimary {
            segments.append(menuBarSegment(for: primaryTimeZone, at: date))
        }
        if showSecondary {
            segments.append(menuBarSegment(for: secondaryTimeZone, at: date))
        }
        return segments.joined(separator: " | ")
    }

    public func formatTime(_ date: Date, in timeZone: TimeZone) -> String {
        timeFormatter.timeZone = timeZone
        return timeFormatter.string(from: date)
    }

    private func menuBarSegment(for timeZone: TimeZone, at date: Date) -> String {
        "\(shortCode(for: timeZone.identifier)) \(formatTime(date, in: timeZone))"
    }

    private func utcOffset(for timeZone: TimeZone, at date: Date = Date()) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }
        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    private static func timeZone(for identifier: String?, fallbackIdentifier: String) -> TimeZone {
        if let identifier, let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        }
        return TimeZone(identifier: fallbackIdentifier) ?? .current
    }

    private static func cityName(from identifier: String) -> String {
        identifier
            .split(separator: "/")
            .last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
    }
}

private final class BundleLocator: NSObject {}
