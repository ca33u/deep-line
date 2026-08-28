import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: swift scripts/extract-store-diver.swift input.png output.png")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let sourceImage = NSImage(contentsOf: inputURL),
      let sourceCG = sourceImage.cgImage(forProposedRect: nil, context: nil,
                                        hints: nil) else {
    fatalError("unable to load input image")
}

let width = sourceCG.width
let height = sourceCG.height
let bytesPerRow = width * 4
let colorSpace = CGColorSpaceCreateDeviceRGB()
var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

guard let context = CGContext(data: &pixels, width: width, height: height,
    bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("unable to create RGBA context")
}

context.interpolationQuality = .high
context.draw(sourceCG, in: CGRect(x: 0, y: 0, width: width, height: height))

var minX = width
var minY = height
var maxX = -1
var maxY = -1

for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * 4
        let red = Double(pixels[offset])
        let green = Double(pixels[offset + 1])
        let blue = Double(pixels[offset + 2])
        let dominance = green - max(red, blue)

        let alpha: Double
        if dominance >= 130 {
            alpha = 0
        } else if dominance <= 28 {
            alpha = 1
        } else {
            alpha = (130 - dominance) / 102
        }

        if alpha <= 0.01 {
            pixels[offset] = 0
            pixels[offset + 1] = 0
            pixels[offset + 2] = 0
            pixels[offset + 3] = 0
            continue
        }

        // Remove the green matte from anti-aliased edge pixels before storing
        // premultiplied RGBA. The solid source background is RGB 0,255,0.
        let foregroundRed = min(255, max(0, red / alpha))
        let foregroundGreen = min(255, max(0,
            (green - (1 - alpha) * 255) / alpha))
        let foregroundBlue = min(255, max(0, blue / alpha))

        pixels[offset] = UInt8((foregroundRed * alpha).rounded())
        pixels[offset + 1] = UInt8((foregroundGreen * alpha).rounded())
        pixels[offset + 2] = UInt8((foregroundBlue * alpha).rounded())
        pixels[offset + 3] = UInt8((255 * alpha).rounded())

        if alpha >= 0.04 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

guard maxX >= minX, maxY >= minY else {
    fatalError("no foreground found")
}

let margin = 16
minX = max(0, minX - margin)
minY = max(0, minY - margin)
maxX = min(width - 1, maxX + margin)
maxY = min(height - 1, maxY + margin)

let trimmedWidth = maxX - minX + 1
let trimmedHeight = maxY - minY + 1
let trimmedBytesPerRow = trimmedWidth * 4
var trimmed = [UInt8](repeating: 0,
    count: trimmedHeight * trimmedBytesPerRow)

for y in 0..<trimmedHeight {
    let sourceStart = (minY + y) * bytesPerRow + minX * 4
    let destinationStart = y * trimmedBytesPerRow
    trimmed.withUnsafeMutableBytes { destination in
        pixels.withUnsafeBytes { source in
            destination.baseAddress!.advanced(by: destinationStart).copyMemory(
                from: source.baseAddress!.advanced(by: sourceStart),
                byteCount: trimmedBytesPerRow)
        }
    }
}

guard let provider = CGDataProvider(data: Data(trimmed) as CFData),
      let outputCG = CGImage(width: trimmedWidth, height: trimmedHeight,
        bitsPerComponent: 8, bitsPerPixel: 32,
        bytesPerRow: trimmedBytesPerRow, space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider, decode: nil, shouldInterpolate: true,
        intent: .defaultIntent) else {
    fatalError("unable to create output image")
}

let outputRep = NSBitmapImageRep(cgImage: outputCG)
guard let png = outputRep.representation(using: .png, properties: [:]) else {
    fatalError("unable to encode PNG")
}
try png.write(to: outputURL)
print("wrote \(trimmedWidth)x\(trimmedHeight) RGBA to \(outputURL.path)")
