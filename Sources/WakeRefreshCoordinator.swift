import Foundation

/// Subscribes to a set of `(NotificationCenter, Notification.Name)` pairs and
/// forwards every received notification to a single `onRefresh` callback.
///
/// Used by the menu-bar UI to refresh the displayed time after the system
/// wakes from sleep or the wall clock changes. Designed for testability:
/// callers inject the centers and names, so unit tests can drive the
/// coordinator with an in-memory `NotificationCenter` and a synthetic name.
public final class WakeRefreshCoordinator {
    public typealias Subscription = (center: NotificationCenter, name: Notification.Name)

    public var onRefresh: (() -> Void)?

    private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    public init(subscriptions: [Subscription]) {
        for subscription in subscriptions {
            let token = subscription.center.addObserver(
                forName: subscription.name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onRefresh?()
            }
            tokens.append((subscription.center, token))
        }
    }

    deinit {
        for (center, token) in tokens {
            center.removeObserver(token)
        }
    }
}
