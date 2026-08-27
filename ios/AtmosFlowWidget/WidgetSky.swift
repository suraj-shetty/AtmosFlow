import SwiftUI

extension Color {
    /// The design writes its colours as CSS `rgba`; this keeps them readable
    /// as written rather than converted to 0–1 triples by hand.
    static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static func hex(_ value: UInt32) -> Color {
        rgba(Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF),
             Double(value & 0xFF), 1)
    }
}

/// The seven conditions, matching the app's own `WeatherCondition` names —
/// which is how they arrive through the shared store.
enum WidgetCondition: String, CaseIterable {
    case clear, cloudy, fog, drizzle, rain, snow, storm

    var label: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// Whether this condition's veil drags a bright sky down toward mid-grey.
    ///
    /// Rain's is rgba(52, 58, 80, .58) and the storm's rgba(24, 26, 44, .64):
    /// either takes a morning down to about #7A7F8B before the copy lands on
    /// it. See `WidgetPalette`.
    var darkensSky: Bool { self == .rain || self == .storm }

    /// Whether this condition's veil lifts a dim sky up toward mid-grey — the
    /// same problem from the other side.
    ///
    /// Fog's is rgba(196, 198, 206, .56) and snow's rgba(214, 222, 238, .5),
    /// pale enough to wash a dawn or an evening out from under white copy.
    var lightensSky: Bool { self == .fog || self == .snow }
}

/// The five skies the widget design paints, matching the app's `SkyTime`.
enum WidgetSky: String, CaseIterable {
    case dawn, morning, afternoon, evening, night

    var label: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// How dark the sky is on its own, in three steps rather than two.
    ///
    /// The design's copy rule only needs two — dawn, evening and night take
    /// white, morning and afternoon take ink — but a veil painted over the
    /// sky moves it, and the three behave differently when it does. Dawn and
    /// evening start mid-toned and a pale veil is enough to wash them out
    /// from under white; night starts at #141A30 and no veil in the set gets
    /// it far enough to matter. See `WidgetPalette`.
    enum Depth {
        case bright, dusk, dark
    }

    var depth: Depth {
        switch self {
        case .morning, .afternoon: return .bright
        case .dawn, .evening: return .dusk
        case .night: return .dark
        }
    }

    /// The tile's background, transcribed from the design's CSS gradients.
    var gradient: LinearGradient {
        switch self {
        case .dawn:
            return Self.linear(180, [(.hex(0x3d3a5c), 0), (.hex(0x8a6a86), 0.45), (.hex(0xe8a06a), 1)])
        case .morning:
            return Self.linear(160, [(.hex(0xbcd8ee), 0), (.hex(0xf5e3cc), 1)])
        case .afternoon:
            return Self.linear(160, [(.hex(0x8fc4e8), 0), (.hex(0xdceaf5), 1)])
        case .evening:
            return Self.linear(180, [(.hex(0x6a5a8c), 0), (.hex(0xd2765c), 0.6), (.hex(0xf2b06a), 1)])
        case .night:
            return Self.linear(180, [(.hex(0x141a30), 0), (.hex(0x26304f), 1)])
        }
    }

    /// A CSS gradient angle, where 180° runs top to bottom and the angle turns
    /// clockwise from there, expressed as SwiftUI's two unit points.
    private static func linear(_ degrees: Double,
                               _ stops: [(Color, CGFloat)]) -> LinearGradient {
        let radians = degrees * .pi / 180
        let dx = sin(radians) / 2
        let dy = -cos(radians) / 2
        return LinearGradient(
            gradient: Gradient(stops: stops.map { Gradient.Stop(color: $0.0, location: $0.1) }),
            startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
            endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
        )
    }
}

/// The design's two sets of copy colours — white, or ink — and which set a
/// tile takes.
///
/// The design picks by sky: white on dawn, evening and night, ink on morning
/// and afternoon. Read as a rule about the sky that is what it says, but the
/// copy is not drawn on the sky. It is drawn on the sky *and* the condition's
/// veil, and four of the seven veils move the tile far enough to change the
/// answer — in both directions.
///
/// Measured off the rendered tiles, on the pixels each string actually covers
/// (`tool/brand/contrast.py`), the sky-only rule leaves eight tiles where the
/// other set is the better one, four at each end:
///
///     rain, storm   over morning, afternoon   temperature 4.2 → white 5.7
///     fog, snow     over dawn, evening        temperature 2.4 → ink   6.8
///
/// So depth proposes and the condition can override. Night is the one that
/// never moves: it starts dark enough that even the palest veil leaves white
/// ahead.
struct WidgetPalette {
    /// Whether this tile takes the white set.
    let isDark: Bool

    static func on(_ condition: WidgetCondition, _ sky: WidgetSky) -> WidgetPalette {
        switch sky.depth {
        case .bright: return WidgetPalette(isDark: condition.darkensSky)
        case .dusk: return WidgetPalette(isDark: !condition.lightensSky)
        case .dark: return WidgetPalette(isDark: true)
        }
    }

    /// The temperature, and any other full-strength copy.
    var ink: Color { isDark ? .white : .hex(0x1b1f26) }

    /// "Afternoon · Clear" under the temperature.
    var caption: Color {
        isDark ? .rgba(255, 255, 255, 0.8) : .rgba(40, 46, 56, 0.74)
    }

    /// The same caption on the larger square tile, which lifts it slightly.
    var captionLarge: Color {
        isDark ? .rgba(255, 255, 255, 0.82) : .rgba(40, 46, 56, 0.78)
    }

    // ── The footnote, and the one place these are not the design's numbers ──
    //
    // The design lets the footnote recede a long way: 62% ink under the square
    // tile's humidity and clock, 58% behind its droplet. Measured against the
    // ground it lands on, that put eleven tiles under 3:1 and twenty-three
    // under 4.5:1 — the reading was there, but on a mid-toned tile you had to
    // go looking for it. The alphas below are raised until every one of the
    // thirty-five clears 3:1, which is as far as they can usefully go: the
    // footnote is the smallest copy on the tile and turning it fully opaque
    // would flatten it into the temperature.
    //
    // Alpha is also not the whole answer, and it is worth knowing where it
    // stops. Six tiles cannot reach 4.5:1 on any alpha at all, snow at night
    // topping out at 3.7 with white at full strength, because what limits them
    // is the ground rather than the ink. Closing those means putting something
    // behind the footnote — a scrim, the way dawn and evening already carry
    // one — which is a change to the design rather than to a colour.

    /// The humidity and clock along the bottom.
    var footnote: Color {
        isDark ? .rgba(255, 255, 255, 0.90) : .rgba(40, 46, 56, 0.82)
    }

    var footnoteLarge: Color {
        isDark ? .rgba(255, 255, 255, 0.90) : .rgba(40, 46, 56, 0.80)
    }

    /// The small droplet beside the humidity. Kept just under the copy it sits
    /// with, as the design has it — a 2.2pt stroke reads lighter than type at
    /// the same alpha, so the gap is smaller than the numbers suggest.
    var footnoteGlyph: Color {
        isDark ? .rgba(255, 255, 255, 0.84) : .rgba(40, 46, 56, 0.76)
    }

    var footnoteGlyphLarge: Color {
        isDark ? .rgba(255, 255, 255, 0.84) : .rgba(40, 46, 56, 0.74)
    }

    /// The two glass cards on the wide tile.
    var cardFill: Color {
        isDark ? .rgba(255, 255, 255, 0.14) : .rgba(255, 255, 255, 0.42)
    }
}
