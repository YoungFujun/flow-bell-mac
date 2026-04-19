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

// 微妙的渐变背景（不是纯白，增加质感）
let backgroundGradient = NSGradient(
    colors: [
        NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.98, alpha: 1), // 几乎纯白
        NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.96, alpha: 1)  // 微微偏蓝灰
    ]
)
backgroundGradient?.draw(in: backgroundPath, angle: 135)

// 边缘微妙的内阴影（增加深度感）
let innerShadowPath = NSBezierPath(roundedRect: roundedBounds, xRadius: 230, yRadius: 230)
innerShadowPath.lineWidth = 8
NSColor.black.withAlphaComponent(0.03).setStroke()
innerShadowPath.stroke()

// 外部光晕效果
let outerGlowPath = NSBezierPath(ovalIn: NSRect(x: 180, y: 180, width: 664, height: 664))
let outerGlowGradient = NSGradient(
    colors: [
        NSColor.black.withAlphaComponent(0.04),
        NSColor.black.withAlphaComponent(0.0)
    ]
)
outerGlowGradient?.draw(in: outerGlowPath, angle: 0)

// 内部微妙的反光效果
let innerHighlightPath = NSBezierPath(ovalIn: NSRect(x: 280, y: 280, width: 464, height: 464))
let innerHighlightGradient = NSGradient(
    colors: [
        NSColor.white.withAlphaComponent(0.0),
        NSColor.white.withAlphaComponent(0.08)
    ]
)
innerHighlightGradient?.draw(in: innerHighlightPath, angle: -45)

let ringRect = NSRect(x: 236, y: 236, width: 552, height: 552)
let ringPath = NSBezierPath(ovalIn: ringRect)
ringPath.lineWidth = 56
// 浅蓝色圆环
NSColor(calibratedRed: 0.25, green: 0.40, blue: 0.60, alpha: 1).setStroke() // 更浅的蓝色
ringPath.stroke()

// 进度弧 - sage 绿 accent 色
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
NSColor(calibratedRed: 0.380, green: 0.573, blue: 0.455, alpha: 1).setStroke() // sage 绿
progressPath.stroke()

// 进度弧末端微光
let arcEndGlow = NSBezierPath(ovalIn: NSRect(x: ringRect.midX - 46, y: ringRect.maxY - 22, width: 92, height: 92))
NSColor(calibratedRed: 0.380, green: 0.573, blue: 0.455, alpha: 0.15).setFill()
arcEndGlow.fill()

let knobRect = NSRect(x: ringRect.midX - 38, y: ringRect.maxY - 12, width: 76, height: 112)
let knobPath = NSBezierPath(roundedRect: knobRect, xRadius: 34, yRadius: 34)
// 浅蓝色铃舌
NSColor(calibratedRed: 0.25, green: 0.40, blue: 0.60, alpha: 1).setFill() // 更浅的蓝色
knobPath.fill()

// 铃舌顶部微光
let knobHighlight = NSBezierPath(ovalIn: NSRect(x: knobRect.midX - 28, y: knobRect.minY + 8, width: 56, height: 40))
NSColor.white.withAlphaComponent(0.12).setFill()
knobHighlight.fill()

let innerCircle = NSBezierPath(ovalIn: NSRect(x: 388, y: 388, width: 248, height: 248))
// 内圆渐变（微微偏白灰）
let innerCircleGradient = NSGradient(
    colors: [
        NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.93, green: 0.93, blue: 0.95, alpha: 1)
    ]
)
innerCircleGradient?.draw(in: innerCircle, angle: 45)

let centerDot = NSBezierPath(ovalIn: NSRect(x: 486, y: 486, width: 52, height: 52))
// sage 绿中心点
NSColor(calibratedRed: 0.380, green: 0.573, blue: 0.455, alpha: 1).setFill()
centerDot.fill()

// 中心点微光
let centerDotGlow = NSBezierPath(ovalIn: NSRect(x: 476, y: 476, width: 72, height: 72))
NSColor(calibratedRed: 0.380, green: 0.573, blue: 0.455, alpha: 0.18).setFill()
centerDotGlow.fill()

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
