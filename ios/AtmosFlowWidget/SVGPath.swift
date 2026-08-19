import CoreGraphics
import Foundation

/// A small SVG path reader — enough for the design's icon set and no more.
///
/// The condition glyphs come straight from the design as `d` attributes, arcs
/// and all. Retracing them as Core Graphics curves by hand would be a
/// transcription with no way to check itself, so they stay in the form the
/// design wrote them and are read here. Supports `M m L l H h V v A a Z z`,
/// which is every command the seven icons use.
enum SVGPath {
    static func path(_ d: String) -> CGPath {
        let path = CGMutablePath()
        var cursor = CGPoint.zero
        var start = CGPoint.zero
        var scanner = Scanner(d)

        while let command = scanner.command() {
            let relative = command.isLowercase
            switch Character(command.uppercased()) {
            case "M":
                repeat {
                    let p = scanner.point(relativeTo: relative ? cursor : .zero)
                    path.move(to: p)
                    cursor = p; start = p
                } while scanner.peekIsNumber()

            case "L":
                repeat {
                    let p = scanner.point(relativeTo: relative ? cursor : .zero)
                    path.addLine(to: p)
                    cursor = p
                } while scanner.peekIsNumber()

            case "H":
                repeat {
                    let x = scanner.number() + (relative ? cursor.x : 0)
                    cursor = CGPoint(x: x, y: cursor.y)
                    path.addLine(to: cursor)
                } while scanner.peekIsNumber()

            case "V":
                repeat {
                    let y = scanner.number() + (relative ? cursor.y : 0)
                    cursor = CGPoint(x: cursor.x, y: y)
                    path.addLine(to: cursor)
                } while scanner.peekIsNumber()

            case "A":
                repeat {
                    let rx = scanner.number(), ry = scanner.number()
                    let rotation = scanner.number()
                    // Flags are single digits and the spec lets them run
                    // together — "0 11-10.4 0" is rotation 0, both flags set.
                    let largeArc = scanner.flag()
                    let sweep = scanner.flag()
                    let end = scanner.point(relativeTo: relative ? cursor : .zero)
                    addArc(to: path, from: cursor, to: end, rx: rx, ry: ry,
                           rotation: rotation, largeArc: largeArc, sweep: sweep)
                    cursor = end
                } while scanner.peekIsNumber()

            case "C":
                repeat {
                    let c1 = scanner.point(relativeTo: relative ? cursor : .zero)
                    let c2 = scanner.point(relativeTo: relative ? cursor : .zero)
                    let end = scanner.point(relativeTo: relative ? cursor : .zero)
                    path.addCurve(to: end, control1: c1, control2: c2)
                    cursor = end
                } while scanner.peekIsNumber()

            case "Z":
                path.closeSubpath()
                cursor = start

            default:
                return path  // An unsupported command: stop rather than guess.
            }
        }
        return path
    }

    /// The SVG endpoint-parameterised arc, converted to a centre and two
    /// angles — the conversion given in the SVG spec's implementation notes.
    private static func addArc(to path: CGMutablePath, from p0: CGPoint, to p1: CGPoint,
                               rx: CGFloat, ry: CGFloat, rotation: CGFloat,
                               largeArc: Bool, sweep: Bool) {
        guard rx != 0, ry != 0 else {
            path.addLine(to: p1); return
        }
        var rx = abs(rx), ry = abs(ry)
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)

        let dx2 = (p0.x - p1.x) / 2, dy2 = (p0.y - p1.y) / 2
        let x1 = cosPhi * dx2 + sinPhi * dy2
        let y1 = -sinPhi * dx2 + cosPhi * dy2

        // Scale the radii up if they are too small to span the two points.
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 {
            rx *= sqrt(lambda); ry *= sqrt(lambda)
        }

        let sign: CGFloat = largeArc == sweep ? -1 : 1
        let numerator = max(0, rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1)
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coefficient = denominator == 0 ? 0 : sign * sqrt(numerator / denominator)

        let cx1 = coefficient * rx * y1 / ry
        let cy1 = -coefficient * ry * x1 / rx
        let cx = cosPhi * cx1 - sinPhi * cy1 + (p0.x + p1.x) / 2
        let cy = sinPhi * cx1 + cosPhi * cy1 + (p0.y + p1.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
            var a = acos(min(1, max(-1, len == 0 ? 1 : dot / len)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }

        let startAngle = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry,
                          (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        // Core Graphics has no rotated-ellipse arc, so the arc is drawn on the
        // unit circle and the transform carries the radii and rotation.
        let transform = CGAffineTransform(translationX: cx, y: cy)
            .rotated(by: phi)
            .scaledBy(x: rx, y: ry)
        path.addRelativeArc(center: .zero, radius: 1, startAngle: startAngle,
                            delta: delta, transform: transform)
    }

    /// A cursor over the `d` string.
    private struct Scanner {
        private let chars: [Character]
        private var index = 0

        init(_ d: String) { chars = Array(d) }

        mutating func skipSeparators() {
            while index < chars.count,
                  chars[index] == " " || chars[index] == "," || chars[index] == "\n" {
                index += 1
            }
        }

        mutating func command() -> Character? {
            skipSeparators()
            guard index < chars.count, chars[index].isLetter else { return nil }
            defer { index += 1 }
            return chars[index]
        }

        mutating func peekIsNumber() -> Bool {
            skipSeparators()
            guard index < chars.count else { return false }
            return chars[index].isNumber || chars[index] == "-" || chars[index] == "."
        }

        mutating func number() -> CGFloat {
            skipSeparators()
            var text = ""
            if index < chars.count, chars[index] == "-" || chars[index] == "+" {
                text.append(chars[index]); index += 1
            }
            while index < chars.count, chars[index].isNumber || chars[index] == "." {
                text.append(chars[index]); index += 1
            }
            return CGFloat(Double(text) ?? 0)
        }

        mutating func flag() -> Bool {
            skipSeparators()
            guard index < chars.count else { return false }
            defer { index += 1 }
            return chars[index] == "1"
        }

        mutating func point(relativeTo origin: CGPoint) -> CGPoint {
            let x = number(), y = number()
            return CGPoint(x: origin.x + x, y: origin.y + y)
        }
    }
}
