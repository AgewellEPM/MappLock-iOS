// SimpleContentView.swift - Beautiful modern interface
import SwiftUI
import OSLog

struct SimpleContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var kioskManager: iOSKioskManager
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var showingStartSession = false
    @State private var selectedDuration: TimeInterval = 1800 // 30 minutes
    @State private var selectedMode: SessionMode = .focus
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var animateGradient = false

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "SimpleContentView")

    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background gradient
                AnimatedGradientBackground()
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 40) {
                        // Modern Header with glass effect
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)

                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 10)
                            }
                            .scaleEffect(sessionManager.isSessionActive ? 1.1 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: sessionManager.isSessionActive)

                            VStack(spacing: 8) {
                                Text("MappLock")
                                    .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Focus Mode for iOS")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                        }
                        .padding(.top, 60)

                        // Modern Session Status Card
                        ModernSessionCard(
                            isActive: sessionManager.isSessionActive,
                            elapsedTime: sessionManager.elapsedTime,
                            progress: sessionProgress,
                            pauseAction: pauseSession,
                            endAction: endSession
                        )

                        // Modern Start Session Section
                        if !sessionManager.isSessionActive {
                            ModernStartSessionCard(
                                selectedDuration: $selectedDuration,
                                selectedMode: $selectedMode,
                                startAction: startSession
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }


                // Info text at bottom
                VStack {
                    Spacer()
                    Text("💡 Tip: Enable Guided Access in Settings > Accessibility for full kiosk mode")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                        .opacity(0.7)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("MappLock"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var sessionProgress: Double {
        guard sessionManager.isSessionActive else { return 0 }
        return min(1.0, sessionManager.elapsedTime / selectedDuration)
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

    private func startSession() {
        logger.info("Starting session with duration: \(selectedDuration) mode: \(selectedMode.rawValue)")

        Task {
            do {
                // Create session configuration
                let config = SessionConfiguration(
                    name: "\(selectedMode.rawValue.capitalized) Session",
                    mode: selectedMode,
                    duration: selectedDuration,
                    kioskMode: .guidedAccess,
                    restrictionLevel: .standard
                )

                // Start the session
                await sessionManager.startSession(configuration: config)

                // Try to start kiosk mode (will only work if Guided Access is enabled)
                if UIAccessibility.isGuidedAccessEnabled {
                    try await kioskManager.startKiosk(with: config)
                    alertMessage = "Session started with Guided Access protection"
                } else {
                    alertMessage = "Session started. Enable Guided Access in Settings for full protection."
                }
                showingAlert = true

            } catch {
                logger.error("Failed to start session: \(error)")
                alertMessage = "Failed to start session: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func pauseSession() {
        logger.info("Pausing session")

        Task {
            await sessionManager.pauseSession()
            try? await kioskManager.pauseKiosk()
        }
    }

    private func endSession() {
        logger.info("Ending session")

        Task {
            await sessionManager.endSession()
            try? await kioskManager.endKiosk()

            alertMessage = "Session ended successfully"
            showingAlert = true
        }
    }
}

// MARK: - Modern Components

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBlue).opacity(0.1),
                Color(.systemPurple).opacity(0.15),
                Color(.systemPink).opacity(0.1),
                Color(.systemTeal).opacity(0.12)
            ]),
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ModernSessionCard: View {
    let isActive: Bool
    let elapsedTime: TimeInterval
    let progress: Double
    let pauseAction: () -> Void
    let endAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 16, height: 16)

                    Circle()
                        .fill(isActive ? .green : .gray)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isActive)
                }

                Text(isActive ? "Session Active" : "No Active Session")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                if isActive {
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }

            if isActive {
                VStack(spacing: 16) {
                    // Modern progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(progress) * UIScreen.main.bounds.width * 0.8, height: 8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                    }

                    // Modern control buttons
                    HStack(spacing: 20) {
                        ModernButton(
                            title: "Pause",
                            icon: "pause.circle.fill",
                            color: .orange,
                            action: pauseAction
                        )

                        ModernButton(
                            title: "End Session",
                            icon: "stop.circle.fill",
                            color: .red,
                            action: endAction
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
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

struct ModernStartSessionCard: View {
    @Binding var selectedDuration: TimeInterval
    @Binding var selectedMode: SessionMode
    let startAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Start New Session")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            VStack(spacing: 20) {
                // Duration picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    ModernPicker(
                        selection: $selectedDuration,
                        options: [
                            (900, "15 min"),
                            (1800, "30 min"),
                            (3600, "1 hour"),
                            (7200, "2 hours")
                        ]
                    )
                }

                // Mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mode")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach([SessionMode.focus, .study, .work], id: \.self) { mode in
                            Button(action: { selectedMode = mode }) {
                                VStack(spacing: 8) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 20, weight: .medium))

                                    Text(mode.rawValue.capitalized)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(selectedMode == mode ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedMode == mode ?
                                    AnyView(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ) :
                                    AnyView(Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.ultraThinMaterial, lineWidth: selectedMode == mode ? 0 : 1)
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // Start button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                startAction()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20, weight: .semibold))

                    Text("Start Session")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedMode)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
}

struct ModernButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernPicker: View {
    @Binding var selection: TimeInterval
    let options: [(TimeInterval, String)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { duration, label in
                Button(action: { selection = duration }) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(selection == duration ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selection == duration ?
                            AnyView(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            ) :
                            AnyView(Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.ultraThinMaterial, lineWidth: selection == duration ? 0 : 1)
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

extension SessionMode {
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .study: return "book.fill"
        case .work: return "laptopcomputer"
        case .exam: return "pencil.and.ruler"
        case .kiosk: return "display"
        case .presentation: return "rectangle.on.rectangle"
        case .retail: return "storefront"
        case .healthcare: return "heart.fill"
        case .custom: return "gearshape.fill"
        }
    }
}

struct SimpleContentView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleContentView()
            .environmentObject(SessionManager())
            .environmentObject(iOSKioskManager())
            .environmentObject(SettingsManager())
    }
}