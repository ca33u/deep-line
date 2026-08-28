import AppKit
import Foundation

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let output = root.appendingPathComponent("store/assets", isDirectory: true)
try fileManager.createDirectory(at: output, withIntermediateDirectories: true)

func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func bitmap(width: Int, height: Int,
            draw: (_ size: NSSize) throws -> Void) throws -> NSBitmapImageRep {
    guard let result = NSBitmapImageRep(bitmapDataPlanes: nil,
        pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        fatalError("Unable to create bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: result)
    NSGraphicsContext.current?.imageInterpolation = .high
    if let context = NSGraphicsContext.current?.cgContext {
        context.setShouldAntialias(true)
        context.setShouldSmoothFonts(false)
        context.setShouldSubpixelPositionFonts(false)
        context.setShouldSubpixelQuantizeFonts(false)
    }
    try draw(NSSize(width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    return result
}

func write(_ image: NSBitmapImageRep, name: String) throws {
    guard let data = image.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode \(name)")
    }
    try data.write(to: output.appendingPathComponent(name))
}

func path(_ points: [NSPoint], close: Bool = false) -> NSBezierPath {
    let result = NSBezierPath()
    guard let first = points.first else { return result }
    result.move(to: first)
    for point in points.dropFirst() { result.line(to: point) }
    if close { result.close() }
    return result
}

func drawOcean(in rect: NSRect, mip: Bool = false) {
    let top = mip ? color(0x00AAAA) : color(0x18B7B1)
    let middle = mip ? color(0x005555) : color(0x087184)
    let bottom = mip ? color(0x000055) : color(0x041823)
    let gradient = NSGradient(colorsAndLocations:
        (bottom, 0), (middle, 0.53), (top, 1))!
    gradient.draw(in: rect, angle: 90)

    color(0xE7F2E9, alpha: 0.20).setFill()
    for index in 0..<18 {
        let x = rect.minX + CGFloat((index * 83) % Int(rect.width))
        let y = rect.minY + CGFloat((index * 137) % Int(rect.height))
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 3, height: 3)).fill()
    }
}

func drawIcon(size: Int, mip: Bool) throws -> NSBitmapImageRep {
    try bitmap(width: size, height: size) { canvas in
        let rect = NSRect(origin: .zero, size: canvas)
        drawOcean(in: rect, mip: mip)
        let scale = CGFloat(size) / 500
        let cx = CGFloat(size) / 2

        let lineColor = mip ? color(0xFFFFAA) : color(0xF0D69C)
        lineColor.setStroke()
        let line = NSBezierPath()
        line.lineWidth = max(1, 7 * scale)
        line.move(to: NSPoint(x: cx, y: 42 * scale))
        line.line(to: NSPoint(x: cx, y: 445 * scale))
        line.stroke()

        // Buoy: deliberately simple so it survives the small app-list size.
        let buoyRect = NSRect(x: cx - 77 * scale, y: 385 * scale,
            width: 154 * scale, height: 58 * scale)
        (mip ? color(0xFF5555) : color(0xFF6B3D)).setFill()
        NSBezierPath(ovalIn: buoyRect).fill()
        color(0xF6F0DC).setStroke()
        let buoyHighlight = NSBezierPath()
        buoyHighlight.lineWidth = max(1, 9 * scale)
        buoyHighlight.move(to: NSPoint(x: cx - 47 * scale, y: 421 * scale))
        buoyHighlight.curve(to: NSPoint(x: cx + 28 * scale, y: 430 * scale),
            controlPoint1: NSPoint(x: cx - 22 * scale, y: 440 * scale),
            controlPoint2: NSPoint(x: cx + 10 * scale, y: 440 * scale))
        buoyHighlight.stroke()

        color(0x062B3A).setStroke()
        let buoyBand = NSBezierPath()
        buoyBand.lineWidth = max(1, 11 * scale)
        buoyBand.move(to: NSPoint(x: cx, y: 386 * scale))
        buoyBand.line(to: NSPoint(x: cx, y: 443 * scale))
        buoyBand.stroke()

        // Abstract head-down freediver to the left of the line.
        let diverX = cx - 34 * scale
        color(0xF3C785).setFill()
        NSBezierPath(ovalIn: NSRect(x: diverX - 13 * scale,
            y: 292 * scale, width: 26 * scale, height: 26 * scale)).fill()

        color(0x062B3A).setStroke()
        let body = NSBezierPath()
        body.lineCapStyle = .round
        body.lineJoinStyle = .round
        body.lineWidth = max(1, 31 * scale)
        body.move(to: NSPoint(x: diverX, y: 291 * scale))
        body.curve(to: NSPoint(x: diverX - 5 * scale, y: 187 * scale),
            controlPoint1: NSPoint(x: diverX + 7 * scale, y: 260 * scale),
            controlPoint2: NSPoint(x: diverX - 10 * scale, y: 222 * scale))
        body.stroke()

        (mip ? color(0x55FFFF) : color(0x20C6DE)).setStroke()
        let seam = NSBezierPath()
        seam.lineWidth = max(1, 6 * scale)
        seam.move(to: NSPoint(x: diverX + 7 * scale, y: 277 * scale))
        seam.curve(to: NSPoint(x: diverX + 1 * scale, y: 196 * scale),
            controlPoint1: NSPoint(x: diverX + 12 * scale, y: 245 * scale),
            controlPoint2: NSPoint(x: diverX - 1 * scale, y: 224 * scale))
        seam.stroke()

        // Arm reaches toward the line.
        color(0x062B3A).setStroke()
        let arm = NSBezierPath()
        arm.lineCapStyle = .round
        arm.lineWidth = max(1, 15 * scale)
        arm.move(to: NSPoint(x: diverX + 2 * scale, y: 264 * scale))
        arm.line(to: NSPoint(x: cx - 5 * scale, y: 226 * scale))
        arm.stroke()

        // Two readable fins.
        (mip ? color(0x0055AA) : color(0x0B4661)).setFill()
        path([
            NSPoint(x: diverX - 12 * scale, y: 181 * scale),
            NSPoint(x: diverX - 50 * scale, y: 77 * scale),
            NSPoint(x: diverX - 3 * scale, y: 119 * scale)
        ], close: true).fill()
        path([
            NSPoint(x: diverX + 7 * scale, y: 181 * scale),
            NSPoint(x: diverX + 27 * scale, y: 68 * scale),
            NSPoint(x: diverX + 25 * scale, y: 132 * scale)
        ], close: true).fill()

        (mip ? color(0xFFAA00) : color(0xFF6B3D)).setStroke()
        let belt = NSBezierPath()
        belt.lineWidth = max(1, 9 * scale)
        belt.move(to: NSPoint(x: diverX - 14 * scale, y: 231 * scale))
        belt.line(to: NSPoint(x: diverX + 13 * scale, y: 229 * scale))
        belt.stroke()
    }
}

func loadImage(_ relativePath: String) -> NSImage {
    let url = root.appendingPathComponent(relativePath)
    guard let image = NSImage(contentsOf: url) else {
        fatalError("Unable to load \(relativePath)")
    }
    return image
}

func drawImage(_ image: NSImage, in rect: NSRect) {
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1,
        respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
}

func drawText(_ value: String, rect: NSRect, font: NSFont,
              color textColor: NSColor, alignment: NSTextAlignment = .left,
              kern: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, alpha: 0.55)
    shadow.shadowOffset = NSSize(width: 2, height: -3)
    shadow.shadowBlurRadius = 3
    (value as NSString).draw(with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
            .kern: kern,
            .shadow: shadow
        ])
}

func drawHero(filename: String) throws {
    let hero = try bitmap(width: 1440, height: 720) { canvas in
        let rect = NSRect(origin: .zero, size: canvas)
        let keyArt = loadImage("art/source/store-hero-v10.png")
        drawImage(keyArt, in: rect)

        // The illustration deliberately uses large cinematic subjects. A soft
        // left-side veil protects the wordmark without turning the art into a
        // UI panel or covering the orca silhouette.
        let textVeil = NSGradient(colorsAndLocations:
            (color(0x031725, alpha: 0.66), 0),
            (color(0x031725, alpha: 0.30), 0.58),
            (color(0x031725, alpha: 0.0), 1))!
        textVeil.draw(in: NSRect(x: 0, y: 0, width: 850, height: 720), angle: 0)

        guard let titleFont = NSFont(name: "DINCondensed-Bold", size: 190) else {
            fatalError("DIN Condensed Bold is unavailable")
        }

        drawText("DEEP LINE", rect: NSRect(x: 58, y: 192, width: 760, height: 235),
            font: titleFont, color: .white, kern: 2.5)
    }
    try write(hero, name: filename)
}

try write(drawIcon(size: 500, mip: false), name: "app-icon-500.png")
try write(drawIcon(size: 128, mip: true), name: "device-icon-mip-128.png")
try write(drawIcon(size: 128, mip: false), name: "device-icon-amoled-128.png")
try drawHero(filename: "hero-1440x720-en.png")
