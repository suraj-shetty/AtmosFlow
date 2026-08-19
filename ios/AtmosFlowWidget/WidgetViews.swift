import SwiftUI
import WidgetKit

/// The app's body face. The design declares weights the family does not carry
/// (100 and 200 for the big temperatures), and the prototype's own font import
/// only loads 400 upward — so what the design *renders* is regular, and that
/// is what the app's hero uses too.
private enum Face {
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Figtree", size: size).weight(weight)
    }
}

/// The sky, its ambient layers and the condition veil — everything behind the
/// copy, shared by all three sizes.
private struct SkyBackground: View {
    var entry: WidgetEntry
    var scale: CGFloat

    var body: some View {
        ZStack {
            entry.sky.gradient
            AmbientView(
                layers: AmbientLayer.catalog(entry.condition, entry.sky),
                scale: scale
            )
        }
    }
}

/// The design's `iOS Lock Screen · Small` tile: 160pt, 12pt padding.
struct SmallWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.temperature)
                            .font(Face.body(28))
                            .foregroundStyle(entry.sky.ink)
                        Text(entry.caption)
                            .font(Face.body(9))
                            .foregroundStyle(entry.sky.caption)
                            .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                    WeatherGlyph(condition: entry.condition, sky: entry.sky,
                                 size: 30, color: entry.sky.ink)
                }
                Spacer(minLength: 0)
                Footnote(entry: entry, fontSize: 11, glyphSize: 11, gap: 4,
                         color: entry.sky.footnote, glyphColor: entry.sky.footnoteGlyph)
            }
            .padding(12)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .background(SkyBackground(entry: entry, scale: scale))
        }
    }
}

/// The design's `iOS Control Center · Square` tile: 200pt, 16pt padding, its
/// two rows pushed to the edges.
struct SquareWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.temperature)
                            .font(Face.body(42))
                            .foregroundStyle(entry.sky.ink)
                        Text(entry.caption)
                            .font(Face.body(12))
                            .foregroundStyle(entry.sky.captionLarge)
                            .padding(.top, 6)
                    }
                    Spacer(minLength: 0)
                    WeatherGlyph(condition: entry.condition, sky: entry.sky,
                                 size: 40, color: entry.sky.ink)
                }
                Spacer(minLength: 0)
                Footnote(entry: entry, fontSize: 11, glyphSize: 13, gap: 5,
                         color: entry.sky.footnoteLarge,
                         glyphColor: entry.sky.footnoteGlyphLarge)
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .background(SkyBackground(entry: entry, scale: scale))
        }
    }
}

/// The design's `Android Home Screen · 4×2` tile, which is the landscape
/// layout — a header strip over two glass cards.
struct WideWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        GeometryReader { geo in
            // The design draws this one against a 230pt reference rather than
            // the tile's own width, which is what keeps the sun the same size
            // it is on the square tiles.
            let scale: CGFloat = geo.size.width * (230.0 / 280.0)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AtmosFlow · \(entry.sky.label)".uppercased())
                            .font(Face.body(10, .semibold))
                            .tracking(0.06 * 10)
                            .foregroundStyle(entry.sky.caption)
                        Text("\(entry.conditionLabel) · \(entry.place)")
                            .font(Face.body(13))
                            .foregroundStyle(entry.sky.caption)
                            .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                    WeatherGlyph(condition: entry.condition, sky: entry.sky,
                                 size: 32, color: entry.sky.ink)
                }
                HStack(spacing: 12) {
                    Card(sky: entry.sky) {
                        Text(entry.temperature)
                            .font(Face.body(24))
                            .foregroundStyle(entry.sky.ink)
                        Text(entry.clock)
                            .font(Face.body(11))
                            .foregroundStyle(entry.sky.caption)
                            .padding(.top, 2)
                    }
                    Card(sky: entry.sky) {
                        Text("Humidity")
                            .font(Face.body(11))
                            .foregroundStyle(entry.sky.caption)
                        Text(entry.humidity)
                            .font(Face.body(18))
                            .foregroundStyle(entry.sky.ink)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .background(SkyBackground(entry: entry, scale: scale))
        }
    }
}

/// The humidity and the clock along the bottom of the two square tiles.
private struct Footnote: View {
    var entry: WidgetEntry
    var fontSize: CGFloat
    var glyphSize: CGFloat
    var gap: CGFloat
    var color: Color
    var glyphColor: Color

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: gap) {
                DropletGlyph(size: glyphSize, color: glyphColor)
                Text(entry.humidity)
            }
            Spacer(minLength: 0)
            Text(entry.clock)
        }
        .font(Face.body(fontSize))
        .foregroundStyle(color)
    }
}

/// The humidity droplet — the design's own outline, at 2.2 stroke like the
/// condition glyphs.
private struct DropletGlyph: View {
    var size: CGFloat
    var color: Color

    var body: some View {
        Canvas { context, canvasSize in
            let unit = canvasSize.width / 28
            let transform = CGAffineTransform(translationX: 2 * unit, y: 2 * unit)
                .scaledBy(x: unit, y: unit)
            let d = "M12 3.6c0 0 5.2 5.6 5.2 9.1a5.2 5.2 0 11-10.4 0C6.8 9.2 12 3.6 12 3.6z"
            let path = SVGPath.path(d)
            context.stroke(
                Path(path.copy(using: [transform]) ?? path),
                with: .color(color),
                style: StrokeStyle(lineWidth: 2.2 * unit, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
    }
}

/// One of the wide tile's two glass panes.
private struct Card<Content: View>: View {
    var sky: WidgetSky
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(sky.cardFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
