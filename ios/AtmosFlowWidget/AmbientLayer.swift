import SwiftUI

/// The design's ambient sky, ported from the CSS the prototype draws it in.
///
/// Every tile in `AtmosFlow Widgets.dc.html` is the same recipe: a
/// time-of-day gradient, an optional dusk wash, a condition veil, and a
/// handful of absolutely-positioned shapes. The prototype writes those shapes
/// as inline CSS, so this is a small, deliberate subset of the CSS box model —
/// enough to reproduce them exactly, and nothing more.
///
/// Lengths come in three flavours because the design uses all three: a
/// fraction of the tile's reference size (most geometry, so a shape keeps its
/// proportions across the three widget sizes), a percentage of the box (used
/// for horizontal scatter), and a literal point value (hairlines — a rain
/// streak is 2pt wide at every size, exactly as in the design).
enum Length: Equatable {
    case frac(CGFloat)
    case pct(CGFloat)
    case pt(CGFloat)

    func resolve(against extent: CGFloat, scale: CGFloat) -> CGFloat {
        switch self {
        case .frac(let f): return f * scale
        case .pct(let p): return p * extent
        case .pt(let p): return p
        }
    }
}

/// The CSS box: any of the six offsets, resolved the way absolute positioning
/// resolves them — `left` and `width` win, `right` fills in when `left` is
/// absent, and the margins recentre a shape pinned to 50%.
struct Box: Equatable {
    var top: Length?
    var left: Length?
    var right: Length?
    var bottom: Length?
    var width: Length?
    var height: Length?
    var marginTop: Length?
    var marginLeft: Length?

    func rect(in size: CGSize, scale: CGFloat) -> CGRect {
        let w = width?.resolve(against: size.width, scale: scale) ?? 0
        let h = height?.resolve(against: size.height, scale: scale) ?? 0

        var x: CGFloat = 0
        if let left { x = left.resolve(against: size.width, scale: scale) }
        else if let right { x = size.width - right.resolve(against: size.width, scale: scale) - w }
        if let marginLeft { x += marginLeft.resolve(against: size.width, scale: scale) }

        var y: CGFloat = 0
        if let top { y = top.resolve(against: size.height, scale: scale) }
        else if let bottom { y = size.height - bottom.resolve(against: size.height, scale: scale) - h }
        if let marginTop { y += marginTop.resolve(against: size.height, scale: scale) }

        return CGRect(x: x, y: y, width: w, height: h)
    }
}

/// One of the design's keyframe animations, with this shape's own timing.
///
/// WidgetKit renders a still frame — a widget has no run loop to animate on —
/// so this is not played. It is sampled: `phase` gives the point in the cycle
/// a shape sits at, and because every drop and every star carries a different
/// duration and delay, sampling them all at one instant scatters them exactly
/// the way watching the prototype for a moment would.
struct Anim: Equatable {
    var name: String
    var duration: Double
    var delay: Double

    /// Where in its cycle this shape is at `t` seconds.
    func phase(at t: Double) -> Double {
        guard duration > 0 else { return 0 }
        let p = (t - delay).truncatingRemainder(dividingBy: duration) / duration
        return p < 0 ? p + 1 : p
    }
}

struct Glow: Equatable {
    var blur: Length
    var spread: Length
    var color: Color
}

struct MistBlob: Equatable {
    var width: CGFloat
    var height: CGFloat
    var x: CGFloat
    var y: CGFloat
    var color: Color
}

struct Stop: Equatable {
    var color: Color
    var at: CGFloat?
}

enum AmbientLayer: Equatable {
    /// A full-bleed wash — the condition veil, and the storm's lightning.
    case veil(Color, anim: Anim? = nil)
    /// The dusk gradient across the bottom of a dawn or evening sky.
    case duskVeil(height: CGFloat, color: Color)
    case radial(Box, center: UnitPoint, stops: [Stop], anim: Anim?)
    case ring(Box, strokeWidth: CGFloat, color: Color, anim: Anim?)
    case fill(Box, round: Bool, color: Color, glow: Glow?, anim: Anim?)
    case mist([MistBlob], anim: Anim?)
}
