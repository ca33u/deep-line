import AppKit
import Foundation

struct TitleVariant {
    let suffix: String
    let width: Int
    let height: Int
    let fontSize: CGFloat
    let kern: CGFloat
    let shadowOffset: CGFloat
}

let variants = [
    TitleVariant(suffix: "mip", width: 214, height: 60,
        fontSize: 46, kern: 0.8, shadowOffset: 1),
    TitleVariant(suffix: "amoled", width: 300, height: 80,
        fontSize: 63, kern: 1.2, shadowOffset: 2)
]

let outputDirectory = URL(fileURLWithPath: "resources/drawables/generated",
    isDirectory: true)
let title = "DEEP LINE" as NSString

for variant in variants {
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
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: variant.width, height: variant.height).fill()

    guard let font = NSFont(name: "DINCondensed-Bold", size: variant.fontSize) else {
        fatalError("DIN Condensed Bold is not available")
    }

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedRed: 4 / 255, green: 24 / 255,
        blue: 35 / 255, alpha: 0.62)
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
            .strokeColor: NSColor(calibratedRed: 4 / 255, green: 24 / 255,
                blue: 35 / 255, alpha: 0.72),
            .strokeWidth: -1.1,
            .shadow: shadow,
            .foregroundColor: NSColor(calibratedRed: 246 / 255,
                green: 240 / 255, blue: 220 / 255, alpha: 1)
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
    try data.write(to: outputDirectory
        .appendingPathComponent("deep_line_title_\(variant.suffix).png"))
}
