package com.surajshetty.atmos_flow.widget

import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.sin

/**
 * Draws an ambient sky at one instant.
 *
 * A launcher hosts an app widget as a static set of views, so nothing here
 * moves. Rather than drop the motion and leave every rain streak parked off
 * the top edge where its keyframe starts, the scene is sampled: each shape is
 * placed where its own animation has it at [Ambient.INSTANT]. Because the
 * design gives every drop and every star its own duration and delay, one
 * instant is enough to scatter them the way watching the prototype would.
 */
object AmbientRenderer {

    fun draw(canvas: Canvas, layers: List<AmbientLayer>, w: Float, h: Float, scale: Float) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        for (layer in layers) {
            paint.reset()
            paint.isAntiAlias = true
            when (layer) {
                is AmbientLayer.Veil -> {
                    paint.color = fade(layer.color, Ambient.transform(layer.anim).opacity)
                    canvas.drawRect(0f, 0f, w, h, paint)
                }

                is AmbientLayer.DuskVeil -> {
                    val top = h * (1f - layer.height)
                    paint.shader = LinearGradient(
                        0f, top, 0f, h,
                        Color.TRANSPARENT, layer.color, Shader.TileMode.CLAMP,
                    )
                    canvas.drawRect(0f, top, w, h, paint)
                }

                is AmbientLayer.Radial -> {
                    val t = Ambient.transform(layer.anim)
                    val r = layer.box.rect(w, h, scale)
                    val bw = r[2] - r[0]
                    val bh = r[3] - r[1]
                    if (bw <= 0f || bh <= 0f) continue
                    val cx = r[0] + bw * layer.centerX + t.dx
                    val cy = r[1] + bh * layer.centerY + t.dy
                    // CSS sizes a `radial-gradient(circle, …)` to its farthest
                    // corner, so the stops run to the corner of the box rather
                    // than the edge of the disc.
                    val radius = hypot(bw, bh) / 2f * t.scale
                    paint.shader = RadialGradient(
                        cx, cy, radius,
                        layer.stops.map { fade(it.color, t.opacity) }.toIntArray(),
                        positions(layer.stops),
                        Shader.TileMode.CLAMP,
                    )
                    // The disc itself is only as wide as its box; the gradient
                    // reaching past it is what gives the soft edge.
                    canvas.drawCircle(cx, cy, bw / 2f * t.scale, paint)
                }

                is AmbientLayer.Ring -> {
                    val t = Ambient.transform(layer.anim)
                    val r = layer.box.rect(w, h, scale)
                    paint.style = Paint.Style.STROKE
                    paint.strokeWidth = layer.strokeWidth * Density.current
                    paint.color = layer.color
                    // A rotating circle is a circle; only its stroke phase
                    // would move, and this one is unbroken.
                    canvas.drawOval(RectF(r[0], r[1], r[2], r[3]), paint)
                }

                is AmbientLayer.Fill -> {
                    val t = Ambient.transform(layer.anim)
                    val r = layer.box.rect(w, h, scale)
                    val rect = RectF(r[0] + t.dx, r[1] + t.dy, r[2] + t.dx, r[3] + t.dy)
                    paint.color = fade(layer.color, t.opacity)
                    layer.glow?.let {
                        val blur = it.blur.resolve(scale, scale)
                        if (blur > 0f) paint.maskFilter = BlurMaskFilter(blur, BlurMaskFilter.Blur.NORMAL)
                    }
                    if (layer.round) canvas.drawOval(rect, paint) else canvas.drawRect(rect, paint)
                }

                is AmbientLayer.Mist -> {
                    val t = Ambient.transform(layer.anim)
                    for (blob in layer.blobs) {
                        val bw = blob.width * scale * t.scale
                        val bh = blob.height * scale * t.scale
                        val cx = w * blob.x + t.dx
                        val cy = h * blob.y + t.dy
                        canvas.save()
                        // An `ellipse Wpx Hpx` gradient reaches transparent at
                        // the ellipse's own edge on both axes; Android's is
                        // round, so it is drawn round and squashed.
                        canvas.scale(1f, bh / bw, cx, cy)
                        paint.reset()
                        paint.isAntiAlias = true
                        paint.shader = RadialGradient(
                            cx, cy, bw / 2f,
                            intArrayOf(fade(blob.color, t.opacity), Color.TRANSPARENT),
                            floatArrayOf(0f, 1f),
                            Shader.TileMode.CLAMP,
                        )
                        canvas.drawCircle(cx, cy, bw / 2f, paint)
                        canvas.restore()
                    }
                }
            }
        }
    }

    /** The tile's own background gradient, at the CSS angle. */
    fun drawSky(canvas: Canvas, sky: WidgetSky, w: Float, h: Float) {
        val radians = Math.toRadians(sky.gradientAngle.toDouble())
        val dx = (sin(radians) / 2).toFloat()
        val dy = (-cos(radians) / 2).toFloat()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.shader = LinearGradient(
            w * (0.5f - dx), h * (0.5f - dy),
            w * (0.5f + dx), h * (0.5f + dy),
            sky.gradientColors, sky.gradientStops, Shader.TileMode.CLAMP,
        )
        canvas.drawRect(0f, 0f, w, h, paint)
    }

    private fun positions(stops: List<Stop>): FloatArray =
        FloatArray(stops.size) { i ->
            stops[i].at ?: if (stops.size <= 1) 0f else i.toFloat() / (stops.size - 1)
        }

    private fun fade(color: Int, opacity: Float): Int =
        Color.argb(
            (Color.alpha(color) * opacity).toInt().coerceIn(0, 255),
            Color.red(color), Color.green(color), Color.blue(color),
        )
}
