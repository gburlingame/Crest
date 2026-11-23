// Draws the picture behind the window Finder opens on Thundermist's disk image:
// a dusk sky that matches the app icon's afterglow, mist along the bottom, a
// hint at the top, and an arrow from the app to Applications. The band where
// Finder writes the icons' names stays a middle tone, so the black names of
// light mode and the white names of dark mode both read on it.
//
// Scripts/thundermist-disk-image.py runs it with the window's layout:
// swift thundermist-disk-image-background.swift <output.tiff> <width> <height>
//   <app x> <app y> <Applications x> <Applications y> <product name>
// Points are measured from the window's top left, as Finder places icons. The
// TIFF holds the picture at 1x and 2x, as Finder wants for Retina screens.
import AppKit

let arguments = CommandLine.arguments
let numbers = arguments.count == 9 ? arguments[2...7].compactMap { Double($0) } : []
guard numbers.count == 6 else {
    FileHandle.standardError.write(
        Data(
            "Usage: thundermist-disk-image-background.swift <output.tiff> <width> <height> <app x> <app y> <Applications x> <Applications y> <product name>\n"
                .utf8))
    exit(64)
}
let output = URL(fileURLWithPath: arguments[1])
let width = CGFloat(numbers[0])
let height = CGFloat(numbers[1])
let application = CGPoint(x: numbers[2], y: numbers[3])
let applications = CGPoint(x: numbers[4], y: numbers[5])
let productName = arguments[8]

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

/// The drawing's point for one measured from the window's top left.
func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: height - y) }

func glow(_ center: CGPoint, radius: CGFloat, _ tint: NSColor) {
    NSGradient(colors: [tint, tint.withAlphaComponent(0)])!
        .draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
}

func drawSky() {
    // Deep dusk at the top, the middle tone under the names, lighter mist below.
    NSGradient(
        colorsAndLocations: (color(0x353b66), 0), (color(0x4f5885), 0.4), (color(0x6a7699), 0.7),
        (color(0x7f88aa), 1))!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    // The last of the sun, high on the right, as in the icon.
    glow(point(width - 80, -30), radius: 300, color(0xe0794a, 0.32))
    glow(point(width - 80, -30), radius: 120, color(0xffd08a, 0.22))
    // Mist rising along the bottom.
    for (x, y, radius, alpha) in [
        (0.09, 1.05, 170.0, 0.16), (0.39, 1.1, 190, 0.13), (0.67, 1.075, 170, 0.14), (0.97, 1.04, 180, 0.16),
    ] {
        glow(point(width * x, height * y), radius: radius, NSColor(white: 1, alpha: alpha))
    }
}

func drawArrow() {
    // A shallow arc from beside the app to beside Applications.
    let start = point(application.x + 86, application.y)
    let end = point(applications.x - 86, applications.y)
    let rise: CGFloat = 22
    let reach: CGFloat = 40
    let arc = NSBezierPath()
    arc.move(to: start)
    arc.curve(
        to: end, controlPoint1: CGPoint(x: start.x + reach, y: start.y + rise),
        controlPoint2: CGPoint(x: end.x - reach, y: end.y + rise))
    // The head's two strokes sit evenly about the way the arc arrives.
    let back = atan2(rise, -reach)
    let spread: CGFloat = .pi / 5.5
    let length: CGFloat = 18
    let head = NSBezierPath()
    head.move(to: CGPoint(x: end.x + length * cos(back + spread), y: end.y + length * sin(back + spread)))
    head.line(to: end)
    head.line(to: CGPoint(x: end.x + length * cos(back - spread), y: end.y + length * sin(back - spread)))

    let shadow = NSShadow()
    shadow.shadowColor = color(0x1b1d3a, 0.35)
    shadow.shadowBlurRadius = 6
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor(white: 1, alpha: 0.9).setStroke()
    for path in [arc, head] {
        path.lineWidth = 5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
}

func drawHint() {
    // On the dark sky at the top.
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    NSAttributedString(
        string: "Drag \(productName) to Applications",
        attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: NSColor(white: 1, alpha: 0.88),
            .paragraphStyle: style,
        ]
    )
    .draw(in: NSRect(x: 0, y: height - 70, width: width, height: 22))
}

func render(scale: CGFloat) -> NSBitmapImageRep {
    let image = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
        bitsPerPixel: 0)!
    image.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: image)
    drawSky()
    drawArrow()
    drawHint()
    NSGraphicsContext.restoreGraphicsState()
    return image
}

guard
    let picture = NSBitmapImageRep.tiffRepresentationOfImageReps(
        in: [render(scale: 1), render(scale: 2)], using: .lzw, factor: 0)
else {
    FileHandle.standardError.write(Data("Couldn't draw the disk image's background.\n".utf8))
    exit(1)
}
try picture.write(to: output)
