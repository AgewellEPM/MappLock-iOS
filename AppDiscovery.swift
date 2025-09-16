// AppDiscovery.swift - Discover installed apps on the device
import UIKit
import SwiftUI
import OSLog

class AppDiscovery: ObservableObject {
    @Published var installedApps: [BlockableApp] = []
    private let logger = Logger(subsystem: "com.mapplock.ios", category: "AppDiscovery")

    init() {
        loadInstalledApps()
    }

    func loadInstalledApps() {
        logger.info("Loading installed apps")

        // Get all installed apps
        // Note: iOS restricts app enumeration for privacy

        var apps: [BlockableApp] = []

        // Check if running in simulator
        #if targetEnvironment(simulator)
        logger.info("Running in simulator - showing simulator apps")
        #else
        logger.info("Running on device - checking for installed apps")
        #endif

        // Add system apps that are always present
        let knownApps = [
            ("com.apple.mobilesafari", "Safari", "safari"),
            ("com.apple.mobilemail", "Mail", "envelope.fill"),
            ("com.apple.mobilenotes", "Notes", "note.text"),
            ("com.apple.reminders", "Reminders", "checklist"),
            ("com.apple.mobilecal", "Calendar", "calendar"),
            ("com.apple.camera", "Camera", "camera.fill"),
            ("com.apple.photos", "Photos", "photo.fill"),
            ("com.apple.Maps", "Maps", "map.fill"),
            ("com.apple.AppStore", "App Store", "bag.fill"),
            ("com.apple.Music", "Music", "music.note"),
            ("com.apple.podcasts", "Podcasts", "mic.circle.fill"),
            ("com.apple.tv", "TV", "tv.fill"),
            ("com.apple.news", "News", "newspaper.fill"),
            ("com.apple.iBooks", "Books", "book.fill"),
            ("com.apple.Health", "Health", "heart.fill"),
            ("com.apple.Home", "Home", "house.fill"),
            ("com.apple.facetime", "FaceTime", "video.fill"),
            ("com.apple.calculator", "Calculator", "number"),
            ("com.apple.weather", "Weather", "cloud.sun.fill"),
            ("com.apple.stocks", "Stocks", "chart.line.uptrend.xyaxis"),
        ]

        // Add known third-party apps that might be installed
        let thirdPartyApps = [
            ("com.facebook.Facebook", "Facebook", "person.2.fill"),
            ("com.burbn.instagram", "Instagram", "camera.fill"),
            ("com.atebits.Tweetie2", "Twitter", "message.fill"),
            ("com.zhiliaoapp.musically", "TikTok", "music.note"),
            ("com.google.ios.youtube", "YouTube", "play.rectangle.fill"),
            ("com.spotify.client", "Spotify", "music.note.list"),
            ("com.netflix.Netflix", "Netflix", "tv.fill"),
            ("com.snapchat.picaboo", "Snapchat", "camera.badge.ellipsis"),
            ("com.roblox.robloxmobile", "Roblox", "gamecontroller.fill"),
            ("com.supercell.magic", "Clash Royale", "gamecontroller.fill"),
            ("com.mojang.minecraftpe", "Minecraft", "cube.fill"),
            ("com.innersloth.amongus", "Among Us", "person.fill.questionmark"),
            ("com.discord.Discord", "Discord", "message.circle.fill"),
            ("com.reddit.Reddit", "Reddit", "quote.bubble.fill"),
            ("com.google.chrome.ios", "Chrome", "globe"),
            ("com.microsoft.Office.Outlook", "Outlook", "envelope.fill"),
            ("com.amazon.Amazon", "Amazon", "cart.fill"),
            ("com.ubercab.UberClient", "Uber", "car.fill"),
            ("com.airbnb.app", "Airbnb", "house.fill"),
        ]

        // Combine all apps
        for (bundleId, name, icon) in knownApps {
            // System apps are always present
            apps.append(BlockableApp(
                name: name,
                bundleId: bundleId,
                icon: icon,
                category: categorizeApp(bundleId: bundleId)
            ))
        }

        // Check for third-party apps (only if actually installed)
        for (bundleId, name, icon) in thirdPartyApps {
            #if targetEnvironment(simulator)
            // In simulator, show a subset of common apps for demo
            if ["com.burbn.instagram", "com.google.ios.youtube", "com.zhiliaoapp.musically",
                "com.facebook.Facebook", "com.atebits.Tweetie2", "com.snapchat.picaboo",
                "com.roblox.robloxmobile", "com.netflix.Netflix"].contains(bundleId) {
                apps.append(BlockableApp(
                    name: name,
                    bundleId: bundleId,
                    icon: icon,
                    category: categorizeApp(bundleId: bundleId)
                ))
            }
            #else
            // On device, check if app is actually installed
            if let url = URL(string: "\(bundleId.replacingOccurrences(of: ".", with: ""))://"),
               UIApplication.shared.canOpenURL(url) {
                apps.append(BlockableApp(
                    name: name,
                    bundleId: bundleId,
                    icon: icon,
                    category: categorizeApp(bundleId: bundleId)
                ))
            }
            #endif
        }

        // Sort apps alphabetically
        apps.sort { $0.name < $1.name }

        DispatchQueue.main.async {
            self.installedApps = apps
            self.logger.info("Found \(apps.count) installed apps")
        }
    }

    private func isAppInstalled(bundleId: String) -> Bool {
        // Try to check if app is installed using URL scheme
        if let url = URL(string: "\(bundleId)://") {
            return UIApplication.shared.canOpenURL(url)
        }

        // For system apps, assume they're installed
        if bundleId.starts(with: "com.apple.") {
            return true
        }

        return false
    }

    private func categorizeApp(bundleId: String) -> String {
        if bundleId.contains("game") || bundleId.contains("Game") {
            return "Gaming"
        } else if bundleId.contains("social") || bundleId == "com.facebook.Facebook" ||
                  bundleId == "com.burbn.instagram" || bundleId == "com.atebits.Tweetie2" ||
                  bundleId == "com.zhiliaoapp.musically" || bundleId == "com.snapchat.picaboo" {
            return "Social"
        } else if bundleId.contains("video") || bundleId == "com.google.ios.youtube" ||
                  bundleId == "com.netflix.Netflix" {
            return "Video"
        } else if bundleId.contains("music") || bundleId == "com.spotify.client" {
            return "Music"
        } else if bundleId.starts(with: "com.apple.") {
            return "System"
        } else {
            return "Other"
        }
    }

    func getAppIcon(for bundleId: String) -> UIImage? {
        // Try to get the actual app icon
        // This is limited in iOS, but we can try a few approaches

        // For now, return nil and use SF Symbols as fallback
        return nil
    }
}

// Extension to load real app icons where possible
extension AppDiscovery {
    func loadRealAppIcon(for app: BlockableApp, completion: @escaping (UIImage?) -> Void) {
        // In a real implementation, you might:
        // 1. Use private APIs (not for App Store)
        // 2. Fetch from a server that has app icons
        // 3. Use iTunes Search API for App Store apps

        // For now, we'll try to fetch from iTunes API for third-party apps
        if !app.bundleId.starts(with: "com.apple.") {
            fetchAppIconFromiTunes(bundleId: app.bundleId) { image in
                completion(image)
            }
        } else {
            completion(nil)
        }
    }

    private func fetchAppIconFromiTunes(bundleId: String, completion: @escaping (UIImage?) -> Void) {
        // iTunes Search API to get app icon
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let firstResult = results.first,
                  let iconURLString = firstResult["artworkUrl512"] as? String,
                  let iconURL = URL(string: iconURLString) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // Download the icon
            URLSession.shared.dataTask(with: iconURL) { iconData, _, _ in
                if let iconData = iconData,
                   let image = UIImage(data: iconData) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
        }.resume()
    }
}