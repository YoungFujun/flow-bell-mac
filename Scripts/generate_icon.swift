import AppKit

let outputPath = CommandLine.arguments.dropFirst().first ?? ""
guard !outputPath.isEmpty else {
    fputs("Usage: swift generate_icon.swift <output.png>\n", stderr)
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)
let backgroundPath = NSBezierPath(
    roundedRect: bounds.insetBy(dx: 24, dy: 24),
    xRadius: 230,
    yRadius: 230
)

NSGraphicsContext.current?.imageInterpolation = .high

let backgroundGradient = NSGradient(
    colors: [
        NSColor(calibratedRed: 0.97, green: 0.84, blue: 0.90, alpha: 1),
        NSColor(calibratedRed: 0.86, green: 0.82, blue: 0.95, alpha: 1)
    ]
)
backgroundGradient?.draw(in: backgroundPath, angle: -22)

let glowPath = NSBezierPath(ovalIn: NSRect(x: 188, y: 188, width: 648, height: 648))
NSColor.white.withAlphaComponent(0.16).setFill()
glowPath.fill()

let ringRect = NSRect(x: 236, y: 236, width: 552, height: 552)
let ringPath = NSBezierPath(ovalIn: ringRect)
ringPath.lineWidth = 56
NSColor.white.withAlphaComponent(0.92).setStroke()
ringPath.stroke()

let progressPath = NSBezierPath()
progressPath.appendArc(
    withCenter: NSPoint(x: ringRect.midX, y: ringRect.midY),
    radius: ringRect.width / 2,
    startAngle: 90,
    endAngle: 134,
    clockwise: false
)
progressPath.lineWidth = 56
progressPath.lineCapStyle = .round
NSColor(calibratedWhite: 0.14, alpha: 0.96).setStroke()
progressPath.stroke()

let knobRect = NSRect(x: ringRect.midX - 38, y: ringRect.maxY - 12, width: 76, height: 112)
let knobPath = NSBezierPath(roundedRect: knobRect, xRadius: 34, yRadius: 34)
NSColor(calibratedWhite: 0.10, alpha: 0.94).setFill()
knobPath.fill()

let innerCircle = NSBezierPath(ovalIn: NSRect(x: 388, y: 388, width: 248, height: 248))
NSColor.white.withAlphaComponent(0.92).setFill()
innerCircle.fill()

let centerDot = NSBezierPath(ovalIn: NSRect(x: 486, y: 486, width: 52, height: 52))
NSColor(calibratedWhite: 0.15, alpha: 0.95).setFill()
centerDot.fill()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render icon PNG.\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Failed to write PNG: \(error)\n", stderr)
    exit(1)
}
