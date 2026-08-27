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
     * Whether this condition's veil is heavy enough to darken a bright sky
     * past the point where ink still reads against it.
     *
     * Every condition but clear lays a veil over the sky, and most are pale
     * or thin enough to leave a morning a morning. Rain's is
     * rgba(52, 58, 80, .58) and the storm's rgba(24, 26, 44, .64) — those two
     * take a bright sky down to around #7A7F8B. See [WidgetPalette].
     */
    val darkensSky: Boolean get() = this == RAIN || this == STORM

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
     * Whether the sky itself is dark: the design paints dawn, evening and
     * night dark, and morning and afternoon bright. Whether the *tile* ends up
     * dark is [WidgetPalette]'s question, because the condition paints over
     * this.
     */
    val isDark: Boolean get() = this != MORNING && this != AFTERNOON

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
 * and afternoon. That holds wherever the sky is the last thing painted, and
 * for five of the seven conditions it is close enough. It is not the whole
 * story. The condition veil sits over the sky and under the copy, and rain's
 * and the storm's are heavy enough that a bright morning arrives at the copy
 * as dark as an evening. Ink on those measured 4.1:1 for the temperature and
 * 2.3:1 for the caption — the four tiles where the reading disappeared.
 *
 * So the sky proposes and the condition can override: anything
 * [WidgetCondition.darkensSky] takes the white set at every hour.
 */
class WidgetPalette private constructor(private val isDark: Boolean) {

    val ink: Int get() = if (isDark) Color.WHITE else 0xFF1B1F26.toInt()

    val caption: Int
        get() = if (isDark) alpha(Color.WHITE, 0.8f) else alpha(0xFF282E38.toInt(), 0.74f)

    val cardFill: Int
        get() = alpha(Color.WHITE, if (isDark) 0.14f else 0.42f)

    companion object {
        fun on(condition: WidgetCondition, sky: WidgetSky) =
            WidgetPalette(sky.isDark || condition.darkensSky)

        private fun alpha(color: Int, opacity: Float): Int =
            Color.argb(
                (Color.alpha(color) * opacity).toInt(),
                Color.red(color), Color.green(color), Color.blue(color),
            )
    }
}
