// MappLockApp.swift - Main iOS App Entry Point
import SwiftUI
import OSLog
import UserNotifications

@main
struct MappLockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var kioskManager = iOSKioskManager()

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "App")

    var body: some Scene {
        WindowGroup {
            SimpleContentView()
                .environmentObject(sessionManager)
                .environmentObject(settingsManager)
                .environmentObject(kioskManager)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppBecameActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
        }
    }

    private func setupApp() {
        logger.info("MappLock iOS app starting up")

        // Configure app appearance
        configureAppearance()

        // Setup notifications
        Task {
            await requestNotificationPermissions()
        }

        // Initialize analytics
        AnalyticsService.shared.initialize()

        logger.info("MappLock iOS app setup complete")
    }

    private func configureAppearance() {
        // Configure global app appearance
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]

        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        UITabBar.appearance().barTintColor = UIColor.systemBackground
    }

    private func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            logger.info("Notification permissions granted: \\(granted)")
        } catch {
            logger.error("Failed to request notification permissions: \\(error)")
        }
    }

    private func handleAppBecameActive() {
        logger.debug("App became active")

        // Resume any paused operations
        Task {
            await sessionManager.handleAppBecameActive()
        }
    }

    private func handleAppWillResignActive() {
        logger.debug("App will resign active")

        // Handle app going to background during session
        Task {
            await sessionManager.handleAppWillResignActive()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.mapplock.ios", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        logger.info("App delegate didFinishLaunching")

        // Configure background task handling
        configureBackgroundTasks()

        // Setup URL scheme handling
        setupURLSchemeHandling()

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        logger.info("Opening URL: \\(url.absoluteString)")

        return handleURL(url)
    }

    private func configureBackgroundTasks() {
        // Configure background tasks for session monitoring
        logger.debug("Configuring background tasks")
    }

    private func setupURLSchemeHandling() {
        // Setup mapplock:// URL scheme handling
        logger.debug("Setting up URL scheme handling")
    }

    private func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "mapplock" else {
            return false
        }

        switch url.host {
        case "start-session":
            handleStartSessionURL(url)
            return true
        case "pause-session":
            handlePauseSessionURL(url)
            return true
        case "settings":
            handleSettingsURL(url)
            return true
        default:
            logger.warning("Unknown URL host: \(url.host ?? "nil")")
            return false
        }
    }

    private func handleStartSessionURL(_ url: URL) {
        logger.info("Handling start session URL")
        NotificationCenter.default.post(name: .startSessionFromURL, object: url)
    }

    private func handlePauseSessionURL(_ url: URL) {
        logger.info("Handling pause session URL")
        NotificationCenter.default.post(name: .pauseSessionFromURL, object: url)
    }

    private func handleSettingsURL(_ url: URL) {
        logger.info("Handling settings URL")
        NotificationCenter.default.post(name: .openSettingsFromURL, object: url)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startSessionFromURL = Notification.Name("startSessionFromURL")
    static let pauseSessionFromURL = Notification.Name("pauseSessionFromURL")
    static let openSettingsFromURL = Notification.Name("openSettingsFromURL")
}