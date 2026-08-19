import SwiftUI

/// The design's keyframes, evaluated rather than played.
enum Ambient {
    /// The instant every widget is drawn at, in seconds since the scene began.
    ///
    /// Not arbitrary: 2.944s is 92% of the storm's 3.2s `rainFallFlash` cycle,
    /// the one frame in that cycle where the lightning is at full strength. A
    /// widget shows a single picture for minutes at a time, so a storm sampled
    /// at any other instant would be a storm with no lightning in it. Every
    /// other layer is sampled at the same instant and lands somewhere
    /// unremarkable in its own cycle, which is exactly what is wanted.
    static let instant: Double = 2.944

    struct Transform {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var scale: CGFloat = 1
        var opacity: Double = 1
        var rotation: Double = 0

        static let identity = Transform()
    }

    static func opacity(for anim: Anim) -> Double {
        transform(for: anim).opacity
    }

    /// One keyframe's value at [instant], transcribed from the prototype's own
    /// `@keyframes` blocks.
    static func transform(for anim: Anim) -> Transform {
        let t = anim.phase(at: instant)

        switch anim.name {
        // 0%,100% translateY(3px); 50% translateY(-3px)
        case "sunRise":
            return Transform(dy: pingPong(t, from: 3, to: -3))

        // 0%,100% scale(1) opacity .85; 50% scale(1.1) opacity 1
        case "sunPulse":
            return Transform(scale: pingPong(t, from: 1, to: 1.1),
                             opacity: Double(pingPong(t, from: 0.85, to: 1)))

        case "sunRaysRotate":
            return Transform(rotation: t * 360)

        // 0%,100% opacity .55 scale(1); 50% opacity .9 scale(1.07)
        case "moonGlow":
            return Transform(scale: pingPong(t, from: 1, to: 1.07),
                             opacity: Double(pingPong(t, from: 0.55, to: 0.9)))

        // 0%,100% opacity .25; 50% opacity 1
        case "twinkle":
            return Transform(opacity: Double(pingPong(t, from: 0.25, to: 1)))

        // 0%,100% translateY(0); 50% translateY(-4px)
        case "cloudFloat":
            return Transform(dy: pingPong(t, from: 0, to: -4))

        // 0%,100% translateX(-3px); 50% translateX(3px)
        case "cloudDriftSmall":
            return Transform(dx: pingPong(t, from: -3, to: 3))

        // 0%,100% translateX(-1.5px); 50% translateX(1.5px)
        case "snowSwirl":
            return Transform(dx: pingPong(t, from: -1.5, to: 1.5))

        // 0%,100% translateY(0); 50% translateY(2.5px)
        case "rainDrop":
            return Transform(dy: pingPong(t, from: 0, to: 2.5))

        // 0% translateY(-20px) opacity 0; 20%..80% opacity 1;
        // 100% translateY(210px) opacity 0
        case "rainFall":
            let eased = t * t  // `ease-in`, near enough for a still frame
            return Transform(dy: -20 + eased * 230, opacity: fallOpacity(t))

        // 0%,90%,100% opacity 0; 92% opacity .3; 94% opacity 0
        case "rainFallFlash":
            return Transform(opacity: flashOpacity(t))

        // 0% opacity .4 translateX(0) scale(1); 50% opacity .65;
        // 100% opacity .4 translateX(8px) scale(1.05)
        case "mistSwirl":
            return Transform(dx: t * 8,
                             scale: 1 + t * 0.05,
                             opacity: Double(pingPong(t, from: 0.4, to: 0.65)))

        // 0%,100% translateX(-2px); 50% translateX(3px), and its two siblings.
        case "fogBar1":
            return Transform(dx: pingPong(t, from: -2, to: 3))
        case "fogBar2":
            return Transform(dx: pingPong(t, from: 2, to: -2))
        case "fogBar3":
            return Transform(dx: pingPong(t, from: -1, to: 2))

        default:
            return .identity
        }
    }

    /// A keyframe that runs out to `to` at the halfway mark and back.
    private static func pingPong(_ t: Double, from: CGFloat, to: CGFloat) -> CGFloat {
        let u = t < 0.5 ? t * 2 : (1 - t) * 2
        let eased = u * u * (3 - 2 * u)  // ease-in-out
        return from + (to - from) * eased
    }

    private static func fallOpacity(_ t: Double) -> Double {
        switch t {
        case ..<0.2: return t / 0.2
        case ..<0.8: return 1
        default: return (1 - t) / 0.2
        }
    }

    private static func flashOpacity(_ t: Double) -> Double {
        switch t {
        case ..<0.90: return 0
        case ..<0.92: return (t - 0.90) / 0.02 * 0.3
        case ..<0.94: return (0.94 - t) / 0.02 * 0.3
        default: return 0
        }
    }

    static func gradientStops(_ stops: [Stop]) -> [Gradient.Stop] {
        stops.enumerated().map { index, stop in
            Gradient.Stop(
                color: stop.color,
                location: stop.at ?? (stops.count <= 1
                    ? 0
                    : CGFloat(index) / CGFloat(stops.count - 1))
            )
        }
    }
}
