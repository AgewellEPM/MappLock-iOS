// CreativeKioskSetupView.swift - Creative Kiosk Mode Setup Interface
import SwiftUI
import OSLog

struct CreativeKioskSetupView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var kioskManager: iOSKioskManager
    @State private var selectedCycle: CreativeCycle = .pomodoro
    @State private var customFocusDuration: Double = 25
    @State private var customBreakDuration: Double = 5
    @State private var installedApps: [AppInfo] = []
    @State private var focusApps: Set<String> = []
    @State private var creativeApps: Set<String> = []
    @State private var blockedApps: Set<String> = []
    @State private var showingInstallation = false
    @State private var installationProgress: Double = 0
    @State private var isInstalling = false

    private let logger = Logger(subsystem: "com.mapplock.ios", category: "CreativeKioskSetup")

    var body: some View {
        NavigationView {
            ZStack {
                // Dark theme base
                Color(.sRGB, red: 0.04, green: 0.04, blue: 0.06)
                    .edgesIgnoringSafeArea(.all)

                // Animated background gradient
                AnimatedGradientBackground()
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        MagicalHeaderView(
                            title: "Creative Kiosk Mode",
                            subtitle: "Transform your device into a productivity powerhouse"
                        )

                        // Step 1: Choose Creative Cycle
                        CreativeCycleSelector(
                            selectedCycle: $selectedCycle,
                            customFocusDuration: $customFocusDuration,
                            customBreakDuration: $customBreakDuration
                        )

                        // Step 2: Categorize Apps
                        if !installedApps.isEmpty {
                            AppCategorizationView(
                                apps: installedApps,
                                focusApps: $focusApps,
                                creativeApps: $creativeApps,
                                blockedApps: $blockedApps
                            )
                        }

                        // Step 3: Install Kiosk Mode
                        InstallKioskModeCard(
                            isInstalling: $isInstalling,
                            progress: $installationProgress,
                            installAction: installCreativeKioskMode
                        )
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadInstalledApps()
        }
    }

    private func loadInstalledApps() {
        Task {
            do {
                installedApps = try await kioskManager.getRunningApps()
            } catch {
                logger.error("Failed to load installed apps: \(error)")
            }
        }
    }

    private func installCreativeKioskMode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isInstalling = true
            installationProgress = 0
        }

        Task {
            await performKioskInstallation()
        }
    }

    private func performKioskInstallation() async {
        // Simulate installation progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    installationProgress = progress
                }
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        }

        await MainActor.run {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isInstalling = false
                // Show success state
            }
        }
    }
}

// MARK: - Creative Cycle Types
enum CreativeCycle: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case ultradian = "Ultradian"
    case custom = "Custom"

    var focusDuration: Double {
        switch self {
        case .pomodoro: return 25
        case .ultradian: return 90
        case .custom: return 25 // Default, user customizable
        }
    }

    var breakDuration: Double {
        switch self {
        case .pomodoro: return 5
        case .ultradian: return 20
        case .custom: return 5 // Default, user customizable
        }
    }

    var description: String {
        switch self {
        case .pomodoro: return "25min focus / 5min creative break"
        case .ultradian: return "90min focus / 20min creative break"
        case .custom: return "Set your own timing"
        }
    }

    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .ultradian: return "clock"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Magical Header View
struct MagicalHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Magical glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.4), .blue.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(100 + i * 15), height: CGFloat(100 + i * 15))
                        .opacity(0.6)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(i)) * 0.1)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(i) * 0.5)
                            .repeatForever(autoreverses: true),
                            value: Date().timeIntervalSince1970
                        )
                }

                // Central icon
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.5), radius: 10)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Creative Cycle Selector
struct CreativeCycleSelector: View {
    @Binding var selectedCycle: CreativeCycle
    @Binding var customFocusDuration: Double
    @Binding var customBreakDuration: Double

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Your Creative Cycle")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                ForEach(CreativeCycle.allCases, id: \.self) { cycle in
                    CreativeCycleCard(
                        cycle: cycle,
                        isSelected: selectedCycle == cycle,
                        customFocusDuration: $customFocusDuration,
                        customBreakDuration: $customBreakDuration
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedCycle = cycle
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Creative Cycle Card
struct CreativeCycleCard: View {
    let cycle: CreativeCycle
    let isSelected: Bool
    @Binding var customFocusDuration: Double
    @Binding var customBreakDuration: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: cycle.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.rawValue)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(cycle.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .ultraThinMaterial : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(
                                    colors: [.purple.opacity(0.5), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())

        // Custom duration sliders for custom cycle
        if cycle == .custom && isSelected {
            VStack(spacing: 16) {
                CustomDurationSlider(
                    title: "Focus Duration",
                    value: $customFocusDuration,
                    range: 15...120,
                    unit: "min"
                )

                CustomDurationSlider(
                    title: "Creative Break",
                    value: $customBreakDuration,
                    range: 5...30,
                    unit: "min"
                )
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Custom Duration Slider
struct CustomDurationSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Slider(value: $value, in: range, step: 1) {
                Text(title)
            } minimumValueLabel: {
                Text("\(Int(range.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } maximumValueLabel: {
                Text("\(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .accentColor(.purple)
        }
    }
}

// MARK: - App Categorization View
struct AppCategorizationView: View {
    let apps: [AppInfo]
    @Binding var focusApps: Set<String>
    @Binding var creativeApps: Set<String>
    @Binding var blockedApps: Set<String>

    var body: some View {
        VStack(spacing: 24) {
            Text("Categorize Your Apps")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 20) {
                AppCategorySection(
                    title: "Focus Apps",
                    subtitle: "Apps that help you work and stay productive",
                    icon: "brain.head.profile",
                    color: .green,
                    apps: apps,
                    selectedApps: $focusApps
                )

                AppCategorySection(
                    title: "Creative Apps",
                    subtitle: "Apps for inspiration during breaks",
                    icon: "paintbrush.fill",
                    color: .orange,
                    apps: apps,
                    selectedApps: $creativeApps
                )

                AppCategorySection(
                    title: "Blocked Apps",
                    subtitle: "Distracting apps to block during focus",
                    icon: "xmark.circle.fill",
                    color: .red,
                    apps: apps,
                    selectedApps: $blockedApps
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - App Category Section
struct AppCategorySection: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let apps: [AppInfo]
    @Binding var selectedApps: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Text("\(selectedApps.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.2))
                    )
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(apps.prefix(8), id: \.id) { app in
                    AppToggleCard(
                        app: app,
                        isSelected: selectedApps.contains(app.bundleId),
                        color: color
                    ) {
                        toggleApp(app.bundleId)
                    }
                }
            }
        }
    }

    private func toggleApp(_ bundleId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedApps.contains(bundleId) {
                selectedApps.remove(bundleId)
            } else {
                selectedApps.insert(bundleId)
            }
        }
    }
}

// MARK: - App Toggle Card
struct AppToggleCard: View {
    let app: AppInfo
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.3) : .gray.opacity(0.2))
                        .frame(width: 50, height: 50)

                    // App icon placeholder
                    Image(systemName: "app.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? color : .white.opacity(0.6))

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(color)
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            Spacer()
                        }
                    }
                }

                Text(app.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Install Kiosk Mode Card
struct InstallKioskModeCard: View {
    @Binding var isInstalling: Bool
    @Binding var progress: Double
    let installAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Install Creative Kiosk Mode")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("This will create automations that manage your focus and creative cycles automatically")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            if isInstalling {
                VStack(spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 2)

                    Text("Installing automations... \(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Button(action: installAction) {
                    HStack(spacing: 12) {
                        Image(systemName: "gear.badge.checkmark")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Install Kiosk Mode")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct CreativeKioskSetupView_Previews: PreviewProvider {
    static var previews: some View {
        CreativeKioskSetupView()
            .environmentObject(SessionManager())
            .environmentObject(iOSKioskManager())
    }
}