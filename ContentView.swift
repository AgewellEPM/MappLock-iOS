// ContentView.swift - Main iOS Interface
import SwiftUI
import OSLog

struct ContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var kioskManager: iOSKioskManager

    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @State private var showingEmergencyExit = false

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "ContentView")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Interface
                mainInterface(geometry: geometry)

                // Emergency Exit Overlay
                if showingEmergencyExit {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingEmergencyExit = false
                        }
                        .zIndex(100)
                }

                // Kiosk Mode Overlay
                if kioskManager.isKioskActive {
                    Color.clear
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(50)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showingEmergencyExit)
        .onAppear {
            checkFirstLaunch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .startSessionFromURL)) { _ in
            handleStartSessionURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pauseSessionFromURL)) { _ in
            handlePauseSessionURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsFromURL)) { _ in
            handleSettingsURL()
        }
        // Emergency exit gesture - 5 finger tap
        .gesture(
            TapGesture()
                .onEnded { _ in
                    if kioskManager.isKioskActive {
                        showEmergencyExit()
                    }
                }
        )
    }

    @ViewBuilder
    private func mainInterface(geometry: GeometryProxy) -> some View {
        if geometry.size.width > geometry.size.height && UIDevice.current.userInterfaceIdiom == .pad {
            // iPad Landscape Layout
            iPadLandscapeLayout()
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad Portrait Layout
            iPadPortraitLayout()
        } else {
            // iPhone Layout
            iPhoneLayout()
        }
    }

    // MARK: - iPad Layouts
    @ViewBuilder
    private func iPadLandscapeLayout() -> some View {
        HStack(spacing: 0) {
            // Sidebar
            NavigationSidebar(selectedTab: $selectedTab)
                .frame(width: 320)
                .background(Color(UIColor.secondarySystemBackground))

            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    SessionView()
                case 1:
                    Text("Configuration")
                        .font(.largeTitle)
                case 2:
                    Text("Analytics")
                        .font(.largeTitle)
                case 3:
                    Text("Settings")
                        .font(.largeTitle)
                default:
                    SessionView()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }

    @ViewBuilder
    private func iPadPortraitLayout() -> some View {
        NavigationView {
            // Sidebar for iPad portrait
            NavigationSidebar(selectedTab: $selectedTab)
                .navigationBarHidden(true)
                .frame(minWidth: 320)

            // Detail view
            Group {
                switch selectedTab {
                case 0:
                    SessionView()
                case 1:
                    Text("Configuration")
                        .font(.largeTitle)
                case 2:
                    Text("Analytics")
                        .font(.largeTitle)
                case 3:
                    Text("Settings")
                        .font(.largeTitle)
                default:
                    SessionView()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }

    // MARK: - iPhone Layout
    @ViewBuilder
    private func iPhoneLayout() -> some View {
        TabView(selection: $selectedTab) {
            SessionView()
                .tabItem {
                    Image(systemName: "lock.circle.fill")
                    Text("Session")
                }
                .tag(0)

            Text("Configuration")
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Setup")
                }
                .tag(1)

            Text("Analytics")
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(2)

            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }

    // MARK: - Helper Methods
    private func checkFirstLaunch() {
        // Check first launch logic here
        logger.info("Checking first launch")
    }

    private func handleStartSessionURL() {
        logger.info("Handling start session from URL")
        selectedTab = 0
    }

    private func handlePauseSessionURL() {
        logger.info("Handling pause session from URL")
        Task {
            await sessionManager.pauseSession()
        }
    }

    private func handleSettingsURL() {
        logger.info("Handling settings from URL")
        selectedTab = 3
    }

    private func showEmergencyExit() {
        logger.info("Emergency exit requested")
        showingEmergencyExit = true
    }
}

// MARK: - Navigation Sidebar (iPad)
struct NavigationSidebar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)

                    Text("MappLock")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding()

                // Session Status
                if sessionManager.isSessionActive {
                    SessionStatusCardCompact()
                        .padding(.horizontal)
                }
            }
            .background(Color(UIColor.tertiarySystemBackground))

            // Navigation Items
            ScrollView {
                LazyVStack(spacing: 8) {
                    SidebarItem(
                        icon: "lock.circle.fill",
                        title: "Session Control",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }

                    SidebarItem(
                        icon: "slider.horizontal.3",
                        title: "Configuration",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }

                    SidebarItem(
                        icon: "chart.bar.fill",
                        title: "Analytics",
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }

                    SidebarItem(
                        icon: "gearshape.fill",
                        title: "Settings",
                        isSelected: selectedTab == 3
                    ) {
                        selectedTab = 3
                    }
                }
                .padding()
            }

            Spacer()
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Session Status Card Compact
struct SessionStatusCardCompact: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(sessionManager.sessionState == .active ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(sessionManager.sessionState.displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text(formatTime(sessionManager.elapsedTime))
                    .font(.caption)
                    .monospacedDigit()
            }

            if sessionManager.sessionState == .active {
                ProgressView(value: sessionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var sessionProgress: Double {
        guard let session = sessionManager.currentSession else { return 0 }
        let elapsed = Date().timeIntervalSince(session.startTime)
        return min(1.0, elapsed / 3600) // Default 1 hour duration
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SessionManager())
            .environmentObject(SettingsManager())
            .environmentObject(iOSKioskManager())
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")

        ContentView()
            .environmentObject(SessionManager())
            .environmentObject(SettingsManager())
            .environmentObject(iOSKioskManager())
            .previewDevice("iPhone 14 Pro")
    }
}