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

    /// Whether this condition's veil is heavy enough to darken a bright sky
    /// past the point where ink still reads against it.
    ///
    /// Every condition but clear lays a veil over the sky, and most are pale
    /// or thin enough to leave a morning a morning. Rain's is
    /// rgba(52, 58, 80, .58) and the storm's rgba(24, 26, 44, .64) — those two
    /// take a bright sky down to around #7A7F8B. See `WidgetPalette`.
    var darkensSky: Bool { self == .rain || self == .storm }
}

/// The five skies the widget design paints, matching the app's `SkyTime`.
enum WidgetSky: String, CaseIterable {
    case dawn, morning, afternoon, evening, night

    var label: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// Whether the sky itself is dark: the design paints dawn, evening and
    /// night dark, and morning and afternoon bright. Whether the *tile* ends
    /// up dark is `WidgetPalette`'s question, because the condition paints
    /// over this.
    var isDark: Bool { self != .morning && self != .afternoon }

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
/// and afternoon. That holds wherever the sky is the last thing painted, and
/// for five of the seven conditions it is close enough. It is not the whole
/// story. The condition veil sits over the sky and under the copy, and rain's
/// and the storm's are heavy enough that a bright morning arrives at the copy
/// as dark as an evening. Ink on those measured 4.1:1 for the temperature and
/// 2.3:1 for the caption — the four tiles where the reading disappeared.
///
/// So the sky proposes and the condition can override: anything
/// `WidgetCondition.darkensSky` takes the white set at every hour.
struct WidgetPalette {
    /// Whether this tile takes the white set.
    let isDark: Bool

    static func on(_ condition: WidgetCondition, _ sky: WidgetSky) -> WidgetPalette {
        WidgetPalette(isDark: sky.isDark || condition.darkensSky)
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

    /// The humidity and clock along the bottom.
    var footnote: Color {
        isDark ? .rgba(255, 255, 255, 0.86) : .rgba(40, 46, 56, 0.72)
    }

    var footnoteLarge: Color {
        isDark ? .rgba(255, 255, 255, 0.86) : .rgba(40, 46, 56, 0.62)
    }

    /// The small droplet beside the humidity.
    var footnoteGlyph: Color {
        isDark ? .rgba(255, 255, 255, 0.62) : .rgba(40, 46, 56, 0.58)
    }

    var footnoteGlyphLarge: Color {
        isDark ? .rgba(255, 255, 255, 0.68) : .rgba(40, 46, 56, 0.68)
    }

    /// The two glass cards on the wide tile.
    var cardFill: Color {
        isDark ? .rgba(255, 255, 255, 0.14) : .rgba(255, 255, 255, 0.42)
    }
}
