import SwiftUI

/// The seven condition icons, as the design draws them.
///
/// Each is the design's own SVG: strokes at 2.2 with round caps and joins,
/// over a 24-unit grid inside a 28-unit box (the prototype's `viewBox
/// "-2 -2 28 28"`, which leaves room for the stroke to overhang).
struct WeatherGlyph: View {
    var condition: WidgetCondition
    var sky: WidgetSky
    var size: CGFloat
    var color: Color

    /// The one glyph that changes with the sky: a clear night is a moon.
    private var isMoon: Bool { condition == .clear && sky == .night }

    var body: some View {
        Canvas { context, canvasSize in
            let unit = canvasSize.width / 28
            let transform = CGAffineTransform(translationX: 2 * unit, y: 2 * unit)
                .scaledBy(x: unit, y: unit)

            for element in elements {
                let path = Path(element.path.copy(using: [transform]) ?? element.path)
                if element.filled {
                    context.fill(path, with: .color(color))
                } else {
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: 2.2 * unit, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .frame(width: size, height: size)
    }

    private struct Element {
        var path: CGPath
        var filled: Bool
    }

    private var elements: [Element] {
        switch condition {
        case .clear where isMoon:
            return [
                Element(path: SVGPath.path("M20 14.2A8 8 0 119.8 4a6.4 6.4 0 0010.2 10.2z"), filled: true),
                Element(path: line(19, 3, 19, 6), filled: false),
                Element(path: line(17.5, 4.5, 20.5, 4.5), filled: false),
            ]

        case .clear:
            // A four-point star: a filled core and eight rays, at the same
            // radii the design's own `<line>`s give.
            var rays: [Element] = [Element(path: circle(12, 12, 4), filled: true)]
            for (x1, y1, x2, y2) in [
                (18.0, 12.0, 21.0, 12.0), (16.24, 16.24, 18.36, 18.36),
                (12.0, 18.0, 12.0, 21.0), (7.76, 16.24, 5.64, 18.36),
                (6.0, 12.0, 3.0, 12.0), (7.76, 7.76, 5.64, 5.64),
                (12.0, 6.0, 12.0, 3.0), (16.24, 7.76, 18.36, 5.64),
            ] {
                rays.append(Element(path: line(x1, y1, x2, y2), filled: false))
            }
            return rays

        case .cloudy:
            return [Element(path: SVGPath.path(cloud(baseline: 19)), filled: false)]

        case .fog:
            return [
                Element(path: line(4, 9, 20, 9), filled: false),
                Element(path: line(4, 13, 20, 13), filled: false),
                Element(path: line(4, 17, 16, 17), filled: false),
            ]

        case .drizzle:
            return [Element(path: SVGPath.path(cloud(baseline: 12)), filled: false)]
                + [(9.0, 16.0, 8.5, 18.0), (13.0, 16.0, 12.5, 18.0), (17.0, 16.0, 16.5, 18.0)]
                    .map { Element(path: line($0.0, $0.1, $0.2, $0.3), filled: false) }

        case .rain:
            return [Element(path: SVGPath.path(cloud(baseline: 15)), filled: false)]
                + [(8.0, 18.0, 7.0, 21.0), (12.0, 18.0, 11.0, 21.0), (16.0, 18.0, 15.0, 21.0)]
                    .map { Element(path: line($0.0, $0.1, $0.2, $0.3), filled: false) }

        case .snow:
            return [Element(path: SVGPath.path(cloud(baseline: 15)), filled: false)]
                + [(8.0, 19.0), (12.0, 20.0), (16.0, 19.0)]
                    .map { Element(path: circle($0.0, $0.1, 0.9), filled: true) }

        case .storm:
            return [
                Element(path: SVGPath.path(cloud(baseline: 14)), filled: false),
                Element(path: SVGPath.path("M13 13l-3.5 5.5H12l-1.5 4L15 16h-2.5z"), filled: true),
            ]
        }
    }

    /// The cloud body. Across the whole icon set the design changes exactly
    /// one thing about it — how far down its flat underside sits — sliding it
    /// up to make room for the drizzle, the rain, the snow and the bolt.
    private func cloud(baseline: Int) -> String {
        "M6.5 \(baseline)a4.5 4.5 0 01-.4-8.98 5.5 5.5 0 0110.7-2A4.5 4.5 0 0117 \(baseline)H6.5z"
    }

    private func line(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        return path
    }

    private func circle(_ x: Double, _ y: Double, _ r: Double) -> CGPath {
        CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2),
               transform: nil)
    }
}
