import XCTest

@testable import TimeMenubarCore

final class WakeRefreshCoordinatorTests: XCTestCase {
    private static let primaryName = Notification.Name("WakeRefreshCoordinatorTests.Primary")
    private static let secondaryName = Notification.Name("WakeRefreshCoordinatorTests.Secondary")

    func testPostingSubscribedNotificationTriggersRefresh() {
        let center = NotificationCenter()
        let coordinator = WakeRefreshCoordinator(subscriptions: [(center, Self.primaryName)])
        var refreshCount = 0
        coordinator.onRefresh = { refreshCount += 1 }

        center.post(name: Self.primaryName, object: nil)
        center.post(name: Self.primaryName, object: nil)

        XCTAssertEqual(refreshCount, 2)
    }

    func testMultipleSubscriptionsEachTriggerRefresh() {
        let centerA = NotificationCenter()
        let centerB = NotificationCenter()
        let coordinator = WakeRefreshCoordinator(subscriptions: [
            (centerA, Self.primaryName),
            (centerB, Self.secondaryName),
        ])
        var refreshCount = 0
        coordinator.onRefresh = { refreshCount += 1 }

        centerA.post(name: Self.primaryName, object: nil)
        centerB.post(name: Self.secondaryName, object: nil)

        XCTAssertEqual(refreshCount, 2)
    }

    func testUnsubscribedNotificationsAreIgnored() {
        let center = NotificationCenter()
        let coordinator = WakeRefreshCoordinator(subscriptions: [(center, Self.primaryName)])
        var refreshCount = 0
        coordinator.onRefresh = { refreshCount += 1 }

        center.post(name: Self.secondaryName, object: nil)

        XCTAssertEqual(refreshCount, 0)
    }

    func testRefreshIsNotCalledAfterDeinit() {
        let center = NotificationCenter()
        var refreshCount = 0
        var coordinator: WakeRefreshCoordinator? = WakeRefreshCoordinator(
            subscriptions: [(center, Self.primaryName)]
        )
        coordinator?.onRefresh = { refreshCount += 1 }

        center.post(name: Self.primaryName, object: nil)
        XCTAssertEqual(refreshCount, 1)

        coordinator = nil
        center.post(name: Self.primaryName, object: nil)

        XCTAssertEqual(refreshCount, 1, "Coordinator should remove its observer when deallocated")
    }

    func testRefreshFromBackgroundPostIsDeliveredOnMainThread() {
        let center = NotificationCenter()
        let coordinator = WakeRefreshCoordinator(subscriptions: [(center, Self.primaryName)])
        let expectation = expectation(description: "refresh fires from background post")
        var deliveredOnMainThread = false
        coordinator.onRefresh = {
            deliveredOnMainThread = Thread.isMainThread
            expectation.fulfill()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            center.post(name: Self.primaryName, object: nil)
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(
            deliveredOnMainThread,
            "WakeRefreshCoordinator must deliver onRefresh on the main thread to be safe for AppKit consumers"
        )
    }
}
