package com.surajshetty.atmos_flow.widget

import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import java.io.File

/**
 * Renders every tile the design draws and writes it out as a PNG.
 *
 * Not an assertion — a contact sheet. The widget's whole job is to look like
 * the design, and 35 skies is more than anyone will check by placing widgets
 * on a home screen one at a time.
 *
 *     flutter build apk --debug
 *     ./gradlew :app:connectedDebugAndroidTest   (from android/)
 *     adb pull /sdcard/Android/data/com.surajshetty.atmos_flow/cache/widget-tiles
 */
class TileRenderTest {

    @Test
    fun renderEveryTile() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val directory = File(context.externalCacheDir, "widget-tiles")
        directory.deleteRecursively()
        directory.mkdirs()

        val density = context.resources.displayMetrics.density
        val width = (280 * density).toInt()
        val height = (144 * density).toInt()

        for (condition in WidgetCondition.entries) {
            for (sky in WidgetSky.entries) {
                val snapshot = sample(condition, sky)
                val bitmap = TileRenderer.render(context, snapshot, width, height)
                File(directory, "wide-${condition.key}-${sky.key}.png").outputStream().use {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                }
            }
        }

        println("WIDGET TILES: ${directory.absolutePath}")
    }

    /** The design's own sample readings, so the render is comparable to it. */
    private fun sample(condition: WidgetCondition, sky: WidgetSky) = WidgetSnapshot(
        condition = condition,
        sky = sky,
        temperature = when (sky) {
            WidgetSky.DAWN -> "12°"
            WidgetSky.MORNING -> "16°"
            WidgetSky.AFTERNOON -> "22°"
            WidgetSky.EVENING -> "18°"
            WidgetSky.NIGHT -> "11°"
        },
        humidity = "58%",
        clock = when (sky) {
            WidgetSky.DAWN -> "5:42"
            WidgetSky.MORNING -> "9:15"
            WidgetSky.AFTERNOON -> "14:30"
            WidgetSky.EVENING -> "19:48"
            WidgetSky.NIGHT -> "23:20"
        },
        place = "SF",
        caption = "${sky.label} · ${condition.label}",
    )
}
