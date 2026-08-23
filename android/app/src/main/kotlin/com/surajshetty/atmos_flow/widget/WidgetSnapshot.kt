package com.surajshetty.atmos_flow.widget

import android.content.Context
import android.text.format.DateFormat
import java.util.Date
import java.util.TimeZone

/**
 * One reading, resolved for the moment it is being drawn.
 *
 * The sky and the age are not carried across from the app — they are worked
 * out here, from [WidgetReading]. A tile draws a reading that can be hours
 * old, so anything the app resolved against its own "now" would be wrong by
 * the time anyone looked at it.
 */
data class WidgetSnapshot(
    val condition: WidgetCondition,
    val sky: WidgetSky,
    val temperature: String,
    val humidity: String,
    val place: String,
    val conditionLabel: String,
    /**
     * When the reading was taken: the hour on the place's own clock while it
     * is fresh, and how old it is once it is not. See [WidgetReading.stampAt].
     */
    val stamp: String,
) {
    /** "Afternoon · Clear" — follows this snapshot's sky, not the app's. */
    val caption: String
        get() = "${sky.label} · ${condition.label}"

    /** What the widget says out loud. */
    val description: String
        get() = "$temperature in $place, $caption, humidity $humidity, $stamp"

    companion object {
        /** Shown in the picker, and before the app has ever run. */
        val PLACEHOLDER = WidgetSnapshot(
            condition = WidgetCondition.CLEAR,
            sky = WidgetSky.AFTERNOON,
            temperature = "22°",
            humidity = "58%",
            place = "San Francisco",
            conditionLabel = "Clear",
            stamp = "2:14 PM",
        )

        /**
         * Where the app leaves its reading. Named by `home_widget`, which is
         * what writes it — see `WidgetPublisher` for why the app stopped
         * carrying it across on a channel of its own.
         */
        const val STORE = "HomeWidgetPreferences"

        /**
         * The last reading the app wrote, resolved for [now].
         *
         * The widget cannot fetch a forecast of its own, so an empty store
         * means the app has not run yet — the placeholder stands in rather
         * than an error, which is what the picker preview wants anyway.
         */
        fun read(context: Context, now: Long = System.currentTimeMillis()): WidgetSnapshot {
            val prefs = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            val temperature = prefs.getString("temperature", null) ?: return PLACEHOLDER
            fun value(key: String, fallback: String) = prefs.getString(key, fallback) ?: fallback

            val reading = WidgetReading(
                skyChanges = WidgetReading.parseSchedule(value("skySchedule", "")),
                updatedAt = value("updatedAt", "").toLongOrNull()?.times(1000),
                utcOffsetMinutes = value("utcOffsetMinutes", "").toIntOrNull() ?: 0,
            )

            return WidgetSnapshot(
                condition = WidgetCondition.from(prefs.getString("condition", null)),
                sky = reading.skyAt(now),
                temperature = temperature,
                humidity = value("humidity", "—"),
                place = value("place", ""),
                conditionLabel = value("conditionLabel", ""),
                // `getTimeFormat` is the one that follows the system's own
                // 12/24-hour setting; a hand-written pattern would not.
                stamp = reading.stampAt(now) { instant ->
                    DateFormat.getTimeFormat(context)
                        .apply { timeZone = reading.zone }
                        .format(Date(instant))
                },
            )
        }
    }
}

/**
 * The time-dependent half of a reading: when it was taken, and the run of sky
 * changes ahead of it.
 *
 * Kept apart from [WidgetSnapshot] so the resolving can be tested without a
 * `Context` to read preferences from.
 */
data class WidgetReading(
    val skyChanges: List<SkyChange>,
    val updatedAt: Long?,
    /**
     * The place's offset from UTC, in minutes — what turns [updatedAt] back
     * into the hour it was on the clock there.
     */
    val utcOffsetMinutes: Int = 0,
) {
    /** The sky becomes [sky] at [at] (epoch millis), and holds until the next. */
    data class SkyChange(val at: Long, val sky: WidgetSky)

    /**
     * The sky in force at [now] — the last change to have happened, or the
     * first on record if [now] precedes them all.
     */
    fun skyAt(now: Long): WidgetSky {
        var current = skyChanges.firstOrNull()?.sky ?: WidgetSky.AFTERNOON
        for (change in skyChanges) {
            if (change.at > now) break
            current = change.sky
        }
        return current
    }

    /** [utcOffsetMinutes] as a zone a `DateFormat` will take. */
    val zone: TimeZone
        get() {
            val sign = if (utcOffsetMinutes < 0) "-" else "+"
            val minutes = kotlin.math.abs(utcOffsetMinutes)
            return TimeZone.getTimeZone(
                "GMT%s%02d:%02d".format(sign, minutes / 60, minutes % 60),
            )
        }

    /**
     * The clock, or the age once the reading is old enough that the clock
     * would be quietly misleading.
     *
     * [clock] is passed in rather than reached for so the rule can be tested
     * without a `Context` and without the device's locale deciding the answer.
     */
    fun stampAt(now: Long, clock: (Long) -> String): String {
        val updatedAt = updatedAt ?: return ""
        val seconds = ((now - updatedAt) / 1000).coerceAtLeast(0)
        return if (seconds < STALE_AFTER_SECONDS) clock(updatedAt) else ageAt(now)
    }

    /**
     * Deliberately coarse. The tile has room for a couple of words, and to
     * the minute is a precision nobody reads a weather widget for.
     */
    fun ageAt(now: Long): String {
        val updatedAt = updatedAt ?: return ""
        val seconds = ((now - updatedAt) / 1000).coerceAtLeast(0)
        return when {
            seconds < 120 -> "Just now"
            seconds < 3600 -> "${seconds / 60}m ago"
            seconds < 86_400 -> "${seconds / 3600}h ago"
            seconds < 172_800 -> "Yesterday"
            else -> "${seconds / 86_400}d ago"
        }
    }

    companion object {
        /**
         * Past this the hour a reading was taken stops being the useful fact
         * and its age takes over. Matched by `WidgetReading.staleAfter` on
         * iOS.
         */
        const val STALE_AFTER_SECONDS = 3 * 3600

        /**
         * `<epochSeconds>:<sky>` pairs, comma separated. Anything unreadable
         * is dropped rather than defaulted — a missing change leaves the
         * previous sky standing, which is the older behaviour and not worth
         * a crash.
         */
        fun parseSchedule(raw: String): List<SkyChange> =
            raw.split(",").mapNotNull { pair ->
                val halves = pair.split(":")
                if (halves.size != 2) return@mapNotNull null
                val seconds = halves[0].toLongOrNull() ?: return@mapNotNull null
                // Matched on the key the app sends, not the enum's own name —
                // `WidgetSky.from` would fall back to AFTERNOON on a typo and
                // bury the change in the middle of an otherwise good run.
                val sky = WidgetSky.entries.firstOrNull { it.key == halves[1] }
                    ?: return@mapNotNull null
                SkyChange(at = seconds * 1000, sky = sky)
            }
    }
}
