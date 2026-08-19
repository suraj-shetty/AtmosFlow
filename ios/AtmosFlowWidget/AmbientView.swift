import SwiftUI

/// Draws an ambient sky at one instant.
///
/// A widget has no run loop, so nothing here moves — WidgetKit asks for a
/// picture and shows it until the next timeline entry. Rather than drop the
/// motion and leave every rain streak parked off the top edge where its
/// keyframe starts, the whole scene is *sampled*: each shape is placed where
/// its own animation has it at `Ambient.instant`. Because the design gives
/// every drop and every star its own duration and delay, one instant is all it
/// takes to scatter them the way watching the prototype would.
struct AmbientView: View {
    var layers: [AmbientLayer]

    /// The reference size the design's fractions are written against — the
    /// prototype uses 160 for the small tile, 200 for the square and 230 for
    /// the wide one, all with the same fractions.
    var scale: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Pins the stack to the tile before anything else lays out.
                // Without it the stack takes the size of its tallest child —
                // and since every shape is placed by offsetting from the
                // stack's own top-left corner, a stack that is shorter than
                // the tile drags the whole sky down with it.
                Color.clear
                    .frame(width: geo.size.width, height: geo.size.height)
                ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                    shape(layer, in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func shape(_ layer: AmbientLayer, in size: CGSize) -> some View {
        switch layer {
        case .veil(let color, let anim):
            Rectangle()
                .fill(color)
                .frame(width: size.width, height: size.height)
                .opacity(anim.map { Ambient.opacity(for: $0) } ?? 1)

        case .duskVeil(let height, let color):
            LinearGradient(
                colors: [color.opacity(0), color],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: size.width, height: size.height * height)
            .offset(y: size.height * (1 - height))

        case .radial(let box, let center, let stops, let anim):
            let rect = box.rect(in: size, scale: scale)
            let t = anim.map { Ambient.transform(for: $0) } ?? .identity
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: Ambient.gradientStops(stops)),
                        center: center,
                        startRadius: 0,
                        // CSS sizes a `radial-gradient(circle, …)` to its
                        // farthest corner, so the stops run out to the corner
                        // of the box, not to the edge of the disc. Measured
                        // from the edge instead, every glow in the design
                        // comes out a third too small.
                        endRadius: hypot(rect.width, rect.height) / 2
                    )
                )
                .frame(width: rect.width, height: rect.height)
                .scaleEffect(t.scale)
                .opacity(t.opacity)
                .offset(x: rect.minX + t.dx, y: rect.minY + t.dy)

        case .ring(let box, let strokeWidth, let color, let anim):
            let rect = box.rect(in: size, scale: scale)
            let t = anim.map { Ambient.transform(for: $0) } ?? .identity
            Circle()
                .strokeBorder(color, lineWidth: strokeWidth)
                .frame(width: rect.width, height: rect.height)
                .rotationEffect(.degrees(t.rotation))
                .offset(x: rect.minX, y: rect.minY)

        case .fill(let box, let round, let color, let glow, let anim):
            let rect = box.rect(in: size, scale: scale)
            let t = anim.map { Ambient.transform(for: $0) } ?? .identity
            Group {
                if round {
                    Circle().fill(color)
                } else {
                    Rectangle().fill(color)
                }
            }
            .frame(width: rect.width, height: rect.height)
            .modifier(GlowModifier(glow: glow, scale: scale))
            .opacity(t.opacity)
            .offset(x: rect.minX + t.dx, y: rect.minY + t.dy)

        case .mist(let blobs, let anim):
            let t = anim.map { Ambient.transform(for: $0) } ?? .identity
            ZStack(alignment: .topLeading) {
                ForEach(Array(blobs.enumerated()), id: \.offset) { _, blob in
                    let w = blob.width * scale
                    let h = blob.height * scale
                    let side = max(w, h)
                    // An `ellipse Wpx Hpx` gradient reaches transparent at the
                    // ellipse's own edge on both axes. SwiftUI's radial
                    // gradient is always round, so it is drawn round at the
                    // larger axis and squashed to the other.
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [blob.color, blob.color.opacity(0)]),
                                center: .center, startRadius: 0, endRadius: side / 2
                            )
                        )
                        .frame(width: side, height: side)
                        .scaleEffect(x: w / side, y: h / side)
                        .offset(x: size.width * blob.x - side / 2,
                                y: size.height * blob.y - side / 2)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .scaleEffect(t.scale)
            .opacity(t.opacity)
            .offset(x: t.dx, y: t.dy)
        }
    }
}

/// A `box-shadow` used as a glow — the moon's halo and a snowflake's bloom.
private struct GlowModifier: ViewModifier {
    var glow: Glow?
    var scale: CGFloat

    func body(content: Content) -> some View {
        if let glow {
            content.shadow(
                color: glow.color,
                radius: glow.blur.resolve(against: scale, scale: scale) / 2
            )
        } else {
            content
        }
    }
}
