import AppKit
import Foundation

struct PaletteColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(_ hex: Int) {
        red = CGFloat((hex >> 16) & 0xFF) / 255
        green = CGFloat((hex >> 8) & 0xFF) / 255
        blue = CGFloat(hex & 0xFF) / 255
    }

    var nsColor: NSColor {
        NSColor(deviceRed: red, green: green, blue: blue, alpha: 1)
    }
}

struct OceanPalette {
    let name: String
    let top: PaletteColor
    let middle: PaletteColor
    let bottom: PaletteColor
}

let palettes = [
    OceanPalette(name: "sea_of_cortez", top: PaletteColor(0x00AAAA),
        middle: PaletteColor(0x005555), bottom: PaletteColor(0x000055)),
    OceanPalette(name: "visayan_sea", top: PaletteColor(0x00AAAA),
        middle: PaletteColor(0x005555), bottom: PaletteColor(0x000000)),
    OceanPalette(name: "red_sea", top: PaletteColor(0x00AAAA),
        middle: PaletteColor(0x0055AA), bottom: PaletteColor(0x000055)),
    OceanPalette(name: "atlantic", top: PaletteColor(0x0055AA),
        middle: PaletteColor(0x000055), bottom: PaletteColor(0x000000)),
    OceanPalette(name: "greenland_sea", top: PaletteColor(0xAAAAAA),
        middle: PaletteColor(0x55AAAA), bottom: PaletteColor(0x005555))
]

let bayer8 = [
     0, 48, 12, 60,  3, 51, 15, 63,
    32, 16, 44, 28, 35, 19, 47, 31,
     8, 56,  4, 52, 11, 59,  7, 55,
    40, 24, 36, 20, 43, 27, 39, 23,
     2, 50, 14, 62,  1, 49, 13, 61,
    34, 18, 46, 30, 33, 17, 45, 29,
    10, 58,  6, 54,  9, 57,  5, 53,
    42, 26, 38, 22, 41, 25, 37, 21
]

let width = 280
let height = 280
let middleStop = 0.48
let outputDirectory = URL(fileURLWithPath: "resources/drawables/generated",
    isDirectory: true)

for palette in palettes {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create MIP ocean bitmap")
    }

    for imageY in 0..<height {
        let y = imageY
        let position = Double(y) / Double(height - 1)
        let upper: PaletteColor
        let lower: PaletteColor
        let blend: Double
        if position <= middleStop {
            upper = palette.top
            lower = palette.middle
            blend = position / middleStop
        } else {
            upper = palette.middle
            lower = palette.bottom
            blend = (position - middleStop) / (1 - middleStop)
        }

        let cutoff = Int((blend * 64).rounded())
        for x in 0..<width {
            let threshold = bayer8[((y & 7) * 8) + (x & 7)]
            bitmap.setColor(threshold < cutoff ? lower.nsColor : upper.nsColor,
                atX: x, y: imageY)
        }
    }

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode MIP ocean bitmap")
    }
    try data.write(to: outputDirectory.appendingPathComponent(
        "ocean_gradient_\(palette.name)_mip.png"))
}
