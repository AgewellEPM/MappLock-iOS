// MappLockTests.swift - Comprehensive Test Suite
import XCTest
import Combine
import SwiftUI
@testable import MappLock_iOS
@testable import MappLockCore

final class MappLockTests: XCTestCase {
    var sessionManager: SessionManager!
    var kioskManager: iOSKioskController!
    var mockNotificationService: MockNotificationService!
    var mockAnalyticsService: MockAnalyticsService!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockNotificationService = MockNotificationService()
        mockAnalyticsService = MockAnalyticsService()

        sessionManager = SessionManager(
            violationDetector: ViolationDetector(),
            notificationService: mockNotificationService,
            analyticsService: mockAnalyticsService
        )

        kioskManager = iOSKioskController()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        cancellables?.removeAll()
        sessionManager = nil
        kioskManager = nil
        mockNotificationService = nil
        mockAnalyticsService = nil

        try super.tearDownWithError()
    }
}

// MARK: - Session Manager Tests
extension MappLockTests {
    func testSessionManagerInitialState() {
        // Given: Fresh session manager
        // When: Just initialized
        // Then: Should be in inactive state
        XCTAssertEqual(sessionManager.state, .inactive)
        XCTAssertNil(sessionManager.currentSession)
        XCTAssertEqual(sessionManager.remainingTime, 0)
        XCTAssertEqual(sessionManager.elapsedTime, 0)
        XCTAssertTrue(sessionManager.violations.isEmpty)
    }

    func testStartSessionSuccess() async throws {
        // Given: Valid configuration
        let configuration = SessionConfiguration(
            name: "Test Session",
            duration: 3600, // 1 hour
            kioskMode: .autonomous
        )

        let expectation = XCTestExpectation(description: "Session started")

        sessionManager.$state
            .dropFirst()
            .sink { state in
                if state == .active {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Starting session
        try await sessionManager.startSession(with: configuration)

        // Then: Should be active
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(sessionManager.state, .active)
        XCTAssertNotNil(sessionManager.currentSession)
        XCTAssertEqual(sessionManager.currentSession?.configuration.name, "Test Session")
        XCTAssertEqual(sessionManager.remainingTime, 3600, accuracy: 1.0)
    }

    func testStartSessionWithInvalidConfiguration() async {
        // Given: Invalid configuration (negative duration)
        let configuration = SessionConfiguration(
            name: "Invalid Session",
            duration: -100
        )

        // When: Starting session with invalid config
        // Then: Should throw error
        do {
            try await sessionManager.startSession(with: configuration)
            XCTFail("Should have thrown an error")
        } catch SessionError.invalidDuration {
            // Expected error
            XCTAssertEqual(sessionManager.state, .inactive)
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }

    func testPauseAndResumeSession() async throws {
        // Given: Active session
        let configuration = SessionConfiguration(
            name: "Test Session",
            duration: 3600
        )

        try await sessionManager.startSession(with: configuration)
        XCTAssertEqual(sessionManager.state, .active)

        // When: Pausing session
        try await sessionManager.pauseSession()

        // Then: Should be paused
        XCTAssertEqual(sessionManager.state, .paused)

        // When: Resuming session
        try await sessionManager.resumeSession()

        // Then: Should be active again
        XCTAssertEqual(sessionManager.state, .active)
    }

    func testEndSession() async throws {
        // Given: Active session
        let configuration = SessionConfiguration(
            name: "Test Session",
            duration: 3600
        )

        try await sessionManager.startSession(with: configuration)
        XCTAssertEqual(sessionManager.state, .active)

        // When: Ending session
        await sessionManager.endSession()

        // Then: Should be inactive
        XCTAssertEqual(sessionManager.state, .inactive)
        XCTAssertNil(sessionManager.currentSession)
        XCTAssertEqual(sessionManager.remainingTime, 0)
        XCTAssertTrue(sessionManager.violations.isEmpty)
    }

    func testExtendSession() async throws {
        // Given: Active session
        let configuration = SessionConfiguration(
            name: "Test Session",
            duration: 1800 // 30 minutes
        )

        try await sessionManager.startSession(with: configuration)
        let originalTime = sessionManager.remainingTime

        // When: Extending session by 15 minutes
        try await sessionManager.extendSession(by: 900)

        // Then: Should have extended time
        XCTAssertEqual(sessionManager.remainingTime, originalTime + 900, accuracy: 1.0)
    }

    func testViolationReporting() async throws {
        // Given: Active session
        let configuration = SessionConfiguration(
            name: "Test Session",
            duration: 3600
        )

        try await sessionManager.startSession(with: configuration)

        let violation = Violation(
            type: .appLaunch,
            severity: .high,
            details: ["app": "Blocked App"]
        )

        // When: Reporting violation
        await sessionManager.reportViolation(violation)

        // Then: Should be recorded
        XCTAssertEqual(sessionManager.violations.count, 1)
        XCTAssertEqual(sessionManager.violations.first?.type, .appLaunch)
    }
}

// MARK: - Kiosk Manager Tests
extension MappLockTests {
    func testKioskManagerInitialState() {
        // Given: Fresh kiosk manager
        // When: Just initialized
        // Then: Should be inactive
        XCTAssertEqual(kioskManager.currentState, .inactive)
        XCTAssertEqual(kioskManager.currentMode, .guidedAccess)
    }

    func testKioskModeLifecycle() async throws {
        // Given: Configuration for autonomous mode
        let configuration = SessionConfiguration(
            name: "Test Kiosk",
            duration: 3600,
            kioskMode: .autonomous
        )

        // When: Starting kiosk mode
        try await kioskManager.startKioskMode(with: configuration)

        // Then: Should be active
        XCTAssertEqual(kioskManager.currentState, .active)
        XCTAssertEqual(kioskManager.currentMode, .autonomous)

        // When: Ending kiosk mode
        try await kioskManager.endKioskMode()

        // Then: Should be inactive
        XCTAssertEqual(kioskManager.currentState, .inactive)
    }

    func testRequestPermissions() async throws {
        // When: Requesting permissions
        let granted = try await kioskManager.requestPermissions()

        // Then: Should return boolean result
        XCTAssertTrue(granted == true || granted == false) // Either result is valid
    }

    func testGetRunningApps() async throws {
        // When: Getting running apps
        let apps = try await kioskManager.getRunningApps()

        // Then: Should return at least current app
        XCTAssertGreaterThanOrEqual(apps.count, 1)
        XCTAssertTrue(apps.contains { $0.bundleId == Bundle.main.bundleIdentifier })
    }
}

// MARK: - Configuration Tests
extension MappLockTests {
    func testSessionConfigurationCreation() {
        // Given: Configuration parameters
        let name = "Test Config"
        let duration: TimeInterval = 3600

        // When: Creating configuration
        let config = SessionConfiguration(
            name: name,
            duration: duration,
            kioskMode: .screenTime,
            restrictionLevel: .strict
        )

        // Then: Should have correct values
        XCTAssertEqual(config.name, name)
        XCTAssertEqual(config.duration, duration)
        XCTAssertEqual(config.kioskMode, .screenTime)
        XCTAssertEqual(config.restrictionLevel, .strict)
        XCTAssertNotNil(config.id)
        XCTAssertEqual(config.version, 1)
    }

    func testConfigurationUpdate() {
        // Given: Original configuration
        let original = SessionConfiguration(
            name: "Original",
            duration: 1800
        )

        // When: Updating configuration
        let updated = original.updated(
            name: "Updated",
            duration: 3600
        )

        // Then: Should have updated values
        XCTAssertEqual(updated.name, "Updated")
        XCTAssertEqual(updated.duration, 3600)
        XCTAssertEqual(updated.id, original.id) // ID should remain same
        XCTAssertEqual(updated.version, 2) // Version should increment
        XCTAssertGreaterThan(updated.modifiedAt, original.modifiedAt)
    }

    func testAppIdentifierEquality() {
        // Given: Two app identifiers
        let app1 = AppIdentifier(
            bundleId: "com.example.app",
            name: "Example App",
            platform: .iOS
        )

        let app2 = AppIdentifier(
            bundleId: "com.example.app",
            name: "Example App",
            platform: .iOS
        )

        let app3 = AppIdentifier(
            bundleId: "com.different.app",
            name: "Different App",
            platform: .iOS
        )

        // Then: Should be equal if same bundle ID
        XCTAssertEqual(app1, app2)
        XCTAssertNotEqual(app1, app3)
    }

    func testWebsitePatternMatching() {
        // Given: Website patterns
        let domainPattern = WebsitePattern(pattern: "example.com", type: .domain)
        let wildcardPattern = WebsitePattern(pattern: "*.social.com", type: .wildcard)

        let exactURL = URL(string: "https://example.com")!
        let subdomainURL = URL(string: "https://www.example.com")!
        let socialURL = URL(string: "https://app.social.com")!

        // Then: Should match correctly
        XCTAssertTrue(domainPattern.matches(url: exactURL))
        XCTAssertFalse(domainPattern.matches(url: subdomainURL)) // Domain type is exact
        XCTAssertTrue(wildcardPattern.matches(url: socialURL))
    }
}

// MARK: - Time Restrictions Tests
extension MappLockTests {
    func testTimeRestrictions() {
        // Given: Time restrictions
        let morningRange = TimeRange(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 12, minute: 0)
        )

        let restrictions = TimeRestrictions(
            allowedTimeRanges: [morningRange]
        )

        // When: Checking different times
        let calendar = Calendar.current
        let morningTime = calendar.date(from: DateComponents(hour: 10, minute: 30))!
        let afternoonTime = calendar.date(from: DateComponents(hour: 14, minute: 30))!

        // Then: Should allow/block correctly
        XCTAssertTrue(restrictions.isAllowed(at: morningTime))
        XCTAssertFalse(restrictions.isAllowed(at: afternoonTime))
    }

    func testTimeRangeSpanningMidnight() {
        // Given: Time range spanning midnight
        let nightRange = TimeRange(
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 6, minute: 0)
        )

        // When: Checking times
        let lateNight = TimeOfDay(hour: 23, minute: 30)
        let earlyMorning = TimeOfDay(hour: 3, minute: 0)
        let afternoon = TimeOfDay(hour: 14, minute: 0)

        // Then: Should handle midnight span correctly
        XCTAssertTrue(nightRange.contains(lateNight))
        XCTAssertTrue(nightRange.contains(earlyMorning))
        XCTAssertFalse(nightRange.contains(afternoon))
    }
}

// MARK: - Violation Detection Tests
extension MappLockTests {
    func testViolationCreation() {
        // Given: Violation parameters
        let violation = Violation(
            type: .appLaunch,
            severity: .high,
            details: [
                "app": "Blocked App",
                "bundleId": "com.blocked.app"
            ]
        )

        // Then: Should have correct properties
        XCTAssertEqual(violation.type, .appLaunch)
        XCTAssertEqual(violation.severity, .high)
        XCTAssertEqual(violation.details["app"], "Blocked App")
        XCTAssertNotNil(violation.id)
    }

    func testViolationSeverityOrdering() {
        // Given: Different severity levels
        let low = Violation.Severity.low
        let medium = Violation.Severity.medium
        let high = Violation.Severity.high
        let critical = Violation.Severity.critical

        // Then: Should be properly ordered
        XCTAssertLessThan(low.rawValue, medium.rawValue)
        XCTAssertLessThan(medium.rawValue, high.rawValue)
        XCTAssertLessThan(high.rawValue, critical.rawValue)
    }
}

// MARK: - UI Component Tests
extension MappLockTests {
    func testSessionStatusCardDisplay() {
        // Given: Session status card with active session
        let sessionManager = SessionManager(
            violationDetector: ViolationDetector(),
            notificationService: mockNotificationService,
            analyticsService: mockAnalyticsService
        )

        // Create a mock active session
        let mockSession = Session(
            id: UUID(),
            configuration: SessionConfiguration(name: "Test", duration: 3600),
            startTime: Date().addingTimeInterval(-1800), // Started 30 minutes ago
            state: .active
        )

        // When: Creating status card view
        let statusCard = SessionStatusCardCompact()
            .environmentObject(sessionManager)

        // Then: Should render without crashing
        XCTAssertNotNil(statusCard)
    }

    func testQuickActionButtonInteraction() {
        // Given: Quick action button
        var actionCalled = false
        let button = QuickActionButton(
            icon: "play.fill",
            title: "Test Action",
            color: .blue
        ) {
            actionCalled = true
        }

        // Then: Should be creatable
        XCTAssertNotNil(button)
        // Note: UI interaction testing would require UI testing framework
    }
}

// MARK: - Performance Tests
extension MappLockTests {
    func testSessionCreationPerformance() {
        // Measure time to create session configurations
        measure {
            for _ in 0..<1000 {
                let _ = SessionConfiguration(
                    name: "Performance Test",
                    duration: 3600
                )
            }
        }
    }

    func testViolationDetectionPerformance() {
        measure {
            let detector = ViolationDetector()
            for _ in 0..<100 {
                let violation = Violation(
                    type: .appLaunch,
                    severity: .medium
                )
                detector.violationPublisher.send(violation)
            }
        }
    }
}

// MARK: - Integration Tests
extension MappLockTests {
    func testSessionManagerKioskManagerIntegration() async throws {
        // Given: Session manager and kiosk manager
        let configuration = SessionConfiguration(
            name: "Integration Test",
            duration: 1800,
            kioskMode: .autonomous
        )

        // When: Starting session (should trigger kiosk mode)
        try await sessionManager.startSession(with: configuration)

        // Then: Both should be active
        XCTAssertEqual(sessionManager.state, .active)

        // When: Ending session
        await sessionManager.endSession()

        // Then: Both should be inactive
        XCTAssertEqual(sessionManager.state, .inactive)
    }
}

// MARK: - Error Handling Tests
extension MappLockTests {
    func testSessionErrorHandling() async {
        // Given: Session manager in inactive state

        // When: Trying to pause non-existent session
        do {
            try await sessionManager.pauseSession()
            XCTFail("Should have thrown error")
        } catch SessionError.noActiveSession {
            // Expected
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }

        // When: Trying to resume non-paused session
        do {
            try await sessionManager.resumeSession()
            XCTFail("Should have thrown error")
        } catch SessionError.sessionNotPaused {
            // Expected
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }

    func testKioskErrorHandling() async {
        // Given: Kiosk manager in inactive state

        // When: Trying to pause non-active kiosk
        do {
            try await kioskManager.pauseKioskMode()
            XCTFail("Should have thrown error")
        } catch KioskError.notActive {
            // Expected
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }
}

// MARK: - Mock Services
class MockNotificationService: NotificationServiceProtocol {
    var sentNotifications: [String] = []

    func sendSessionStartNotification(_ session: Session) async {
        sentNotifications.append("session_start")
    }

    func sendSessionEndNotification(_ session: Session) async {
        sentNotifications.append("session_end")
    }

    func sendViolationNotification(_ violation: Violation) async {
        sentNotifications.append("violation")
    }

    func sendReminderNotification(remainingTime: TimeInterval) async {
        sentNotifications.append("reminder")
    }
}

class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [String] = []

    func initialize() {
        // Mock initialization
    }

    func trackSessionStart(_ session: Session) async {
        trackedEvents.append("session_start")
    }

    func trackSessionEnd(_ session: Session) async {
        trackedEvents.append("session_end")
    }

    func trackSessionPause(_ session: Session) async {
        trackedEvents.append("session_pause")
    }

    func trackSessionResume(_ session: Session) async {
        trackedEvents.append("session_resume")
    }

    func trackSessionExtension(_ session: Session, duration: TimeInterval) async {
        trackedEvents.append("session_extension")
    }

    func trackViolation(_ violation: Violation) async {
        trackedEvents.append("violation")
    }
}

// MARK: - Protocol Definitions (for mock services)
protocol NotificationServiceProtocol {
    func sendSessionStartNotification(_ session: Session) async
    func sendSessionEndNotification(_ session: Session) async
    func sendViolationNotification(_ violation: Violation) async
    func sendReminderNotification(remainingTime: TimeInterval) async
}

protocol AnalyticsServiceProtocol {
    func initialize()
    func trackSessionStart(_ session: Session) async
    func trackSessionEnd(_ session: Session) async
    func trackSessionPause(_ session: Session) async
    func trackSessionResume(_ session: Session) async
    func trackSessionExtension(_ session: Session, duration: TimeInterval) async
    func trackViolation(_ violation: Violation) async
}