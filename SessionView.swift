// SessionView.swift - Main Session Control Interface
import SwiftUI


import OSLog

struct SessionView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var kioskManager: iOSKioskManager
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var showingConfiguration = false
    @State private var showingEmergencyExit = false
    @State private var selectedConfiguration: SessionConfiguration?

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "SessionView")

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Session Status Card
                        sessionStatusCard

                        // Quick Actions
                        if sessionManager.isSessionActive {
                            quickActionsCard
                        } else {
                            startSessionCard
                        }

                        // Smart Suggestions (iPhone only)
                        if UIDevice.current.userInterfaceIdiom == .phone && !sessionManager.isSessionActive {
                            smartSuggestionsCard
                        }

                        // Recent Sessions
                        recentSessionsCard

                        // Violation Log (if active)
                        if sessionManager.isSessionActive && !sessionManager.violations.isEmpty {
                            violationLogCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("MappLock")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingConfiguration = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(sessionManager.isSessionActive)
                }
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            Text("Configuration Selection")
                .font(.largeTitle)
        }
        .onChange(of: selectedConfiguration) { configuration in
            if let config = configuration {
                startSession(with: config)
                selectedConfiguration = nil
            }
        }
    }

    // MARK: - Session Status Card
    private var sessionStatusCard: some View {
        VStack(spacing: 16) {
            // Status Header
            HStack {
                statusIndicator
                Spacer()
                timeDisplay
            }

            // Progress Bar
            if sessionManager.isSessionActive {
                ProgressView(value: sessionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 3)
                    .animation(.easeInOut, value: sessionProgress)
            }

            // Active App Display
            if sessionManager.isSessionActive {
                activeAppDisplay
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)

            Text(sessionManager.sessionState.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    private var timeDisplay: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if sessionManager.isSessionActive {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatTime(sessionManager.elapsedTime))
                    .font(.title2)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundColor(.primary)
            } else {
                Text("Ready")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var activeAppDisplay: some View {
        HStack(spacing: 12) {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundColor(.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Current App")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(currentAppName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Lock Status
            Image(systemName: kioskManager.isKioskActive ? "lock.fill" : "lock.open.fill")
                .font(.title3)
                .foregroundColor(kioskManager.isKioskActive ? .red : .green)
        }
    }

    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionButton(
                    icon: sessionManager.sessionState == .active ? "pause.circle.fill" : "play.circle.fill",
                    title: sessionManager.sessionState == .active ? "Pause" : "Resume",
                    color: .orange
                ) {
                    handlePauseResumeAction()
                }

                QuickActionButton(
                    icon: "stop.circle.fill",
                    title: "End Session",
                    color: .red
                ) {
                    endSession()
                }

                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Extend Time",
                    color: .blue
                ) {
                    extendSession()
                }

                QuickActionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "Emergency Exit",
                    color: .red
                ) {
                    showingEmergencyExit = true
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Start Session Card
    private var startSessionCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Start Focus Session")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Block distractions and stay focused")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingConfiguration = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start New Session")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Smart Suggestions Card
    private var smartSuggestionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Smart Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                SuggestionRow(
                    emoji: "🎯",
                    title: "Focus Mode",
                    description: "Block social apps for 2 hours"
                ) {
                    // Implement focus mode suggestion
                }

                SuggestionRow(
                    emoji: "📚",
                    title: "Study Session",
                    description: "Education-optimized restrictions"
                ) {
                    // Implement study session suggestion
                }

                SuggestionRow(
                    emoji: "💼",
                    title: "Work Mode",
                    description: "Business-focused environment"
                ) {
                    // Implement work mode suggestion
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Recent Sessions Card
    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.semibold)

            // Placeholder for recent sessions
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus Session")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("2 hours • Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("Yesterday")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    if index < 2 {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Violation Log Card
    private var violationLogCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Activity Log")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\\(sessionManager.violations.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sessionManager.violations.prefix(5)) { violation in
                        ViolationRow(violation: violation)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Helper Properties
    private var statusIcon: String {
        switch sessionManager.sessionState {
        case .active: return "lock.fill"
        case .paused: return "pause.circle.fill"
        case .inactive: return "lock.open.fill"
        default: return "clock.fill"
        }
    }

    private var statusColor: Color {
        switch sessionManager.sessionState {
        case .active: return .green
        case .paused: return .orange
        case .inactive: return .gray
        default: return .blue
        }
    }

    private var sessionProgress: Double {
        guard let session = sessionManager.currentSession else { return 0 }
        let elapsed = Date().timeIntervalSince(session.startTime)
        return min(1.0, elapsed / 3600) // Default 1 hour
    }

    private var currentAppName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "MappLock"
    }

    // MARK: - Helper Methods
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

    private func startSession(with configuration: SessionConfiguration) {
        logger.info("Starting session with configuration: \(configuration.name)")

        Task {
            await sessionManager.startSession(configuration: configuration)
            logger.info("Session started successfully")
        }
    }

    private func handlePauseResumeAction() {
        Task {
            do {
                if sessionManager.sessionState == .active {
                    await sessionManager.pauseSession()
                } else if sessionManager.sessionState == .paused {
                    await sessionManager.resumeSession()
                }
            } catch {
                logger.error("Failed to pause/resume session: \\(error)")
            }
        }
    }

    private func endSession() {
        logger.info("Ending session")

        Task {
            await sessionManager.endSession()
        }
    }

    private func extendSession() {
        logger.info("Extending session")

        Task {
            // Extend session logic
            logger.info("Extending session by 15 minutes")
        }
    }
}

// MARK: - Supporting Views
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SuggestionRow: View {
    let emoji: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ViolationRow: View {
    let violation: Violation

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(severityColor)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(violation.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(formatViolationTime(violation.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(violation.severity.displayName)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(severityColor.opacity(0.2))
                .cornerRadius(4)
        }
    }

    private var severityColor: Color {
        switch violation.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    private func formatViolationTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews
struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
            .environmentObject(SessionManager())
            .environmentObject(iOSKioskManager())
            .environmentObject(SettingsManager())
            .previewDevice("iPhone 14 Pro")

        SessionView()
            .environmentObject(SessionManager())
            .environmentObject(iOSKioskManager())
            .environmentObject(SettingsManager())
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}