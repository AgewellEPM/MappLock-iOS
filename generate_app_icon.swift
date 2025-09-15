#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MappLock App Icon Generator
// Generates all required App Store icon sizes from base design

struct AppIconSize {
    let name: String
    let size: CGFloat
    let scale: CGFloat
    let filename: String
    let platform: String

    var pixelSize: CGFloat {
        return size * scale
    }
}

let appIconSizes: [AppIconSize] = [
    // iPhone
    AppIconSize(name: "iPhone Notification", size: 20, scale: 2, filename: "Icon-20@2x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone Notification", size: 20, scale: 3, filename: "Icon-20@3x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone Settings", size: 29, scale: 2, filename: "Icon-29@2x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone Settings", size: 29, scale: 3, filename: "Icon-29@3x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone Spotlight", size: 40, scale: 2, filename: "Icon-40@2x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone Spotlight", size: 40, scale: 3, filename: "Icon-40@3x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone App", size: 60, scale: 2, filename: "Icon-60@2x.png", platform: "iPhone"),
    AppIconSize(name: "iPhone App", size: 60, scale: 3, filename: "Icon-60@3x.png", platform: "iPhone"),

    // iPad
    AppIconSize(name: "iPad Notification", size: 20, scale: 1, filename: "Icon-20.png", platform: "iPad"),
    AppIconSize(name: "iPad Notification", size: 20, scale: 2, filename: "Icon-20@2x.png", platform: "iPad"),
    AppIconSize(name: "iPad Settings", size: 29, scale: 1, filename: "Icon-29.png", platform: "iPad"),
    AppIconSize(name: "iPad Settings", size: 29, scale: 2, filename: "Icon-29@2x.png", platform: "iPad"),
    AppIconSize(name: "iPad Spotlight", size: 40, scale: 1, filename: "Icon-40.png", platform: "iPad"),
    AppIconSize(name: "iPad Spotlight", size: 40, scale: 2, filename: "Icon-40@2x.png", platform: "iPad"),
    AppIconSize(name: "iPad App", size: 76, scale: 1, filename: "Icon-76.png", platform: "iPad"),
    AppIconSize(name: "iPad App", size: 76, scale: 2, filename: "Icon-76@2x.png", platform: "iPad"),
    AppIconSize(name: "iPad Pro App", size: 83.5, scale: 2, filename: "Icon-83.5@2x.png", platform: "iPad"),

    // App Store
    AppIconSize(name: "App Store", size: 1024, scale: 1, filename: "Icon-1024.png", platform: "App Store"),
]

func createMappLockIcon(size: CGFloat) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background gradient (Blue to Purple)
    let gradientColors = [
        CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0), // Light blue
        CGColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0)  // Purple
    ]

    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: gradientColors as CFArray,
        locations: [0.0, 1.0]
    ) else {
        return nil
    }

    // Draw gradient background
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size, y: size),
        options: []
    )

    // Apply rounded corners for modern iOS look
    let cornerRadius = size * 0.2237 // iOS app icon corner radius ratio
    let path = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )
    context.addPath(path)
    context.clip()

    // Redraw gradient within clipped area
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size, y: size),
        options: []
    )

    // Draw lock symbol
    drawLockSymbol(in: context, rect: rect, size: size)

    // Add subtle highlight
    addHighlight(in: context, rect: rect, size: size)

    return context.makeImage()
}

func drawLockSymbol(in context: CGContext, rect: CGRect, size: CGFloat) {
    let centerX = size / 2
    let centerY = size / 2
    let lockSize = size * 0.5

    // Set drawing properties
    context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9))
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9))
    context.setLineWidth(size * 0.08)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    // Lock body (rounded rectangle)
    let bodyHeight = lockSize * 0.6
    let bodyWidth = lockSize * 0.7
    let bodyY = centerY + lockSize * 0.1
    let bodyRect = CGRect(
        x: centerX - bodyWidth / 2,
        y: bodyY - bodyHeight / 2,
        width: bodyWidth,
        height: bodyHeight
    )

    let bodyPath = CGPath(
        roundedRect: bodyRect,
        cornerWidth: size * 0.05,
        cornerHeight: size * 0.05,
        transform: nil
    )
    context.addPath(bodyPath)
    context.fillPath()

    // Lock shackle (U-shape)
    let shackleWidth = lockSize * 0.4
    let shackleHeight = lockSize * 0.35
    let shackleY = centerY - lockSize * 0.15

    let shacklePath = CGMutablePath()

    // Left side of shackle
    shacklePath.move(to: CGPoint(
        x: centerX - shackleWidth / 2,
        y: shackleY + shackleHeight / 2
    ))

    // Top arc
    shacklePath.addArc(
        center: CGPoint(x: centerX, y: shackleY + shackleHeight / 2),
        radius: shackleWidth / 2,
        startAngle: CGFloat.pi,
        endAngle: 0,
        clockwise: false
    )

    // Right side of shackle
    shacklePath.addLine(to: CGPoint(
        x: centerX + shackleWidth / 2,
        y: shackleY + shackleHeight * 0.8
    ))

    context.addPath(shacklePath)
    context.strokePath()

    // Keyhole
    let keyholeRadius = size * 0.03
    let keyholeY = centerY + lockSize * 0.05

    context.addEllipse(in: CGRect(
        x: centerX - keyholeRadius,
        y: keyholeY - keyholeRadius,
        width: keyholeRadius * 2,
        height: keyholeRadius * 2
    ))

    // Keyhole slot
    let slotWidth = size * 0.015
    let slotHeight = size * 0.05
    context.addRect(CGRect(
        x: centerX - slotWidth / 2,
        y: keyholeY,
        width: slotWidth,
        height: slotHeight
    ))

    context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.8))
    context.fillPath()
}

func addHighlight(in context: CGContext, rect: CGRect, size: CGFloat) {
    // Add subtle gradient highlight at top
    let highlightHeight = size * 0.3
    let highlightRect = CGRect(
        x: 0,
        y: 0,
        width: size,
        height: highlightHeight
    )

    let highlightColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2),
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    ]

    guard let highlightGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: highlightColors as CFArray,
        locations: [0.0, 1.0]
    ) else {
        return
    }

    context.drawLinearGradient(
        highlightGradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: 0, y: highlightHeight),
        options: []
    )
}

func savePNGImage(_ image: CGImage, to url: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }

    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

func generateAllIcons() {
    let outputDirectory = "Assets.xcassets/AppIcon.appiconset/"

    // Create output directory
    try? FileManager.default.createDirectory(
        atPath: outputDirectory,
        withIntermediateDirectories: true,
        attributes: nil
    )

    print("🎨 Generating MappLock app icons...")
    print("📁 Output directory: \(outputDirectory)")

    var contentsJSON: [String: Any] = [
        "images": [],
        "info": [
            "author": "xcode",
            "version": 1
        ]
    ]

    var images: [[String: Any]] = []

    for iconSize in appIconSizes {
        print("🖼️  Generating \(iconSize.name) (\(Int(iconSize.pixelSize))x\(Int(iconSize.pixelSize)))")

        guard let iconImage = createMappLockIcon(size: iconSize.pixelSize) else {
            print("❌ Failed to create icon for size \(iconSize.pixelSize)")
            continue
        }

        let outputURL = URL(fileURLWithPath: outputDirectory + iconSize.filename)

        if savePNGImage(iconImage, to: outputURL) {
            print("✅ Saved: \(iconSize.filename)")

            // Add to Contents.json
            var imageEntry: [String: Any] = [
                "filename": iconSize.filename,
                "idiom": iconSize.platform.lowercased(),
                "scale": "\(Int(iconSize.scale))x",
                "size": "\(Int(iconSize.size))x\(Int(iconSize.size))"
            ]

            if iconSize.platform == "App Store" {
                imageEntry["idiom"] = "ios-marketing"
                imageEntry.removeValue(forKey: "scale")
            }

            images.append(imageEntry)
        } else {
            print("❌ Failed to save: \(iconSize.filename)")
        }
    }

    contentsJSON["images"] = images

    // Save Contents.json
    let contentsURL = URL(fileURLWithPath: outputDirectory + "Contents.json")
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: contentsJSON, options: .prettyPrinted)
        try jsonData.write(to: contentsURL)
        print("✅ Saved: Contents.json")
    } catch {
        print("❌ Failed to save Contents.json: \(error)")
    }

    print("🎉 Icon generation complete!")
    print("📱 Generated \(appIconSizes.count) icon sizes")
    print("🗂️  All icons saved to: \(outputDirectory)")
}

// Run the generator
generateAllIcons()