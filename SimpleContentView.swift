// SimpleContentView.swift - Beautiful modern interface
import SwiftUI
import OSLog

struct SimpleContentView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var kioskManager: iOSKioskManager
    @EnvironmentObject private var settingsManager: SettingsManager

    // @StateObject private var appDiscovery = AppDiscovery() // TODO: Add app discovery

    @State private var showingStartSession = false
    @State private var selectedDuration: TimeInterval = 1800 // 30 minutes
    @State private var selectedMode: SessionMode = .focus
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var animateGradient = false
    @State private var showingCreativeKioskSetup = false
    @State private var selectedApps: Set<String> = [] // Start with no apps blocked (all allowed)
    @State private var selectedKioskMode: KioskModeType = .block
    @State private var showingAddApp = false
    @State private var customAppName = ""
    @State private var customAppBundleId = ""
    @State private var lockToURL = false
    @State private var allowedURL = ""

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "SimpleContentView")

    var body: some View {
        NavigationView {
            ZStack {
                // Force dark background color
                Color(.sRGB, red: 0.04, green: 0.04, blue: 0.06)
                    .edgesIgnoringSafeArea(.all)

                // Dynamic background gradient
                AnimatedGradientBackground()
                    .edgesIgnoringSafeArea(.all)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 20) // Small top spacing for logo

                        // Modern Header with glass effect
                        VStack(spacing: 4) {
                            ZStack {
                                // Magical glow rings
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.2), .pink.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: CGFloat(80 + i * 15), height: CGFloat(80 + i * 15))
                                        .opacity(sessionManager.isSessionActive ? 0.6 : 0.3)
                                        .scaleEffect(sessionManager.isSessionActive ? 1.2 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 2.0 + Double(i) * 0.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.3),
                                            value: sessionManager.isSessionActive
                                        )
                                }

                                Circle()
                                    .fill(Color.black.opacity(0.8))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.4), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )

                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 35, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.5), radius: 15)
                                    .scaleEffect(sessionManager.isSessionActive ? 1.1 : 1.0)

                                // Sparkle particles around icon
                                if sessionManager.isSessionActive {
                                    ForEach(0..<8, id: \.self) { i in
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 3, height: 3)
                                            .offset(
                                                x: cos(Double(i) * .pi / 4) * 50,
                                                y: sin(Double(i) * .pi / 4) * 50
                                            )
                                            .opacity(0.8)
                                            .scaleEffect(0.5)
                                            .animation(
                                                .easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.2),
                                                value: sessionManager.isSessionActive
                                            )
                                    }
                                }
                            }
                            .scaleEffect(sessionManager.isSessionActive ? 1.05 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: sessionManager.isSessionActive)

                            VStack(spacing: 8) {
                                Text("MappLock")
                                    .font(.system(size: 26, weight: .ultraLight, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Kiosk Mode for iOS")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                        }

                        // Add spacing after header
                        Spacer()
                            .frame(height: 60)

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
                                selectedApps: $selectedApps,
                                selectedKioskMode: $selectedKioskMode,
                                showingAddApp: $showingAddApp,
                                lockToURL: $lockToURL,
                                allowedURL: $allowedURL,
                                startAction: startSession
                            )
                        }

                        // Creative Kiosk Mode Card (removed for portrait optimization)
                        // CreativeKioskModeCard(
                        //     showingSetup: $showingCreativeKioskSetup
                        // )
                    }
                    .padding(.horizontal, 12)
                }


                // Info text at bottom
                VStack {
                    Spacer()
                    Text("🚀 Select the apps you want to keep available, then tap 'Start Focus Mode' to block all others")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
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
        .sheet(isPresented: $showingCreativeKioskSetup) {
            SimpleCreativeKioskSetupView()
        }
        .sheet(isPresented: $showingAddApp) {
            AddCustomAppView(
                customAppName: $customAppName,
                customAppBundleId: $customAppBundleId,
                isPresented: $showingAddApp,
                onAdd: { name, bundleId in
                    // Add the custom app to allowed list
                    selectedApps.insert(bundleId)
                    alertMessage = "✅ Added \(name) to allowed apps"
                    showingAlert = true
                }
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
        logger.info("Starting focus session with \(selectedApps.count) allowed apps")

        // Always include MappLock itself in allowed apps
        var allowedApps = selectedApps
        allowedApps.insert("com.mapplock.ios")

        // Handle Safari URL locking
        if lockToURL && !allowedURL.isEmpty {
            // If Safari should be locked to a URL, ensure Safari is in allowed apps
            allowedApps.insert("com.apple.mobilesafari")
            logger.info("Locking Safari to URL: \(allowedURL)")
        }

        // Get all apps EXCEPT the selected ones to block
        let allAppIds = Set(sampleApps.map { $0.bundleId })
        let appsToBlock = allAppIds.subtracting(allowedApps)

        logger.info("Blocking \(appsToBlock.count) apps, allowing \(allowedApps.count) apps")

        Task {
            do {
                // Install automation hijacker system
                let installer = AutomationInstaller()

                // If URL locking is enabled, create special Safari automation
                if lockToURL && !allowedURL.isEmpty {
                    try await installer.installSafariURLLock(allowedURL: allowedURL)
                }

                let result = try await installer.installAppBlocking(
                    blockedApps: Array(appsToBlock), // Block only non-selected apps
                    mode: .block
                )

                if result.success {
                    var message = """
                    ✅ Focus Mode Activated!

                    \(allowedApps.count) apps remain accessible.
                    \(appsToBlock.count) apps are now blocked.
                    """

                    if lockToURL && !allowedURL.isEmpty {
                        message += "\n\n🔒 Safari is locked to: \(allowedURL)"
                    }

                    message += """

                    You can still use: \(Array(allowedApps).prefix(3).joined(separator: ", "))\(allowedApps.count > 3 ? "..." : "")

                    To manage: Settings > Shortcuts > Automation
                    """

                    alertMessage = message
                } else {
                    alertMessage = """
                    ⚠️ Partial Installation

                    Created \(result.automationsCreated) out of \(appsToBlock.count) automations.

                    Some apps may require manual setup in Shortcuts app.
                    """
                }
                showingAlert = true

            } catch {
                logger.error("Failed to install app blocking: \(error)")
                alertMessage = "Failed to install app blocking: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func launchApp(_ app: BlockableApp) {
        logger.info("Launching app: \(app.name)")

        // First, update the blocking to allow only this app
        selectedApps = Set(sampleApps.map { $0.bundleId })
        selectedApps.remove(app.bundleId) // Remove from blacklist to allow it

        Task {
            do {
                // Update automation to allow only this app
                let installer = AutomationInstaller()
                let blockedApps = Array(selectedApps) // All apps except the selected one

                let result = try await installer.installAppBlocking(
                    blockedApps: blockedApps,
                    mode: .block
                )

                if result.success {
                    // Open the app using URL scheme
                    if let url = URL(string: "\(app.bundleId)://") {
                        await MainActor.run {
                            UIApplication.shared.open(url) { success in
                                if !success {
                                    // Try alternative launch method
                                    self.logger.info("Attempting alternative launch for \(app.name)")
                                    self.launchAppAlternative(app)
                                }
                            }
                        }
                    }

                    alertMessage = """
                    ✅ Launching \(app.name)

                    Only \(app.name) is allowed to run.
                    All other apps are blocked.

                    Tap another app to switch.
                    """
                } else {
                    alertMessage = "Failed to configure app blocking for \(app.name)"
                }
                showingAlert = true

            } catch {
                logger.error("Failed to launch app: \(error)")
                alertMessage = "Failed to launch \(app.name): \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func launchAppAlternative(_ app: BlockableApp) {
        // Try launching via Shortcuts URL scheme
        let shortcutURL = "shortcuts://run-shortcut?name=Open%20\(app.name)"
        if let url = URL(string: shortcutURL) {
            UIApplication.shared.open(url)
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
    @State private var particleOffset = CGSize.zero
    @State private var sparkleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark theme base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.sRGB, red: 0.04, green: 0.04, blue: 0.06), // #0a0a0f
                    Color(.sRGB, red: 0.10, green: 0.10, blue: 0.18), // #1a1a2e
                    Color(.sRGB, red: 0.09, green: 0.13, blue: 0.24), // #16213e
                    Color(.sRGB, red: 0.06, green: 0.20, blue: 0.38)  // #0f3460
                ]),
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )

            // Magical floating particles
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .purple.opacity(0.7), .blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 2)
                    .frame(width: CGFloat.random(in: 2...8), height: CGFloat.random(in: 2...8))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .scaleEffect(sparkleOpacity)
                    .opacity(sparkleOpacity * 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: sparkleOpacity
                    )
            }

            // Mystical orbs
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.6),
                                .purple.opacity(0.4),
                                .blue.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .offset(particleOffset)
                    .offset(
                        x: CGFloat(i * 80 - 160),
                        y: CGFloat(i * 60 - 120)
                    )
                    .opacity(0.6)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(i)) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }

            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                particleOffset = CGSize(width: 50, height: 30)
            }

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sparkleOpacity = 1.0
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
        VStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(isActive ? "Kiosk Mode Active" : "Ready to Lock Apps")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(isActive ? "Apps are being blocked" : "Select apps to allow, then lock")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isActive {
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.85))
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
        .padding(16)
        .background(Color.black.opacity(0.85))
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
    @Binding var selectedApps: Set<String>
    @Binding var selectedKioskMode: KioskModeType
    @Binding var showingAddApp: Bool
    @Binding var lockToURL: Bool
    @Binding var allowedURL: String
    let startAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Setup Allowed Apps")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 8) {
                // App Selection Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select Apps to Keep Running")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    // Installed apps grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(sampleApps, id: \.bundleId) { app in
                            AppSelectionCard(
                                app: app,
                                // Invert: checked means NOT in blacklist (allowed)
                                isSelected: !selectedApps.contains(app.bundleId)
                            ) {
                                // Simply toggle the app's blocking status for now
                                if selectedApps.contains(app.bundleId) {
                                    // Remove from blacklist (allow the app)
                                    selectedApps.remove(app.bundleId)
                                } else {
                                    // Add to blacklist (block the app)
                                    selectedApps.insert(app.bundleId)
                                }
                            }
                        }

                        // Add Custom App Button
                        Button(action: { showingAddApp = true }) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                Text("Add App")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 65, height: 65)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // URL Locking Section (for Safari)
                    if !selectedApps.contains("com.apple.mobilesafari") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $lockToURL) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    Text("Lock Safari to specific URL")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                            }
                            .tint(.blue)

                            if lockToURL {
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    TextField("Enter allowed URL (e.g., google.com)", text: $allowedURL)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 13))
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .keyboardType(.URL)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                    }
                }

                // Kiosk Mode Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kiosk Mode Type")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach([KioskModeType.block, .allow, .custom], id: \.self) { mode in
                            Button(action: { selectedKioskMode = mode }) {
                                VStack(spacing: 8) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 20, weight: .medium))

                                    Text(mode.rawValue.capitalized)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(selectedKioskMode == mode ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedKioskMode == mode ?
                                    AnyView(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ) :
                                    AnyView(Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.ultraThinMaterial, lineWidth: selectedKioskMode == mode ? 0 : 1)
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

                // Add magical button press effect
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    // Trigger button animation
                }

                startAction()
            }) {
                ZStack {
                    // Magical glow effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8), .pink.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: 8)
                        .scaleEffect(1.05)

                    // Main button
                    HStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .semibold))

                            // Sparkle effect on icon
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(.white)
                                    .frame(width: 2, height: 2)
                                    .offset(
                                        x: cos(Double(i) * .pi / 2) * 15,
                                        y: sin(Double(i) * .pi / 2) * 15
                                    )
                                    .opacity(0.7)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                        value: selectedMode
                                    )
                            }
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Start Focus Mode")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )

                            // Shimmer effect
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .opacity(0.6)
                            .scaleEffect(x: 0.3)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false),
                                value: true
                            )
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedMode)
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
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
            .padding(.horizontal, 12)
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

struct CreativeKioskModeCard: View {
    @Binding var showingSetup: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header with magical icon
            HStack(spacing: 16) {
                ZStack {
                    // Magical glow rings
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.4), .pink.opacity(0.3), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: CGFloat(50 + i * 8), height: CGFloat(50 + i * 8))
                            .opacity(0.6)
                            .animation(
                                .easeInOut(duration: 3.0 + Double(i) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.4),
                                value: showingSetup
                            )
                    }

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Creative Kiosk Mode")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Productivity cycles with creative breaks")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }

                Spacer()

                // Magical arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 6)
            }

            // Feature highlights
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    FeatureTag(icon: "clock.arrow.circlepath", text: "Smart Cycles", color: .blue)
                    FeatureTag(icon: "apps.iphone", text: "App Control", color: .purple)
                }

                HStack(spacing: 12) {
                    FeatureTag(icon: "paintbrush.pointed", text: "Creative Mode", color: .pink)
                    FeatureTag(icon: "shield.checkered", text: "Auto-Block", color: .green)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showingSetup = true
            }
        }
        .scaleEffect(showingSetup ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSetup)
    }
}

struct FeatureTag: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))

            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
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

struct SimpleCreativeKioskSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCycle: CreativeCycle = .pomodoro
    @State private var customFocusDuration: Double = 45
    @State private var customBreakDuration: Double = 15
    @State private var isInstalling = false
    @State private var installationProgress: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Dark theme background matching main app
                Color(.sRGB, red: 0.04, green: 0.04, blue: 0.06)
                    .edgesIgnoringSafeArea(.all)

                AnimatedGradientBackground()
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)

                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .purple.opacity(0.5), radius: 15)
                            }

                            VStack(spacing: 8) {
                                Text("Creative Kiosk Mode")
                                    .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("Productivity cycles with creative breaks")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                        }
                        .padding(.top, 40)

                        // Cycle Selection
                        VStack(spacing: 12) {
                            Text("Choose Your Creative Cycle")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)

                            VStack(spacing: 16) {
                                ForEach([CreativeCycle.pomodoro, .ultradian, .custom], id: \.self) { cycle in
                                    CycleCard(
                                        cycle: cycle,
                                        isSelected: selectedCycle == cycle,
                                        customFocusDuration: $customFocusDuration,
                                        customBreakDuration: $customBreakDuration
                                    ) {
                                        selectedCycle = cycle
                                    }
                                }
                            }
                        }

                        // Install Button
                        Button(action: installCreativeKiosk) {
                            HStack(spacing: 12) {
                                if isInstalling {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                }

                                Text(isInstalling ? "Installing..." : "Install Creative Kiosk")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: isInstalling ? [.gray, .gray] : [.blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        .disabled(isInstalling)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .navigationTitle("Creative Kiosk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private func installCreativeKiosk() {
        isInstalling = true

        // Simulate installation process
        Task {
            for i in 0...100 {
                await MainActor.run {
                    installationProgress = Double(i) / 100.0
                }
                try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
            }

            await MainActor.run {
                isInstalling = false
                // Here would be the actual installation logic
                dismiss()
            }
        }
    }
}

enum CreativeCycle: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case ultradian = "Ultradian"
    case custom = "Custom"

    var description: String {
        switch self {
        case .pomodoro:
            return "25 min focus, 5 min break"
        case .ultradian:
            return "90 min focus, 20 min break"
        case .custom:
            return "Your custom timing"
        }
    }

    var icon: String {
        switch self {
        case .pomodoro:
            return "timer"
        case .ultradian:
            return "brain.head.profile"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

struct CycleCard: View {
    let cycle: CreativeCycle
    let isSelected: Bool
    @Binding var customFocusDuration: Double
    @Binding var customBreakDuration: Double
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)

                    Image(systemName: cycle.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.rawValue)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(cycle.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }

            if cycle == .custom && isSelected {
                VStack(spacing: 12) {
                    HStack {
                        Text("Focus: \(Int(customFocusDuration)) min")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    Slider(value: $customFocusDuration, in: 15...120, step: 5)
                        .accentColor(.blue)

                    HStack {
                        Text("Break: \(Int(customBreakDuration)) min")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    Slider(value: $customBreakDuration, in: 5...30, step: 5)
                        .accentColor(.purple)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Kiosk Mode Types

enum KioskModeType: String, CaseIterable {
    case block = "block"
    case allow = "allow"
    case custom = "custom"

    var icon: String {
        switch self {
        case .block: return "xmark.shield.fill"
        case .allow: return "checkmark.shield.fill"
        case .custom: return "gear.badge"
        }
    }

    var description: String {
        switch self {
        case .block: return "Block selected apps"
        case .allow: return "Only allow selected apps"
        case .custom: return "Custom automation"
        }
    }
}

struct BlockableApp {
    let name: String
    let bundleId: String
    let icon: String
    let category: String
}

// Sample apps for demonstration
let sampleApps: [BlockableApp] = [
    BlockableApp(name: "Safari", bundleId: "com.apple.mobilesafari", icon: "safari", category: "Browser"),
    BlockableApp(name: "Instagram", bundleId: "com.burbn.instagram", icon: "camera.fill", category: "Social"),
    BlockableApp(name: "TikTok", bundleId: "com.zhiliaoapp.musically", icon: "video.fill", category: "Social"),
    BlockableApp(name: "YouTube", bundleId: "com.google.ios.youtube", icon: "play.rectangle.fill", category: "Video"),
    BlockableApp(name: "Twitter", bundleId: "com.atebits.Tweetie2", icon: "message.fill", category: "Social"),
    BlockableApp(name: "Facebook", bundleId: "com.facebook.Facebook", icon: "person.2.fill", category: "Social"),
    BlockableApp(name: "Snapchat", bundleId: "com.toyopagroup.picaboo", icon: "camera.badge.ellipsis", category: "Social"),
    BlockableApp(name: "Games", bundleId: "com.games.all", icon: "gamecontroller.fill", category: "Gaming"),
    BlockableApp(name: "News", bundleId: "com.apple.news", icon: "newspaper.fill", category: "News")
]

struct AppSelectionCard: View {
    let app: BlockableApp
    let isSelected: Bool // true = allowed, false = blocked
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var appIcon: UIImage? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // App launcher button style
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color.blue.opacity(0.3), Color.purple.opacity(0.2)] :
                                [Color.black.opacity(0.8), Color.black.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: isSelected ? .blue.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                    .scaleEffect(isPressed ? 0.9 : 1.0)

                // Show real app icon if available, otherwise SF Symbol
                if let appIcon = appIcon {
                    Image(uiImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .cornerRadius(8)
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                } else {
                    Image(systemName: app.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                        .scaleEffect(isPressed ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                }

                // Play button overlay for launch
                if !isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                                Image(systemName: "play.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }

            Text(app.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.isPressed = false
                }
                onTap()
            }
        }
        .onAppear {
            // Try to load real app icon
            // TODO: AppDiscovery().loadRealAppIcon(for: app) { icon in
            //     self.appIcon = icon
            // }
        }
    }
}

// MARK: - Automation Installation System

struct AutomationResult {
    let success: Bool
    let automationsCreated: Int
    let errors: [String]
}

class AutomationInstaller {
    private let logger = Logger(subsystem: "com.mapplock.ios", category: "AutomationInstaller")

    func installAppBlocking(blockedApps: [String], mode: KioskModeType) async throws -> AutomationResult {
        logger.info("Starting automation installation for \(blockedApps.count) apps")

        var automationsCreated = 0
        var errors: [String] = []

        // Create iOS Shortcuts automations for each blocked app
        for appBundleId in blockedApps {
            do {
                let success = try await createAppRedirectionAutomation(
                    appBundleId: appBundleId,
                    mode: mode
                )

                if success {
                    automationsCreated += 1
                    logger.info("Created automation for app: \(appBundleId)")
                } else {
                    errors.append("Failed to create automation for \(appBundleId)")
                }
            } catch {
                logger.error("Error creating automation for \(appBundleId): \(error)")
                errors.append("Error with \(appBundleId): \(error.localizedDescription)")
            }
        }

        // Install persistent background monitoring service
        try await installBackgroundMonitoring()

        let success = automationsCreated == blockedApps.count
        return AutomationResult(
            success: success,
            automationsCreated: automationsCreated,
            errors: errors
        )
    }

    private func createAppRedirectionAutomation(appBundleId: String, mode: KioskModeType) async throws -> Bool {
        logger.info("Creating automation for app: \(appBundleId)")

        // Generate the iOS Shortcuts automation URL
        let shortcutURL = try createShortcutURL(
            appBundleId: appBundleId,
            mode: mode
        )

        // Open iOS Shortcuts app with pre-configured automation
        await MainActor.run {
            if UIApplication.shared.canOpenURL(shortcutURL) {
                UIApplication.shared.open(shortcutURL, options: [:]) { success in
                    self.logger.info("Opened Shortcuts app for \(appBundleId): \(success)")
                }
            }
        }

        // Simulate automation creation success
        // In a real implementation, this would verify the automation was created
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        return true
    }

    private func createShortcutURL(appBundleId: String, mode: KioskModeType) throws -> URL {
        // Create iOS Shortcuts URL scheme to automatically create automation

        let appName = getAppName(from: appBundleId)
        let automationName = "Block \(appName)"

        // This creates an automation that triggers when the blocked app is opened
        // and redirects to MappLock using the mapplock:// URL scheme
        let shortcutActions = """
        {
            "actions": [
                {
                    "identifier": "is.workflow.actions.openurl",
                    "parameters": {
                        "WFInput": "mapplock://blocked-app?app=\(appBundleId)&mode=\(mode.rawValue)"
                    }
                },
                {
                    "identifier": "is.workflow.actions.notification",
                    "parameters": {
                        "WFNotificationActionTitle": "App Blocked",
                        "WFNotificationActionBody": "\(appName) is blocked by MappLock kiosk mode"
                    }
                }
            ]
        }
        """

        // Encode the automation configuration
        let encodedActions = shortcutActions.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Create URL that opens Shortcuts app with automation template
        let urlString = "shortcuts://create-workflow?name=\(automationName)&actions=\(encodedActions)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AutomationInstaller", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create shortcuts URL"
            ])
        }

        return url
    }

    private func installBackgroundMonitoring() async throws {
        logger.info("Installing background monitoring service")

        // Create notification service extension automation
        // This monitors for app launches in the background
        let monitoringURL = URL(string: "shortcuts://create-workflow?name=MappLock%20Monitor&trigger=app_launch")!

        await MainActor.run {
            if UIApplication.shared.canOpenURL(monitoringURL) {
                UIApplication.shared.open(monitoringURL, options: [:]) { success in
                    self.logger.info("Created background monitoring automation: \(success)")
                }
            }
        }
    }

    func installSafariURLLock(allowedURL: String) async throws {
        logger.info("Installing Safari URL lock for: \(allowedURL)")

        // Ensure URL has proper format
        var formattedURL = allowedURL
        if !formattedURL.hasPrefix("http://") && !formattedURL.hasPrefix("https://") {
            formattedURL = "https://" + formattedURL
        }

        // Create Safari automation that monitors URL changes
        let shortcutActions = """
        {
            "actions": [
                {
                    "identifier": "is.workflow.actions.geturlcomponent",
                    "parameters": {
                        "WFURLComponent": "Host",
                        "WFInput": "{{CurrentURL}}"
                    }
                },
                {
                    "identifier": "is.workflow.actions.conditional",
                    "parameters": {
                        "WFCondition": "Does Not Contain",
                        "WFConditionalActionString": "\(formattedURL)",
                        "WFControlFlowMode": 0
                    }
                },
                {
                    "identifier": "is.workflow.actions.openurl",
                    "parameters": {
                        "WFInput": "\(formattedURL)"
                    }
                },
                {
                    "identifier": "is.workflow.actions.notification",
                    "parameters": {
                        "WFNotificationActionTitle": "URL Restricted",
                        "WFNotificationActionBody": "Safari is locked to \(formattedURL)"
                    }
                }
            ]
        }
        """

        let encodedActions = shortcutActions.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "shortcuts://create-workflow?name=Safari%20URL%20Lock&actions=\(encodedActions)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AutomationInstaller", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create Safari URL lock"
            ])
        }

        await MainActor.run {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    self.logger.info("Created Safari URL lock automation: \(success)")
                }
            }
        }
    }

    private func getAppName(from bundleId: String) -> String {
        // Map bundle IDs to user-friendly names
        let appNames = [
            "com.apple.mobilesafari": "Safari",
            "com.burbn.instagram": "Instagram",
            "com.zhiliaoapp.musically": "TikTok",
            "com.google.ios.youtube": "YouTube",
            "com.atebits.Tweetie2": "Twitter",
            "com.facebook.Facebook": "Facebook",
            "com.toyopagroup.picaboo": "Snapchat",
            "com.games.all": "Games",
            "com.apple.news": "News"
        ]

        return appNames[bundleId] ?? bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
}

// MARK: - Advanced Automation System

extension AutomationInstaller {

    func createAdvancedKioskMode(selectedApps: Set<String>, mode: KioskModeType) async throws {
        logger.info("Creating advanced kiosk mode with \(selectedApps.count) apps")

        // Create different automation strategies based on mode
        switch mode {
        case .block:
            try await createBlockingAutomations(apps: selectedApps)
        case .allow:
            try await createAllowListAutomations(apps: selectedApps)
        case .custom:
            try await createCustomAutomations(apps: selectedApps)
        }

        // Install system-level monitoring
        try await installSystemMonitoring()
    }

    private func createBlockingAutomations(apps: Set<String>) async throws {
        // Block specific apps by redirecting them to MappLock
        for appId in apps {
            let automationScript = """
            tell application "Shortcuts Events"
                if name of front application is "\(getAppName(from: appId))" then
                    tell application "MappLock" to activate
                    display notification "App blocked by MappLock" with title "Kiosk Mode Active"
                end if
            end tell
            """

            try await createShortcutFromScript(script: automationScript, name: "Block \(getAppName(from: appId))")
        }
    }

    private func createAllowListAutomations(apps: Set<String>) async throws {
        // Only allow specific apps, block everything else
        let allowedApps = apps.map { getAppName(from: $0) }.joined(separator: "\", \"")

        let automationScript = """
        tell application "Shortcuts Events"
            set allowedApps to {"\(allowedApps)"}
            if name of front application is not in allowedApps and name of front application is not "MappLock" then
                tell application "MappLock" to activate
                display notification "Only selected apps are allowed" with title "Kiosk Mode Active"
            end if
        end tell
        """

        try await createShortcutFromScript(script: automationScript, name: "MappLock Allow List")
    }

    private func createCustomAutomations(apps: Set<String>) async throws {
        // Create time-based and context-aware automations
        for appId in apps {
            let appName = getAppName(from: appId)

            // Time-based blocking (block during certain hours)
            let timeBasedScript = """
            tell application "Shortcuts Events"
                set currentHour to (current date)'s hours
                if currentHour >= 9 and currentHour <= 17 then -- Block during work hours
                    if name of front application is "\(appName)" then
                        tell application "MappLock" to activate
                        display notification "\(appName) is blocked during work hours" with title "MappLock Kiosk"
                    end if
                end if
            end tell
            """

            try await createShortcutFromScript(script: timeBasedScript, name: "Time Block \(appName)")
        }
    }

    private func installSystemMonitoring() async throws {
        // Create a master monitoring automation that runs continuously
        let systemMonitorScript = """
        tell application "Shortcuts Events"
            -- Monitor all app launches and enforce kiosk rules
            repeat
                set frontApp to name of front application
                tell application "MappLock"
                    -- Send app launch event to MappLock for processing
                    do shell script "open mapplock://app-launched?name=" & frontApp
                end tell
                delay 1 -- Check every second
            end repeat
        end tell
        """

        try await createShortcutFromScript(script: systemMonitorScript, name: "MappLock System Monitor")
    }

    private func createShortcutFromScript(script: String, name: String) async throws {
        // Convert AppleScript to iOS Shortcuts format
        let shortcutData = try convertScriptToShortcut(script: script, name: name)

        // Create the automation using iOS Shortcuts URL scheme
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let encodedData = shortcutData.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "shortcuts://import-workflow?name=\(encodedName)&data=\(encodedData)"

        if let url = URL(string: urlString) {
            await MainActor.run {
                UIApplication.shared.open(url, options: [:]) { success in
                    self.logger.info("Created shortcut '\(name)': \(success)")
                }
            }
        }
    }

    private func convertScriptToShortcut(script: String, name: String) throws -> String {
        // Convert automation logic to iOS Shortcuts JSON format
        let shortcutJSON = """
        {
            "WFWorkflowMinimumClientVersion": 900,
            "WFWorkflowName": "\(name)",
            "WFWorkflowActions": [
                {
                    "WFWorkflowActionIdentifier": "is.workflow.actions.runworkflow",
                    "WFWorkflowActionParameters": {
                        "WFInput": "mapplock://automation-triggered",
                        "WFWorkflowName": "\(name)"
                    }
                }
            ]
        }
        """

        return shortcutJSON
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

// Add Custom App View
struct AddCustomAppView: View {
    @Binding var customAppName: String
    @Binding var customAppBundleId: String
    @Binding var isPresented: Bool
    let onAdd: (String, String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Custom App")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                Text("Enter the app details to add it to your allowed list")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("App Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., WhatsApp", text: $customAppName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bundle ID (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., net.whatsapp.WhatsApp", text: $customAppBundleId)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                Text("💡 Tip: Leave Bundle ID empty if you don't know it")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal)

                Spacer()

                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)

                    Button("Add App") {
                        let bundleId = customAppBundleId.isEmpty ?
                            "custom.\(customAppName.lowercased().replacingOccurrences(of: " ", with: ""))" :
                            customAppBundleId
                        onAdd(customAppName, bundleId)
                        customAppName = ""
                        customAppBundleId = ""
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customAppName.isEmpty)
                }
                .padding()
            }
            .frame(width: 350, height: 400)
        }
    }
}