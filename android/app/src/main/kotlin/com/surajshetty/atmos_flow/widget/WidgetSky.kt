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

    /** The design prints white on dawn, evening and night; ink on the others. */
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

    // ── Copy colours ───────────────────────────────────────────────────────
    //
    // Chosen by sky rather than by condition, as the design does: a storm at
    // noon still prints ink, because the veil sits under the copy and the sky
    // above it is bright.

    val ink: Int get() = if (isDark) Color.WHITE else 0xFF1B1F26.toInt()

    val caption: Int
        get() = if (isDark) alpha(Color.WHITE, 0.8f) else alpha(0xFF282E38.toInt(), 0.74f)

    val cardFill: Int
        get() = alpha(Color.WHITE, if (isDark) 0.14f else 0.42f)

    companion object {
        fun from(key: String?) = entries.firstOrNull { it.key == key } ?: AFTERNOON

        fun alpha(color: Int, opacity: Float): Int =
            Color.argb(
                (Color.alpha(color) * opacity).toInt(),
                Color.red(color), Color.green(color), Color.blue(color),
            )
    }
}
