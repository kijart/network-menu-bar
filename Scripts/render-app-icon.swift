#!/usr/bin/env swift
// Renders Design/AppIcon.svg into every size of the app icon set.
// Usage: swift Scripts/render-app-icon.swift

import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("Design/AppIcon.svg")
let iconSet = root.appendingPathComponent("NetworkMenuBar/Assets.xcassets/AppIcon.appiconset")

guard let svg = NSImage(contentsOf: source) else {
    fatalError("Cannot load \(source.path)")
}

let sizes = [16, 32, 128, 256, 512]
var images: [[String: String]] = []

for size in sizes {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -CGFloat(pixels) * 12 / 1024)
        shadow.shadowBlurRadius = CGFloat(pixels) * 28 / 1024
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.set()
        svg.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()

        let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try rep.representation(using: .png, properties: [:])!.write(to: iconSet.appendingPathComponent(filename))
        images.append(["filename": filename, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: iconSet.appendingPathComponent("Contents.json"))
print("Rendered \(images.count) images into \(iconSet.path)")
