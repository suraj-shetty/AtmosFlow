package com.surajshetty.atmos_flow.widget

/** The design's keyframes, evaluated rather than played. */
object Ambient {
    /**
     * The instant every widget is drawn at, in seconds since the scene began.
     *
     * Not arbitrary: 2.944s is 92% of the storm's 3.2s `rainFallFlash` cycle,
     * the one frame where the lightning is at full strength. A widget shows a
     * single picture for minutes at a time, so a storm sampled anywhere else
     * would be a storm with no lightning in it. Every other layer samples at
     * the same instant and lands somewhere unremarkable in its own cycle,
     * which is exactly what is wanted. Matches `Ambient.instant` on iOS, so
     * the two platforms draw the same frame.
     */
    const val INSTANT = 2.944f

    data class Transform(
        val dx: Float = 0f,
        val dy: Float = 0f,
        val scale: Float = 1f,
        val opacity: Float = 1f,
        val rotation: Float = 0f,
    )

    val IDENTITY = Transform()

    fun transform(anim: Anim?): Transform {
        if (anim == null) return IDENTITY
        val t = anim.phase(INSTANT)

        return when (anim.name) {
            // 0%,100% translateY(3px); 50% translateY(-3px)
            "sunRise" -> Transform(dy = pingPong(t, 3f, -3f))

            // 0%,100% scale(1) opacity .85; 50% scale(1.1) opacity 1
            "sunPulse" -> Transform(
                scale = pingPong(t, 1f, 1.1f),
                opacity = pingPong(t, 0.85f, 1f),
            )

            "sunRaysRotate" -> Transform(rotation = t * 360f)

            // 0%,100% opacity .55 scale(1); 50% opacity .9 scale(1.07)
            "moonGlow" -> Transform(
                scale = pingPong(t, 1f, 1.07f),
                opacity = pingPong(t, 0.55f, 0.9f),
            )

            // 0%,100% opacity .25; 50% opacity 1
            "twinkle" -> Transform(opacity = pingPong(t, 0.25f, 1f))

            // 0%,100% translateY(0); 50% translateY(-4px)
            "cloudFloat" -> Transform(dy = pingPong(t, 0f, -4f))

            "cloudDriftSmall" -> Transform(dx = pingPong(t, -3f, 3f))
            "snowSwirl" -> Transform(dx = pingPong(t, -1.5f, 1.5f))
            "rainDrop" -> Transform(dy = pingPong(t, 0f, 2.5f))

            // 0% translateY(-20px) opacity 0; 20%..80% opacity 1;
            // 100% translateY(210px) opacity 0
            "rainFall" -> Transform(
                dy = -20f + (t * t) * 230f,
                opacity = fallOpacity(t),
            )

            // 0%,90%,100% opacity 0; 92% opacity .3; 94% opacity 0
            "rainFallFlash" -> Transform(opacity = flashOpacity(t))

            // 0% opacity .4 translateX(0) scale(1); 50% opacity .65;
            // 100% opacity .4 translateX(8px) scale(1.05)
            "mistSwirl" -> Transform(
                dx = t * 8f,
                scale = 1f + t * 0.05f,
                opacity = pingPong(t, 0.4f, 0.65f),
            )

            "fogBar1" -> Transform(dx = pingPong(t, -2f, 3f))
            "fogBar2" -> Transform(dx = pingPong(t, 2f, -2f))
            "fogBar3" -> Transform(dx = pingPong(t, -1f, 2f))

            else -> IDENTITY
        }
    }

    /** A keyframe that runs out to [to] at the halfway mark and back. */
    private fun pingPong(t: Float, from: Float, to: Float): Float {
        val u = if (t < 0.5f) t * 2f else (1f - t) * 2f
        val eased = u * u * (3f - 2f * u)
        return from + (to - from) * eased
    }

    private fun fallOpacity(t: Float) = when {
        t < 0.2f -> t / 0.2f
        t < 0.8f -> 1f
        else -> (1f - t) / 0.2f
    }

    private fun flashOpacity(t: Float) = when {
        t < 0.90f -> 0f
        t < 0.92f -> (t - 0.90f) / 0.02f * 0.3f
        t < 0.94f -> (0.94f - t) / 0.02f * 0.3f
        else -> 0f
    }
}
