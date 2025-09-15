// MappLockWidget.swift - iOS Widget Extension
import WidgetKit
import SwiftUI
import MappLockCore
import OSLog

@main
struct MappLockWidgets: WidgetBundle {
    var body: some Widget {
        SessionStatusWidget()
        QuickActionsWidget()
        AnalyticsWidget()
    }
}

// MARK: - Session Status Widget
struct SessionStatusWidget: Widget {
    let kind: String = "SessionStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SessionStatusProvider()) { entry in
            SessionStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Session Status")
        .description("View your current MappLock session status and remaining time")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SessionStatusProvider: TimelineProvider {
    private let logger = Logger(subsystem: "com.mapplock.widgets", category: "SessionStatusProvider")

    func placeholder(in context: Context) -> SessionStatusEntry {
        SessionStatusEntry(
            date: Date(),
            sessionState: .active,
            remainingTime: 3600,
            sessionName: "Focus Session",
            violationCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SessionStatusEntry) -> Void) {
        let entry = SessionStatusEntry(
            date: Date(),
            sessionState: .active,
            remainingTime: 2400,
            sessionName: "Study Session",
            violationCount: 2
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionStatusEntry>) -> Void) {
        Task {
            let currentEntry = await getCurrentSessionStatus()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()

            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func getCurrentSessionStatus() async -> SessionStatusEntry {
        // In a real implementation, this would read from shared app group
        // For now, return a sample entry
        return SessionStatusEntry(
            date: Date(),
            sessionState: .inactive,
            remainingTime: 0,
            sessionName: nil,
            violationCount: 0
        )
    }
}

struct SessionStatusEntry: TimelineEntry {
    let date: Date
    let sessionState: SessionState
    let remainingTime: TimeInterval
    let sessionName: String?
    let violationCount: Int
}

struct SessionStatusWidgetView: View {
    let entry: SessionStatusEntry

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text("MappLock")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                statusIndicator
            }

            if entry.sessionState.isActive {
                // Active Session View
                VStack(spacing: 4) {
                    Text(entry.sessionName ?? "Active Session")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(formatTime(entry.remainingTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.primary)

                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Progress Bar
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                // Violations (if any)
                if entry.violationCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)

                        Text("\\(entry.violationCount) alert\\(entry.violationCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            } else {
                // Inactive Session View
                VStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text("No Active Session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Tap to start")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .widgetURL(entry.sessionState.isActive ? nil : URL(string: "mapplock://start-session"))
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        switch entry.sessionState {
        case .active: return .green
        case .paused: return .orange
        case .inactive: return .gray
        default: return .blue
        }
    }

    private var progressValue: Double {
        // This would need actual session duration data
        return 0.6
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60

        if hours > 0 {
            return "\\(hours)h \\(minutes)m"
        } else {
            return "\\(minutes)m"
        }
    }
}

// MARK: - Quick Actions Widget
struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quick access to MappLock session controls")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionsEntry {
        QuickActionsEntry(date: Date(), sessionState: .inactive)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        let entry = QuickActionsEntry(date: Date(), sessionState: .active)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        Task {
            let currentEntry = await getCurrentSessionState()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()

            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func getCurrentSessionState() async -> QuickActionsEntry {
        // Read from shared app group
        return QuickActionsEntry(date: Date(), sessionState: .inactive)
    }
}

struct QuickActionsEntry: TimelineEntry {
    let date: Date
    let sessionState: SessionState
}

struct QuickActionsWidgetView: View {
    let entry: QuickActionsEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)

                Text("MappLock")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(entry.sessionState.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
            }

            // Action Buttons
            HStack(spacing: 12) {
                if entry.sessionState.isActive {
                    // Active session actions
                    QuickActionButton(
                        icon: "pause.fill",
                        title: "Pause",
                        color: .orange,
                        url: "mapplock://pause-session"
                    )

                    QuickActionButton(
                        icon: "stop.fill",
                        title: "Stop",
                        color: .red,
                        url: "mapplock://end-session"
                    )

                    QuickActionButton(
                        icon: "plus.circle.fill",
                        title: "Extend",
                        color: .blue,
                        url: "mapplock://extend-session"
                    )
                } else {
                    // Inactive session actions
                    QuickActionButton(
                        icon: "play.fill",
                        title: "Focus",
                        color: .green,
                        url: "mapplock://quick-focus"
                    )

                    QuickActionButton(
                        icon: "book.fill",
                        title: "Study",
                        color: .blue,
                        url: "mapplock://quick-study"
                    )

                    QuickActionButton(
                        icon: "briefcase.fill",
                        title: "Work",
                        color: .purple,
                        url: "mapplock://quick-work"
                    )
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
    }

    private var statusColor: Color {
        switch entry.sessionState {
        case .active: return .green
        case .paused: return .orange
        case .inactive: return .gray
        default: return .blue
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(8)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Analytics Widget
struct AnalyticsWidget: Widget {
    let kind: String = "AnalyticsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnalyticsProvider()) { entry in
            AnalyticsWidgetView(entry: entry)
        }
        .configurationDisplayName("Session Analytics")
        .description("View your focus session statistics and trends")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AnalyticsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalyticsEntry {
        AnalyticsEntry(
            date: Date(),
            todayFocusTime: 120,
            weekFocusTime: 840,
            streakDays: 5,
            topBlockedApp: "Social Media"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AnalyticsEntry) -> Void) {
        let entry = AnalyticsEntry(
            date: Date(),
            todayFocusTime: 180,
            weekFocusTime: 960,
            streakDays: 7,
            topBlockedApp: "Gaming Apps"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalyticsEntry>) -> Void) {
        Task {
            let currentEntry = await getCurrentAnalytics()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func getCurrentAnalytics() async -> AnalyticsEntry {
        // Read analytics from shared app group
        return AnalyticsEntry(
            date: Date(),
            todayFocusTime: 90,
            weekFocusTime: 420,
            streakDays: 3,
            topBlockedApp: "Social Media"
        )
    }
}

struct AnalyticsEntry: TimelineEntry {
    let date: Date
    let todayFocusTime: Int // minutes
    let weekFocusTime: Int // minutes
    let streakDays: Int
    let topBlockedApp: String
}

struct AnalyticsWidgetView: View {
    let entry: AnalyticsEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)

                Text("Focus Analytics")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AnalyticsStat(
                    icon: "clock.fill",
                    title: "Today",
                    value: "\\(entry.todayFocusTime)m",
                    color: .blue
                )

                AnalyticsStat(
                    icon: "calendar.badge.clock",
                    title: "This Week",
                    value: "\\(formatHours(entry.weekFocusTime))",
                    color: .green
                )

                AnalyticsStat(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\\(entry.streakDays) days",
                    color: .orange
                )

                AnalyticsStat(
                    icon: "shield.fill",
                    title: "Top Block",
                    value: entry.topBlockedApp,
                    color: .red
                )
            }

            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .widgetURL(URL(string: "mapplock://analytics"))
    }

    private func formatHours(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\\(hours)h \\(mins)m"
        } else {
            return "\\(mins)m"
        }
    }
}

struct AnalyticsStat: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Widget Previews
struct SessionStatusWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SessionStatusWidgetView(entry: SessionStatusEntry(
                date: Date(),
                sessionState: .active,
                remainingTime: 3600,
                sessionName: "Focus Session",
                violationCount: 2
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            SessionStatusWidgetView(entry: SessionStatusEntry(
                date: Date(),
                sessionState: .inactive,
                remainingTime: 0,
                sessionName: nil,
                violationCount: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}

struct QuickActionsWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuickActionsWidgetView(entry: QuickActionsEntry(
                date: Date(),
                sessionState: .active
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            QuickActionsWidgetView(entry: QuickActionsEntry(
                date: Date(),
                sessionState: .inactive
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

struct AnalyticsWidget_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsWidgetView(entry: AnalyticsEntry(
            date: Date(),
            todayFocusTime: 120,
            weekFocusTime: 840,
            streakDays: 5,
            topBlockedApp: "Social Media"
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}