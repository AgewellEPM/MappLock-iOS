// MappLockCore.swift - Core Types and Protocols
import Foundation
import SwiftUI
import Combine

// MARK: - Core Types
public enum SessionState: String, Codable {
    case inactive = "inactive"
    case active = "active"
    case paused = "paused"
    case ending = "ending"
    case starting = "starting"

    public var isActive: Bool {
        return self == .active || self == .paused
    }

    public var displayName: String {
        switch self {
        case .inactive: return "Inactive"
        case .active: return "Active"
        case .paused: return "Paused"
        case .ending: return "Ending"
        case .starting: return "Starting"
        }
    }
}

public enum KioskState: String, Codable {
    case inactive = "inactive"
    case starting = "starting"
    case active = "active"
    case paused = "paused"
    case ending = "ending"
}

public enum KioskMode: String, Codable, CaseIterable {
    case guidedAccess = "guided_access"
    case screenTime = "screen_time"
    case autonomous = "autonomous"
    case singleApp = "single_app"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .guidedAccess: return "Guided Access"
        case .screenTime: return "Screen Time"
        case .autonomous: return "Autonomous"
        case .singleApp: return "Single App"
        case .custom: return "Custom"
        }
    }
}

public enum RestrictionLevel: String, Codable, CaseIterable {
    case none = "none"
    case minimal = "minimal"
    case basic = "basic"
    case standard = "standard"
    case strict = "strict"
    case maximum = "maximum"

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .minimal: return "Minimal"
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .strict: return "Strict"
        case .maximum: return "Maximum"
        }
    }
}

public enum SessionMode: String, Codable, CaseIterable {
    case focus = "focus"
    case study = "study"
    case work = "work"
    case exam = "exam"
    case kiosk = "kiosk"
    case presentation = "presentation"
    case retail = "retail"
    case healthcare = "healthcare"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .study: return "Study"
        case .work: return "Work"
        case .exam: return "Exam"
        case .kiosk: return "Kiosk"
        case .presentation: return "Presentation"
        case .retail: return "Retail"
        case .healthcare: return "Healthcare"
        case .custom: return "Custom"
        }
    }
}

public enum ViolationType: String, Codable {
    case appSwitch = "app_switch"
    case websiteAccess = "website_access"
    case systemGesture = "system_gesture"
    case notificationAccess = "notification_access"
    case controlCenter = "control_center"
    case hardwareButton = "hardware_button"
    case timeLimit = "time_limit"
    case networkChange = "network_change"

    public var displayName: String {
        switch self {
        case .appSwitch: return "App Switch Attempt"
        case .websiteAccess: return "Blocked Website Access"
        case .systemGesture: return "System Gesture"
        case .notificationAccess: return "Notification Access"
        case .controlCenter: return "Control Center"
        case .hardwareButton: return "Hardware Button"
        case .timeLimit: return "Time Limit Exceeded"
        case .networkChange: return "Network Change"
        }
    }
}

public enum ViolationSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Configuration Types
public struct SessionConfiguration: Codable, Equatable {
    public var name: String
    public let mode: SessionMode
    public let duration: TimeInterval
    public let kioskMode: KioskMode
    public let restrictionLevel: RestrictionLevel
    public let allowedApps: [String]
    public let blockedApps: [String]
    public let timeRestrictions: TimeRestriction?
    public let breakConfiguration: BreakConfiguration?
    public let emergencyContact: String?

    public init(
        name: String = "Focus Session",
        mode: SessionMode = .focus,
        duration: TimeInterval = 3600,
        kioskMode: KioskMode = .guidedAccess,
        restrictionLevel: RestrictionLevel = .standard,
        allowedApps: [String] = [],
        blockedApps: [String] = [],
        timeRestrictions: TimeRestriction? = nil,
        breakConfiguration: BreakConfiguration? = nil,
        emergencyContact: String? = nil
    ) {
        self.name = name
        self.mode = mode
        self.duration = duration
        self.kioskMode = kioskMode
        self.restrictionLevel = restrictionLevel
        self.allowedApps = allowedApps
        self.blockedApps = blockedApps
        self.timeRestrictions = timeRestrictions
        self.breakConfiguration = breakConfiguration
        self.emergencyContact = emergencyContact
    }
}

public struct TimeRestriction: Codable, Equatable {
    public let startTime: Date
    public let endTime: Date
    public let daysOfWeek: [Int]

    public init(startTime: Date, endTime: Date, daysOfWeek: [Int]) {
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeek = daysOfWeek
    }
}

public struct BreakConfiguration: Codable, Equatable {
    public let interval: TimeInterval
    public let duration: TimeInterval
    public let isRequired: Bool

    public init(interval: TimeInterval, duration: TimeInterval, isRequired: Bool) {
        self.interval = interval
        self.duration = duration
        self.isRequired = isRequired
    }
}

// MARK: - App and Violation Types
public struct AppIdentifier: Codable, Hashable {
    public let bundleId: String
    public let name: String

    public init(bundleId: String, name: String) {
        self.bundleId = bundleId
        self.name = name
    }
}

public struct AppInfo: Codable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let isRunning: Bool

    public init(id: String, name: String, bundleId: String, isRunning: Bool) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.isRunning = isRunning
    }
}

public struct Violation: Codable, Identifiable {
    public let id: UUID
    public let type: ViolationType
    public let timestamp: Date
    public let details: String?
    public let severity: ViolationSeverity

    public init(
        id: UUID = UUID(),
        type: ViolationType,
        timestamp: Date = Date(),
        details: String? = nil,
        severity: ViolationSeverity = .medium
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.details = details
        self.severity = severity
    }
}

public struct SessionInfo: Codable {
    public let id: String
    public let startTime: Date
    public let endTime: Date?
    public let mode: SessionMode
    public let violations: [Violation]

    public init(
        id: String,
        startTime: Date,
        endTime: Date? = nil,
        mode: SessionMode,
        violations: [Violation] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.mode = mode
        self.violations = violations
    }
}

// MARK: - Protocol Definitions
public protocol KioskControllerProtocol: ObservableObject {
    var currentState: KioskState { get }
    var isSupported: Bool { get }
    var statePublisher: AnyPublisher<KioskState, Never> { get }

    func startKioskMode(with configuration: SessionConfiguration) async throws
    func pauseKioskMode() async throws
    func resumeKioskMode() async throws
    func endKioskMode() async throws
    func blockApp(_ app: AppIdentifier) async throws
    func unblockApp(_ app: AppIdentifier) async throws
    func getRunningApps() async throws -> [AppInfo]
    func requestPermissions() async throws -> Bool
}

// MARK: - Mock Controllers for Development
public class GuidedAccessController {
    public init() {}

    public func start(configuration: SessionConfiguration) async throws {
        // Implementation would go here
    }

    public func pause() async {
        // Implementation would go here
    }

    public func resume() async throws {
        // Implementation would go here
    }

    public func end() async throws {
        // Implementation would go here
    }
}

public class ScreenTimeController {
    public init() {}

    public func start(configuration: SessionConfiguration) async throws {
        // Implementation would go here
    }

    public func pause() async {
        // Implementation would go here
    }

    public func resume() async throws {
        // Implementation would go here
    }

    public func end() async throws {
        // Implementation would go here
    }

    public func blockApp(_ app: AppIdentifier) async throws {
        // Implementation would go here
    }

    public func unblockApp(_ app: AppIdentifier) async throws {
        // Implementation would go here
    }
}

public class AutonomousController {
    public init() {}

    public func start(configuration: SessionConfiguration) async throws {
        // Implementation would go here
    }

    public func pause() async {
        // Implementation would go here
    }

    public func resume() async throws {
        // Implementation would go here
    }

    public func end() async throws {
        // Implementation would go here
    }

    public func blockApp(_ app: AppIdentifier) async throws {
        // Implementation would go here
    }

    public func unblockApp(_ app: AppIdentifier) async throws {
        // Implementation would go here
    }
}

public class ViolationMonitor {
    public let violationPublisher = PassthroughSubject<Violation, Never>()

    public init() {}

    public func start(configuration: SessionConfiguration) async throws {
        // Implementation would go here
    }

    public func pause() async {
        // Implementation would go here
    }

    public func resume() async {
        // Implementation would go here
    }

    public func stop() async {
        // Implementation would go here
    }
}

public class ProfileManager {
    public init() {}

    public func getCurrentProfile() async -> ManagementProfile? {
        return nil
    }
}

public class CertificateManager {
    public init() {}
}

public class MDMController {
    public let serverURL = URL(string: "https://mdm.mapplock.com/api/v1")!

    public init() {}
}

public struct ManagementProfile: Codable {
    public let organizationName: String
    public let profileID: String
    public let version: String

    public init(organizationName: String, profileID: String, version: String) {
        self.organizationName = organizationName
        self.profileID = profileID
        self.version = version
    }
}