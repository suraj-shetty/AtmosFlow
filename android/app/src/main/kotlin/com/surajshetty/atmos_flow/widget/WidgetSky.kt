package com.surajshetty.atmos_flow.widget

import android.graphics.Color

/** The seven conditions, named as the app's own `WeatherCondition` sends them. */
enum class WidgetCondition(val key: String, val label: String) {
    CLEAR("clear", "Clear"),
    CLOUDY("cloudy", "Cloudy"),
    FOG("fog", "Fog"),
    DRIZZLE("drizzle", "Drizzle"),
    RAIN("rain", "Rain"),
    SNOW("snow", "Snow"),
    STORM("storm", "Storm");

    /**
     * Whether this condition's veil drags a bright sky down toward mid-grey.
     *
     * Rain's is rgba(52, 58, 80, .58) and the storm's rgba(24, 26, 44, .64):
     * either takes a morning down to about #7A7F8B before the copy lands on
     * it. See [WidgetPalette].
     */
    val darkensSky: Boolean get() = this == RAIN || this == STORM

    /**
     * Whether this condition's veil lifts a dim sky up toward mid-grey — the
     * same problem from the other side.
     *
     * Fog's is rgba(196, 198, 206, .56) and snow's rgba(214, 222, 238, .5),
     * pale enough to wash a dawn or an evening out from under white copy.
     */
    val lightensSky: Boolean get() = this == FOG || this == SNOW

    companion object {
        fun from(key: String?) = entries.firstOrNull { it.key == key } ?: CLEAR
    }
}

/** The five skies the widget design paints, matching the app's `SkyTime`. */
enum class WidgetSky(val key: String, val label: String) {
    DAWN("dawn", "Dawn"),
    MORNING("morning", "Morning"),
    AFTERNOON("afternoon", "Afternoon"),
    EVENING("evening", "Evening"),
    NIGHT("night", "Night");

    /**
     * How dark the sky is on its own, in three steps rather than two.
     *
     * The design's copy rule only needs two — dawn, evening and night take
     * white, morning and afternoon take ink — but a veil painted over the sky
     * moves it, and the three behave differently when it does. Dawn and
     * evening start mid-toned and a pale veil is enough to wash them out from
     * under white; night starts at #141A30 and no veil in the set gets it far
     * enough to matter. See [WidgetPalette].
     */
    enum class Depth { BRIGHT, DUSK, DARK }

    val depth: Depth
        get() = when (this) {
            MORNING, AFTERNOON -> Depth.BRIGHT
            DAWN, EVENING -> Depth.DUSK
            NIGHT -> Depth.DARK
        }

    /**
     * The tile's background, as the design's CSS writes it: an angle in the
     * CSS sense (180° runs top to bottom, turning clockwise), and stops with
     * their positions.
     */
    val gradientAngle: Float
        get() = when (this) {
            MORNING, AFTERNOON -> 160f
            else -> 180f
        }

    val gradientColors: IntArray
        get() = when (this) {
            DAWN -> intArrayOf(0xFF3D3A5C.toInt(), 0xFF8A6A86.toInt(), 0xFFE8A06A.toInt())
            MORNING -> intArrayOf(0xFFBCD8EE.toInt(), 0xFFF5E3CC.toInt())
            AFTERNOON -> intArrayOf(0xFF8FC4E8.toInt(), 0xFFDCEAF5.toInt())
            EVENING -> intArrayOf(0xFF6A5A8C.toInt(), 0xFFD2765C.toInt(), 0xFFF2B06A.toInt())
            NIGHT -> intArrayOf(0xFF141A30.toInt(), 0xFF26304F.toInt())
        }

    val gradientStops: FloatArray
        get() = when (this) {
            DAWN -> floatArrayOf(0f, 0.45f, 1f)
            EVENING -> floatArrayOf(0f, 0.6f, 1f)
            else -> floatArrayOf(0f, 1f)
        }

    companion object {
        fun from(key: String?) = entries.firstOrNull { it.key == key } ?: AFTERNOON
    }
}

/**
 * The design's two sets of copy colours — white, or ink — and which set a tile
 * takes.
 *
 * The design picks by sky: white on dawn, evening and night, ink on morning
 * and afternoon. Read as a rule about the sky that is what it says, but the
 * copy is not drawn on the sky. It is drawn on the sky *and* the condition's
 * veil, and four of the seven veils move the tile far enough to change the
 * answer — in both directions.
 *
 * Measured off the rendered tiles, on the pixels each string actually covers
 * (`tool/brand/contrast.py`), the sky-only rule leaves eight tiles where the
 * other set is the better one, four at each end:
 *
 *     rain, storm   over morning, afternoon   temperature 4.2 -> white 5.7
 *     fog, snow     over dawn, evening        temperature 2.4 -> ink   6.8
 *
 * So depth proposes and the condition can override. Night is the one that
 * never moves: it starts dark enough that even the palest veil leaves white
 * ahead.
 */
class WidgetPalette private constructor(private val isDark: Boolean) {

    val ink: Int get() = if (isDark) Color.WHITE else 0xFF1B1F26.toInt()

    val caption: Int
        get() = if (isDark) alpha(Color.WHITE, 0.8f) else alpha(0xFF282E38.toInt(), 0.74f)

    val cardFill: Int
        get() = alpha(Color.WHITE, if (isDark) 0.14f else 0.42f)

    companion object {
        fun on(condition: WidgetCondition, sky: WidgetSky) = WidgetPalette(
            when (sky.depth) {
                WidgetSky.Depth.BRIGHT -> condition.darkensSky
                WidgetSky.Depth.DUSK -> !condition.lightensSky
                WidgetSky.Depth.DARK -> true
            },
        )

        private fun alpha(color: Int, opacity: Float): Int =
            Color.argb(
                (Color.alpha(color) * opacity).toInt(),
                Color.red(color), Color.green(color), Color.blue(color),
            )
    }
}
