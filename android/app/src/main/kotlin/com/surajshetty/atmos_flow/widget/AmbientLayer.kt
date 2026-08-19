package com.surajshetty.atmos_flow.widget

/**
 * The design's ambient sky, in the same shape the iOS extension reads it in.
 *
 * Both platforms draw from one model — `tool/widget_spec/ambient_model.json`,
 * which is a reading of the CSS in the AtmosFlow Widgets design — so a tile
 * cannot drift between them without the design moving first.
 *
 * Lengths come in three flavours because the design uses all three: a fraction
 * of the tile's reference size, a percentage of the box, and a literal
 * dimension (hairlines — a rain streak is 2dp wide at every size).
 */
sealed interface Length {
    fun resolve(extent: Float, scale: Float): Float

    data class Frac(val value: Float) : Length {
        override fun resolve(extent: Float, scale: Float) = value * scale
    }

    data class Pct(val value: Float) : Length {
        override fun resolve(extent: Float, scale: Float) = value * extent
    }

    /** Device-independent pixels, scaled to the display like everything else. */
    data class Dp(val value: Float) : Length {
        override fun resolve(extent: Float, scale: Float) = value * Density.current
    }
}

/** The display's density, set once before a tile is drawn. */
object Density {
    var current: Float = 1f
}

/** The CSS box, resolved the way absolute positioning resolves it. */
data class Box(
    val top: Length? = null,
    val left: Length? = null,
    val right: Length? = null,
    val bottom: Length? = null,
    val width: Length? = null,
    val height: Length? = null,
    val marginTop: Length? = null,
    val marginLeft: Length? = null,
) {
    fun rect(w: Float, h: Float, scale: Float): FloatArray {
        val bw = width?.resolve(w, scale) ?: 0f
        val bh = height?.resolve(h, scale) ?: 0f

        var x = when {
            left != null -> left.resolve(w, scale)
            right != null -> w - right.resolve(w, scale) - bw
            else -> 0f
        }
        marginLeft?.let { x += it.resolve(w, scale) }

        var y = when {
            top != null -> top.resolve(h, scale)
            bottom != null -> h - bottom.resolve(h, scale) - bh
            else -> 0f
        }
        marginTop?.let { y += it.resolve(h, scale) }

        return floatArrayOf(x, y, x + bw, y + bh)
    }
}

/**
 * One of the design's keyframe animations, with this shape's own timing.
 *
 * An app widget draws into a [android.widget.RemoteViews] that the launcher
 * hosts — there is no run loop to animate on, so this is never played. It is
 * sampled, at [Ambient.INSTANT], exactly as the iOS extension samples it.
 */
data class Anim(val name: String, val duration: Float, val delay: Float) {
    fun phase(t: Float): Float {
        if (duration <= 0f) return 0f
        val p = ((t - delay) % duration) / duration
        return if (p < 0) p + 1 else p
    }
}

data class Glow(val blur: Length, val spread: Length, val color: Int)

data class MistBlob(
    val width: Float,
    val height: Float,
    val x: Float,
    val y: Float,
    val color: Int,
)

data class Stop(val color: Int, val at: Float? = null)

sealed interface AmbientLayer {
    val anim: Anim?

    /** A full-bleed wash — the condition veil, and the storm's lightning. */
    data class Veil(val color: Int, override val anim: Anim? = null) : AmbientLayer

    /** The dusk gradient across the bottom of a dawn or evening sky. */
    data class DuskVeil(val height: Float, val color: Int) : AmbientLayer {
        override val anim: Anim? get() = null
    }

    data class Radial(
        val box: Box,
        val centerX: Float,
        val centerY: Float,
        val stops: List<Stop>,
        override val anim: Anim?,
    ) : AmbientLayer

    data class Ring(
        val box: Box,
        val strokeWidth: Float,
        val color: Int,
        override val anim: Anim?,
    ) : AmbientLayer

    data class Fill(
        val box: Box,
        val round: Boolean,
        val color: Int,
        val glow: Glow?,
        override val anim: Anim?,
    ) : AmbientLayer

    data class Mist(
        val blobs: List<MistBlob>,
        override val anim: Anim?,
    ) : AmbientLayer
}
