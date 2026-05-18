import AppKit
import CoreGraphics
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/branding/app_icon_master.rgba.png"
let canvasSize = 1024
let size = CGSize(width: canvasSize, height: canvasSize)

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> CGColor {
  let red = CGFloat((hex >> 16) & 0xFF) / 255.0
  let green = CGFloat((hex >> 8) & 0xFF) / 255.0
  let blue = CGFloat(hex & 0xFF) / 255.0
  return NSColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
}

func radians(_ degrees: CGFloat) -> CGFloat {
  degrees * .pi / 180.0
}

func makeGradient(colors: [CGColor], locations: [CGFloat]) -> CGGradient {
  let space = CGColorSpaceCreateDeviceRGB()
  return CGGradient(
    colorsSpace: space,
    colors: colors as CFArray,
    locations: locations
  )!
}

func strokeArc(
  context: CGContext,
  center: CGPoint,
  radius: CGFloat,
  start: CGFloat,
  end: CGFloat,
  width: CGFloat,
  color: CGColor
) {
  context.saveGState()
  context.setStrokeColor(color)
  context.setLineWidth(width)
  context.setLineCap(.round)
  context.addArc(
    center: center,
    radius: radius,
    startAngle: radians(start),
    endAngle: radians(end),
    clockwise: false
  )
  context.strokePath()
  context.restoreGState()
}

func strokeCheck(
  context: CGContext,
  points: [CGPoint],
  width: CGFloat,
  color: CGColor
) {
  guard let first = points.first else { return }
  context.saveGState()
  context.setStrokeColor(color)
  context.setLineWidth(width)
  context.setLineCap(.round)
  context.setLineJoin(.round)
  context.move(to: first)
  for point in points.dropFirst() {
    context.addLine(to: point)
  }
  context.strokePath()
  context.restoreGState()
}

guard let rep = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: canvasSize,
  pixelsHigh: canvasSize,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Failed to create bitmap")
}

guard let context = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else {
  fatalError("Failed to create graphics context")
}

context.setAllowsAntialiasing(true)
context.interpolationQuality = .high

let rect = CGRect(origin: .zero, size: size)

let backgroundGradient = makeGradient(
  colors: [
    color(0x2DA6FF),
    color(0x2456FF),
    color(0x3B1DFF),
  ],
  locations: [0.0, 0.52, 1.0]
)

context.setFillColor(color(0x2C63FF))
context.fill(rect)
context.drawLinearGradient(
  backgroundGradient,
  start: CGPoint(x: 110, y: 980),
  end: CGPoint(x: 940, y: 60),
  options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

let vignette = makeGradient(
  colors: [
    color(0x000000, alpha: 0.0),
    color(0x000000, alpha: 0.18),
  ],
  locations: [0.58, 1.0]
)

context.drawRadialGradient(
  vignette,
  startCenter: CGPoint(x: 512, y: 520),
  startRadius: 80,
  endCenter: CGPoint(x: 512, y: 520),
  endRadius: 720,
  options: []
)

let center = CGPoint(x: 520, y: 540)
let ringRadius: CGFloat = 295
let ringWidth: CGFloat = 92

context.saveGState()
context.setShadow(
  offset: CGSize(width: 0, height: -18),
  blur: 28,
  color: color(0x112772, alpha: 0.35)
)
strokeArc(
  context: context,
  center: center,
  radius: ringRadius,
  start: 118,
  end: 228,
  width: ringWidth,
  color: color(0x74D9FF)
)
strokeArc(
  context: context,
  center: center,
  radius: ringRadius,
  start: 22,
  end: 82,
  width: ringWidth,
  color: color(0xFFFFFF, alpha: 0.96)
)
strokeArc(
  context: context,
  center: center,
  radius: ringRadius,
  start: 238,
  end: 330,
  width: ringWidth,
  color: color(0xC9CFFF, alpha: 0.95)
)
context.restoreGState()

context.saveGState()
context.setShadow(
  offset: CGSize(width: 0, height: -16),
  blur: 24,
  color: color(0x0E1F63, alpha: 0.30)
)
strokeCheck(
  context: context,
  points: [
    CGPoint(x: 368, y: 498),
    CGPoint(x: 486, y: 380),
    CGPoint(x: 684, y: 580),
  ],
  width: 86,
  color: color(0xFFFFFF)
)
context.restoreGState()

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
  at: outputURL.deletingLastPathComponent(),
  withIntermediateDirectories: true
)

guard let data = rep.representation(using: .png, properties: [:]) else {
  fatalError("Failed to encode PNG")
}

try data.write(to: outputURL)
