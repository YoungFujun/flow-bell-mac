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
let roundedBounds = bounds.insetBy(dx: 24, dy: 24)
let backgroundPath = NSBezierPath(
    roundedRect: roundedBounds,
    xRadius: 230,
    yRadius: 230
)

NSGraphicsContext.current?.imageInterpolation = .high

let deepBlue = NSColor(calibratedRed: 0.285, green: 0.405, blue: 0.560, alpha: 1)
let softBlue = NSColor(calibratedRed: 0.420, green: 0.545, blue: 0.680, alpha: 1)
let sage = NSColor(calibratedRed: 0.380, green: 0.573, blue: 0.455, alpha: 1)
let sageLight = NSColor(calibratedRed: 0.500, green: 0.670, blue: 0.555, alpha: 1)

let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedRed: 1.000, green: 0.982, blue: 0.990, alpha: 1),
    NSColor(calibratedRed: 0.945, green: 0.952, blue: 0.965, alpha: 1)
])
backgroundGradient?.draw(in: backgroundPath, angle: 135)

NSGraphicsContext.saveGraphicsState()
backgroundPath.addClip()
let topGloss = NSBezierPath(ovalIn: NSRect(x: -80, y: 560, width: 1184, height: 520))
NSColor.white.withAlphaComponent(0.24).setFill()
topGloss.fill()
let warmTint = NSBezierPath(ovalIn: NSRect(x: 120, y: 70, width: 800, height: 760))
NSColor(calibratedRed: 0.92, green: 0.72, blue: 0.82, alpha: 0.07).setFill()
warmTint.fill()
NSGraphicsContext.restoreGraphicsState()

let edgeHighlight = NSBezierPath(roundedRect: roundedBounds.insetBy(dx: 6, dy: 6), xRadius: 220, yRadius: 220)
edgeHighlight.lineWidth = 10
NSColor.white.withAlphaComponent(0.34).setStroke()
edgeHighlight.stroke()

let edgeShade = NSBezierPath(roundedRect: roundedBounds.insetBy(dx: 9, dy: 9), xRadius: 218, yRadius: 218)
edgeShade.lineWidth = 8
NSColor.black.withAlphaComponent(0.045).setStroke()
edgeShade.stroke()

let dialShadow = NSBezierPath(ovalIn: NSRect(x: 194, y: 174, width: 636, height: 636))
NSColor.black.withAlphaComponent(0.035).setFill()
dialShadow.fill()

let ringRect = NSRect(x: 236, y: 236, width: 552, height: 552)

let ringShadow = NSBezierPath(ovalIn: ringRect.offsetBy(dx: 0, dy: -10))
ringShadow.lineWidth = 72
NSColor.black.withAlphaComponent(0.08).setStroke()
ringShadow.stroke()

let ringPath = NSBezierPath(ovalIn: ringRect)
ringPath.lineWidth = 56
deepBlue.setStroke()
ringPath.stroke()

let ringHighlight = NSBezierPath(ovalIn: ringRect.insetBy(dx: 2, dy: 2))
ringHighlight.lineWidth = 30
softBlue.withAlphaComponent(0.36).setStroke()
ringHighlight.stroke()

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
sage.setStroke()
progressPath.stroke()

let progressHighlight = NSBezierPath()
progressHighlight.appendArc(
    withCenter: NSPoint(x: ringRect.midX, y: ringRect.midY),
    radius: ringRect.width / 2,
    startAngle: 94,
    endAngle: 130,
    clockwise: false
)
progressHighlight.lineWidth = 22
progressHighlight.lineCapStyle = .round
sageLight.withAlphaComponent(0.46).setStroke()
progressHighlight.stroke()

let arcEndGlow = NSBezierPath(ovalIn: NSRect(x: ringRect.midX - 50, y: ringRect.maxY - 24, width: 100, height: 100))
sage.withAlphaComponent(0.14).setFill()
arcEndGlow.fill()

let knobRect = NSRect(x: ringRect.midX - 38, y: ringRect.maxY - 12, width: 76, height: 112)
let knobPath = NSBezierPath(roundedRect: knobRect, xRadius: 34, yRadius: 34)

let knobShadow = NSBezierPath(roundedRect: knobRect.offsetBy(dx: 0, dy: -8), xRadius: 34, yRadius: 34)
NSColor.black.withAlphaComponent(0.08).setFill()
knobShadow.fill()

deepBlue.setFill()
knobPath.fill()

let knobHighlight = NSBezierPath(ovalIn: NSRect(x: knobRect.midX - 28, y: knobRect.minY + 8, width: 56, height: 40))
NSColor.white.withAlphaComponent(0.18).setFill()
knobHighlight.fill()

let innerCircle = NSBezierPath(ovalIn: NSRect(x: 388, y: 388, width: 248, height: 248))

let innerCircleShadow = NSBezierPath(ovalIn: NSRect(x: 382, y: 376, width: 260, height: 260))
NSColor.black.withAlphaComponent(0.035).setFill()
innerCircleShadow.fill()

let innerCircleGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.980, green: 0.976, blue: 0.980, alpha: 1),
    NSColor(calibratedRed: 0.925, green: 0.932, blue: 0.940, alpha: 1)
])
innerCircleGradient?.draw(in: innerCircle, angle: 45)

let innerCircleHighlight = NSBezierPath(ovalIn: NSRect(x: 432, y: 512, width: 160, height: 58))
NSColor.white.withAlphaComponent(0.18).setFill()
innerCircleHighlight.fill()

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
