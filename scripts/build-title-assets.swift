import AppKit
import Foundation

struct TitleVariant {
    let outputDirectory: String
    let filename: String
    let width: Int
    let height: Int
    let fontSize: CGFloat
    let kern: CGFloat
    let shadowOffset: CGFloat
}

let variants = [
    TitleVariant(outputDirectory: "resources/drawables/generated",
        filename: "deep_line_title_mip.png", width: 214, height: 60,
        fontSize: 46, kern: 0.8, shadowOffset: 1),
    TitleVariant(outputDirectory: "resources/drawables/generated",
        filename: "deep_line_title_amoled.png", width: 300, height: 80,
        fontSize: 63, kern: 1.2, shadowOffset: 2),
    TitleVariant(outputDirectory: "resources-round-416x416/drawables/generated",
        filename: "deep_line_title_amoled.png", width: 320, height: 85,
        fontSize: 67, kern: 1.3, shadowOffset: 2),
    TitleVariant(outputDirectory: "resources-round-454x454/drawables/generated",
        filename: "deep_line_title_amoled.png", width: 349, height: 93,
        fontSize: 73, kern: 1.4, shadowOffset: 2),
    TitleVariant(outputDirectory: "resources-round-466x466/drawables/generated",
        filename: "deep_line_title_amoled.png", width: 358, height: 96,
        fontSize: 75, kern: 1.4, shadowOffset: 2)
]
let title = "DEEP LINE" as NSString

for variant in variants {
    let outputDirectory = URL(fileURLWithPath: variant.outputDirectory,
        isDirectory: true)
    try FileManager.default.createDirectory(at: outputDirectory,
        withIntermediateDirectories: true)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: variant.width,
        pixelsHigh: variant.height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create title bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    if let context = NSGraphicsContext.current?.cgContext {
        // Garmin MIP quantization exaggerates colored LCD subpixel fringes.
        // Keep grayscale antialiasing, but never bake RGB subpixels into the PNG.
        context.setShouldAntialias(true)
        context.setShouldSmoothFonts(false)
        context.setShouldSubpixelPositionFonts(false)
        context.setShouldSubpixelQuantizeFonts(false)
    }
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: variant.width, height: variant.height).fill()

    guard let font = NSFont(name: "DINCondensed-Bold", size: variant.fontSize) else {
        fatalError("DIN Condensed Bold is not available")
    }

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.62)
    shadow.shadowOffset = NSSize(width: variant.shadowOffset,
        height: -variant.shadowOffset)
    shadow.shadowBlurRadius = variant.shadowOffset

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributed = NSMutableAttributedString(string: title as String,
        attributes: [
            .font: font,
            .kern: variant.kern,
            .paragraphStyle: paragraph,
            .strokeColor: NSColor(calibratedWhite: 0, alpha: 0.72),
            .strokeWidth: -1.1,
            .shadow: shadow,
            .foregroundColor: NSColor.white
        ])
    let bounds = attributed.boundingRect(
        with: NSSize(width: CGFloat(variant.width), height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading])
    let rect = NSRect(x: 0,
        y: (CGFloat(variant.height) - bounds.height) / 2 - bounds.minY,
        width: CGFloat(variant.width), height: bounds.height)
    attributed.draw(with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading])
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode title bitmap")
    }
    try data.write(to: outputDirectory.appendingPathComponent(variant.filename))
}
