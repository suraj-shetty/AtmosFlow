package com.surajshetty.atmos_flow.widget

import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import androidx.core.graphics.PathParser

/**
 * The seven condition icons, as the design draws them.
 *
 * The paths are the design's own `d` attributes, kept in that form rather than
 * retraced as drawing calls — a transcription with no way to check itself is
 * exactly the kind of thing that goes quietly wrong. They sit on a 24-unit
 * grid inside a 28-unit box (the prototype's `viewBox "-2 -2 28 28"`, which
 * leaves room for the 2.2 stroke to overhang).
 */
object WeatherGlyph {

    fun draw(canvas: Canvas, condition: WidgetCondition, sky: WidgetSky,
             left: Float, top: Float, size: Float, color: Int) {
        val unit = size / 28f
        val matrix = Matrix().apply {
            setScale(unit, unit)
            postTranslate(left + 2f * unit, top + 2f * unit)
        }

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2.2f * unit
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            this.color = color
        }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            this.color = color
        }

        for ((data, filled) in elements(condition, sky)) {
            val path = PathParser.createPathFromPathData(data)
            path.transform(matrix)
            canvas.drawPath(path, if (filled) fill else stroke)
        }
    }

    /** The `d` strings and whether each is filled, matching the iOS glyphs. */
    private fun elements(condition: WidgetCondition, sky: WidgetSky): List<Pair<String, Boolean>> =
        when {
            condition == WidgetCondition.CLEAR && sky == WidgetSky.NIGHT -> listOf(
                "M20 14.2A8 8 0 1 1 9.8 4a6.4 6.4 0 0 0 10.2 10.2z" to true,
                "M19 3L19 6" to false,
                "M17.5 4.5L20.5 4.5" to false,
            )

            condition == WidgetCondition.CLEAR -> buildList {
                add("M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8z" to true)
                for (ray in listOf(
                    "M18 12L21 12", "M16.24 16.24L18.36 18.36",
                    "M12 18L12 21", "M7.76 16.24L5.64 18.36",
                    "M6 12L3 12", "M7.76 7.76L5.64 5.64",
                    "M12 6L12 3", "M16.24 7.76L18.36 5.64",
                )) add(ray to false)
            }

            condition == WidgetCondition.CLOUDY -> listOf(cloud(19) to false)

            condition == WidgetCondition.FOG -> listOf(
                "M4 9L20 9" to false,
                "M4 13L20 13" to false,
                "M4 17L16 17" to false,
            )

            condition == WidgetCondition.DRIZZLE -> listOf(
                cloud(12) to false,
                "M9 16L8.5 18" to false,
                "M13 16L12.5 18" to false,
                "M17 16L16.5 18" to false,
            )

            condition == WidgetCondition.RAIN -> listOf(
                cloud(15) to false,
                "M8 18L7 21" to false,
                "M12 18L11 21" to false,
                "M16 18L15 21" to false,
            )

            condition == WidgetCondition.SNOW -> listOf(
                cloud(15) to false,
                dot(8f, 19f) to true,
                dot(12f, 20f) to true,
                dot(16f, 19f) to true,
            )

            else -> listOf(
                cloud(14) to false,
                "M13 13l-3.5 5.5H12l-1.5 4L15 16h-2.5z" to true,
            )
        }

    /**
     * The cloud body. Across the whole icon set the design changes exactly one
     * thing about it — how far down its flat underside sits — sliding it up to
     * make room for the drizzle, the rain, the snow and the bolt.
     */
    private fun cloud(baseline: Int) =
        "M6.5 ${baseline}a4.5 4.5 0 0 1-.4-8.98 5.5 5.5 0 0 1 10.7-2A4.5 4.5 0 0 1 17 ${baseline}H6.5z"

    private fun dot(x: Float, y: Float) =
        "M$x ${y - 0.9f}a0.9 0.9 0 1 0 0 1.8a0.9 0.9 0 1 0 0-1.8z"

    /** The humidity droplet beside the reading. */
    const val DROPLET = "M12 3.6c0 0 5.2 5.6 5.2 9.1a5.2 5.2 0 1 1-10.4 0C6.8 9.2 12 3.6 12 3.6z"

    fun drawPath(canvas: Canvas, data: String, left: Float, top: Float,
                 size: Float, color: Int) {
        val unit = size / 28f
        val matrix = Matrix().apply {
            setScale(unit, unit)
            postTranslate(left + 2f * unit, top + 2f * unit)
        }
        val path = PathParser.createPathFromPathData(data)
        path.transform(matrix)
        canvas.drawPath(path, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2.2f * unit
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            this.color = color
        })
    }
}
