package com.surajshetty.atmos_flow.widget

import android.content.Context

/** One reading, as the widget sees it. */
data class WidgetSnapshot(
    val condition: WidgetCondition,
    val sky: WidgetSky,
    val temperature: String,
    val humidity: String,
    val clock: String,
    val place: String,
    val caption: String,
) {
    /** What the widget says out loud. */
    val description: String
        get() = "$temperature in $place, $caption, humidity $humidity"

    companion object {
        /** Shown in the picker, and before the app has ever run. */
        val PLACEHOLDER = WidgetSnapshot(
            condition = WidgetCondition.CLEAR,
            sky = WidgetSky.AFTERNOON,
            temperature = "22°",
            humidity = "58%",
            clock = "14:30",
            place = "San Francisco",
            caption = "Afternoon · Clear",
        )

        const val STORE = "atmos_flow.widget"

        /**
         * The last reading the app wrote.
         *
         * The widget cannot fetch a forecast of its own, so an empty store
         * means the app has not run yet — the placeholder stands in rather
         * than an error, which is what the picker preview wants anyway.
         */
        fun read(context: Context): WidgetSnapshot {
            val prefs = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            val temperature = prefs.getString("temperature", null) ?: return PLACEHOLDER
            fun value(key: String, fallback: String) = prefs.getString(key, fallback) ?: fallback
            return WidgetSnapshot(
                condition = WidgetCondition.from(prefs.getString("condition", null)),
                sky = WidgetSky.from(prefs.getString("sky", null)),
                temperature = temperature,
                humidity = value("humidity", "—"),
                clock = value("clock", ""),
                place = value("place", ""),
                caption = value("caption", ""),
            )
        }

        fun write(context: Context, values: Map<String, String>) {
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().apply {
                values.forEach { (key, value) -> putString(key, value) }
                apply()
            }
        }
    }
}
