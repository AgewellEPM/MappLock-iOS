import Foundation
import SwiftUI

// MARK: - App Information Model
public struct AppInfo: Identifiable, Codable {
    public let id = UUID()
    public let bundleId: String
    public let name: String
    public let displayName: String
    public let iconData: Data?
    public let isRunning: Bool
    public let version: String?

    public init(bundleId: String, name: String, displayName: String, iconData: Data? = nil, isRunning: Bool = false, version: String? = nil) {
        self.bundleId = bundleId
        self.name = name
        self.displayName = displayName
        self.iconData = iconData
        self.isRunning = isRunning
        self.version = version
    }
}

// MARK: - Session Configuration
public struct SessionConfiguration: Codable {
    public let mode: KioskMode
    public let allowedApps: Set<String>
    public let blockedApps: Set<String>
    public let timeLimit: TimeInterval?
    public let enableViolationMonitoring: Bool
    public let allowScreenshots: Bool
    public let allowNotifications: Bool
    public let allowControlCenter: Bool
    public let customMessage: String?

    public init(
        mode: KioskMode = .autonomous,
        allowedApps: Set<String> = [],
        blockedApps: Set<String> = [],
        timeLimit: TimeInterval? = nil,
        enableViolationMonitoring: Bool = true,
        allowScreenshots: Bool = false,
        allowNotifications: Bool = false,
        allowControlCenter: Bool = false,
        customMessage: String? = nil
    ) {
        self.mode = mode
        self.allowedApps = allowedApps
        self.blockedApps = blockedApps
        self.timeLimit = timeLimit
        self.enableViolationMonitoring = enableViolationMonitoring
        self.allowScreenshots = allowScreenshots
        self.allowNotifications = allowNotifications
        self.allowControlCenter = allowControlCenter
        self.customMessage = customMessage
    }
}

// MARK: - Kiosk Mode Enum
public enum KioskMode: String, CaseIterable, Codable {
    case guidedAccess = "guided_access"
    case screenTime = "screen_time"
    case autonomous = "autonomous"
    case singleApp = "single_app"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .guidedAccess:
            return "Guided Access"
        case .screenTime:
            return "Screen Time"
        case .autonomous:
            return "Autonomous"
        case .singleApp:
            return "Single App"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Violation Model
public struct Violation: Identifiable, Codable {
    public let id = UUID()
    public let type: ViolationType
    public let timestamp: Date
    public let appBundleId: String?
    public let description: String
    public let severity: ViolationSeverity

    public init(type: ViolationType, appBundleId: String? = nil, description: String, severity: ViolationSeverity = .medium) {
        self.type = type
        self.timestamp = Date()
        self.appBundleId = appBundleId
        self.description = description
        self.severity = severity
    }
}

// MARK: - Violation Type
public enum ViolationType: String, CaseIterable, Codable {
    case unauthorizedAppLaunch = "unauthorized_app_launch"
    case systemAccess = "system_access"
    case screenTimeExceeded = "screen_time_exceeded"
    case controlCenterAccess = "control_center_access"
    case screenshotAttempt = "screenshot_attempt"
    case forceQuit = "force_quit"
    case backgroundAppSwitch = "background_app_switch"

    public var displayName: String {
        switch self {
        case .unauthorizedAppLaunch:
            return "Unauthorized App Launch"
        case .systemAccess:
            return "System Access Attempt"
        case .screenTimeExceeded:
            return "Screen Time Exceeded"
        case .controlCenterAccess:
            return "Control Center Access"
        case .screenshotAttempt:
            return "Screenshot Attempt"
        case .forceQuit:
            return "Force Quit"
        case .backgroundAppSwitch:
            return "Background App Switch"
        }
    }
}

// MARK: - Violation Severity
public enum ViolationSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    public var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Kiosk Controller Protocol
public protocol KioskControllerProtocol: ObservableObject {
    var isKioskModeActive: Bool { get }
    var currentConfiguration: SessionConfiguration? { get }
    var violations: [Violation] { get }

    func startKioskMode(configuration: SessionConfiguration) async throws
    func stopKioskMode() async throws
    func getRunningApps() async throws -> [AppInfo]
    func showViolation(_ violation: Violation) async
}

// MARK: - Session Status
public enum SessionStatus: String, CaseIterable {
    case inactive = "inactive"
    case starting = "starting"
    case active = "active"
    case paused = "paused"
    case stopping = "stopping"
    case error = "error"

    public var displayName: String {
        switch self {
        case .inactive:
            return "Ready to Lock Apps"
        case .starting:
            return "Starting Session..."
        case .active:
            return "Session Active"
        case .paused:
            return "Session Paused"
        case .stopping:
            return "Stopping Session..."
        case .error:
            return "Session Error"
        }
    }

    public var color: Color {
        switch self {
        case .inactive:
            return .secondary
        case .starting:
            return .blue
        case .active:
            return .green
        case .paused:
            return .orange
        case .stopping:
            return .blue
        case .error:
            return .red
        }
    }
}