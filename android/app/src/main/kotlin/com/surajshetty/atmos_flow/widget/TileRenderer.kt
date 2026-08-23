package com.surajshetty.atmos_flow.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface

/**
 * Draws the whole tile — sky, ambient, copy and cards — into one bitmap.
 *
 * A `RemoteViews` tree can hold text and images but not gradients, blurred
 * discs or arbitrary paths, and it cannot reach the app's bundled Figtree
 * either. Painting the tile ourselves and handing the launcher a single
 * ImageView is what makes the design reachable at all; the cost is that the
 * text does not follow the system font scale, which is why the widget also
 * carries a full content description.
 */
object TileRenderer {

    /** The reference the design's fractions are written against for this tile. */
    private const val REFERENCE = 230f

    /** The design's own tile: 280 wide with 16 of padding. */
    private const val DESIGN_WIDTH = 280f

    fun render(context: Context, snapshot: WidgetSnapshot, widthPx: Int, heightPx: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        Density.current = density

        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val w = widthPx.toFloat()
        val h = heightPx.toFloat()
        val sky = snapshot.sky

        // The launcher rounds the widget's own corners on modern Android, but
        // older hosts do not, so the tile carries the design's own radius.
        val radius = 20f * density
        val clip = Path().apply {
            addRoundRect(RectF(0f, 0f, w, h), radius, radius, Path.Direction.CW)
        }
        canvas.clipPath(clip)

        AmbientRenderer.drawSky(canvas, sky, w, h)
        AmbientRenderer.draw(
            canvas,
            AmbientCatalog.layers(snapshot.condition, sky),
            w, h,
            scale = w * (REFERENCE / DESIGN_WIDTH),
        )

        // Everything below is in design points, scaled to the tile's real
        // width so a 5-column widget grows the whole layout rather than
        // stranding the copy in one corner.
        val unit = w / DESIGN_WIDTH
        fun pt(value: Float) = value * unit

        val regular = font(context, "Figtree-Regular.ttf")
        val semiBold = font(context, "Figtree-SemiBold.ttf")

        val text = Paint(Paint.ANTI_ALIAS_FLAG)
        val padding = pt(16f)

        // ── Header ────────────────────────────────────────────────────────
        text.typeface = semiBold
        text.textSize = pt(10f)
        text.letterSpacing = 0.06f
        text.color = sky.caption
        val kickerBaseline = padding - text.fontMetrics.ascent
        canvas.drawText(
            "AtmosFlow · ${sky.label}".uppercase(),
            padding, kickerBaseline, text,
        )

        text.typeface = regular
        text.textSize = pt(13f)
        text.letterSpacing = 0f
        val subtitleTop = kickerBaseline + text.fontMetrics.descent + pt(4f)
        canvas.drawText(
            "${snapshot.condition.label} · ${snapshot.place}",
            padding, subtitleTop - text.fontMetrics.ascent, text,
        )

        val glyphSize = pt(32f)
        WeatherGlyph.draw(
            canvas, snapshot.condition, sky,
            left = w - padding - glyphSize, top = padding,
            size = glyphSize, color = sky.ink,
        )

        // ── The two cards ─────────────────────────────────────────────────
        val headerBottom = maxOf(subtitleTop - text.fontMetrics.ascent + text.fontMetrics.descent,
                                 padding + glyphSize)
        val cardsTop = headerBottom + pt(12f)
        val gap = pt(12f)
        val cardWidth = (w - padding * 2 - gap) / 2f
        val cardHeight = (h - padding - cardsTop).coerceAtLeast(pt(60f))

        drawCard(
            canvas, context, sky,
            RectF(padding, cardsTop, padding + cardWidth, cardsTop + cardHeight),
            big = snapshot.temperature, bigSize = pt(24f), bigOnTop = true,
            small = snapshot.stamp, smallSize = pt(11f), unit = unit,
        )
        drawCard(
            canvas, context, sky,
            RectF(w - padding - cardWidth, cardsTop, w - padding, cardsTop + cardHeight),
            big = snapshot.humidity, bigSize = pt(18f), bigOnTop = false,
            small = "Humidity", smallSize = pt(11f), unit = unit,
        )

        return bitmap
    }

    /**
     * One glass pane. The design puts the reading above its label on the left
     * card and below it on the right, which [bigOnTop] carries.
     */
    private fun drawCard(
        canvas: Canvas, context: Context, sky: WidgetSky, rect: RectF,
        big: String, bigSize: Float, bigOnTop: Boolean,
        small: String, smallSize: Float, unit: Float,
    ) {
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = sky.cardFill }
        val radius = 12f * unit
        canvas.drawRoundRect(rect, radius, radius, fill)

        val regular = font(context, "Figtree-Regular.ttf")
        val bigPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = regular
            textSize = bigSize
            color = sky.ink
            textAlign = Paint.Align.CENTER
        }
        val smallPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = regular
            textSize = smallSize
            color = sky.caption
            textAlign = Paint.Align.CENTER
        }

        val bigHeight = bigPaint.fontMetrics.descent - bigPaint.fontMetrics.ascent
        val smallHeight = smallPaint.fontMetrics.descent - smallPaint.fontMetrics.ascent
        val spacing = 2f * unit
        val total = bigHeight + spacing + smallHeight
        var y = rect.centerY() - total / 2f
        val cx = rect.centerX()

        val first = if (bigOnTop) bigPaint else smallPaint
        val second = if (bigOnTop) smallPaint else bigPaint
        val firstText = if (bigOnTop) big else small
        val secondText = if (bigOnTop) small else big

        canvas.drawText(firstText, cx, y - first.fontMetrics.ascent, first)
        y += (first.fontMetrics.descent - first.fontMetrics.ascent) + spacing
        canvas.drawText(secondText, cx, y - second.fontMetrics.ascent, second)
    }

    private val fonts = mutableMapOf<String, Typeface>()

    /**
     * Figtree, from the Flutter asset bundle the app already ships — the
     * widget renders in the app's own process, so the same files are there.
     */
    private fun font(context: Context, name: String): Typeface = fonts.getOrPut(name) {
        runCatching {
            Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/$name")
        }.getOrDefault(Typeface.DEFAULT)
    }
}
