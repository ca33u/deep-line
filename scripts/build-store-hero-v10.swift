import AppKit
import Foundation

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath,
               isDirectory: true)
let backgroundURL = root.appendingPathComponent(
    "art/source/store-hero-background.png")
let diverURL = root.appendingPathComponent(
    "art/source/store-hero-v10-diver.png")
let outputURL = root.appendingPathComponent(
    "art/source/store-hero-v10.png")

guard let background = NSImage(contentsOf: backgroundURL),
      let backgroundCG = background.cgImage(forProposedRect: nil,
                                             context: nil, hints: nil),
      let diver = NSImage(contentsOf: diverURL) else {
    fatalError("unable to load v10 source assets")
}

let width = backgroundCG.width
let height = backgroundCG.height

guard let result = NSBitmapImageRep(bitmapDataPlanes: nil,
    pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
    fatalError("unable to create output bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: result)
NSGraphicsContext.current?.imageInterpolation = .high

background.draw(in: NSRect(x: 0, y: 0,
    width: width, height: height), from: .zero,
    operation: .copy, fraction: 1,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high])

// Exact user-selected first pose. Keep the figure left of the line and the face
// turned toward it. No generative edit follows this deterministic composite.
diver.draw(in: NSRect(x: 1265, y: 150, width: 104, height: 620),
    from: .zero, operation: .sourceOver, fraction: 0.92,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high])

NSGraphicsContext.restoreGraphicsState()

guard let png = result.representation(using: .png, properties: [:]) else {
    fatalError("unable to encode v10 hero source")
}
try png.write(to: outputURL)
print("wrote \(width)x\(height) composite to \(outputURL.path)")
