package com.surajshetty.atmos_flow.widget

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The half of the widget that resolves rather than draws.
 *
 * This is the seam the app cannot see: the app publishes a schedule and walks
 * away, and everything the tile shows about *when* — which sky, how old — is
 * worked out over here, possibly a day later. A bug in it does not crash, it
 * just quietly paints the wrong sky until someone opens the app.
 *
 * Kept in step with `ios/RunnerTests/WidgetReadingTests.swift`, which holds
 * the same contract to the same answers.
 */
class WidgetReadingTest {

    private val noon = 1_755_000_000_000L // epoch millis

    private fun reading(
        changes: List<WidgetReading.SkyChange> = emptyList(),
        updatedAt: Long? = null,
        utcOffsetMinutes: Int = 0,
    ) = WidgetReading(
        skyChanges = changes,
        updatedAt = updatedAt,
        utcOffsetMinutes = utcOffsetMinutes,
    )

    // ── Parsing ──────────────────────────────────────────────────────────

    @Test
    fun `parses the schedule the app sends`() {
        val changes = WidgetReading.parseSchedule("1755000000:afternoon,1755010000:evening")

        assertEquals(2, changes.size)
        assertEquals(WidgetSky.AFTERNOON, changes[0].sky)
        assertEquals(noon, changes[0].at)
        assertEquals(WidgetSky.EVENING, changes[1].sky)
    }

    @Test
    fun `drops unreadable pairs rather than defaulting them`() {
        // A pair defaulted to a real sky would sit in the middle of an
        // otherwise good run and paint the wrong gradient with confidence.
        val changes = WidgetReading.parseSchedule(
            "1755000000:afternoon,nonsense,1755010000:midwinter,1755020000:night",
        )

        assertEquals(listOf(WidgetSky.AFTERNOON, WidgetSky.NIGHT), changes.map { it.sky })
    }

    @Test
    fun `an empty schedule parses to nothing`() {
        assertTrue(WidgetReading.parseSchedule("").isEmpty())
    }

    // ── Sky lookup ───────────────────────────────────────────────────────

    @Test
    fun `holds the last sky to have started`() {
        val subject = reading(
            listOf(
                WidgetReading.SkyChange(noon, WidgetSky.AFTERNOON),
                WidgetReading.SkyChange(noon + 3_600_000, WidgetSky.EVENING),
                WidgetReading.SkyChange(noon + 7_200_000, WidgetSky.NIGHT),
            ),
        )

        assertEquals(WidgetSky.AFTERNOON, subject.skyAt(noon))
        assertEquals(WidgetSky.AFTERNOON, subject.skyAt(noon + 1_800_000))
        // A moment landing exactly on a change belongs to the new sky.
        assertEquals(WidgetSky.EVENING, subject.skyAt(noon + 3_600_000))
        // Past the end of the schedule the last sky stands, rather than
        // falling back to a default that would flip the tile at random.
        assertEquals(WidgetSky.NIGHT, subject.skyAt(noon + 90_000_000))
    }

    @Test
    fun `a moment before the schedule takes its first sky`() {
        val subject = reading(
            listOf(
                WidgetReading.SkyChange(noon, WidgetSky.EVENING),
                WidgetReading.SkyChange(noon + 3_600_000, WidgetSky.NIGHT),
            ),
        )

        assertEquals(WidgetSky.EVENING, subject.skyAt(noon - 3_600_000))
    }

    // ── Age ──────────────────────────────────────────────────────────────

    @Test
    fun `age is coarse and readable`() {
        val subject = reading(updatedAt = noon)
        fun at(seconds: Long) = subject.ageAt(noon + seconds * 1000)

        assertEquals("Just now", at(0))
        assertEquals("Just now", at(119))
        assertEquals("2m ago", at(120))
        assertEquals("59m ago", at(3599))
        assertEquals("1h ago", at(3600))
        assertEquals("23h ago", at(86_399))
        assertEquals("Yesterday", at(86_400))
        assertEquals("2d ago", at(172_800))
    }

    @Test
    fun `a clock skewed backwards does not read as the future`() {
        // The reading's stamp comes from the forecast's own timezone and the
        // comparison from the device — a phone whose clock is a minute behind
        // must not print "-1m ago".
        assertEquals("Just now", reading(updatedAt = noon).ageAt(noon - 60_000))
    }

    @Test
    fun `no stamp means no claim about age`() {
        assertEquals("", reading().ageAt(noon))
    }

    // ── The stamp ────────────────────────────────────────────────────────

    @Test
    fun `a fresh reading prints the hour it was taken at`() {
        assertEquals("15:20", reading(updatedAt = noon).stampAt(noon + 600_000) { "15:20" })
    }

    @Test
    fun `a stale reading gives the hour up for its age`() {
        // An hour on its own reads as current. Once it is old enough that it
        // is not, the tile has to say so rather than print a plausible time.
        val subject = reading(updatedAt = noon)
        val clock = { _: Long -> "15:20" }
        val stale = WidgetReading.STALE_AFTER_SECONDS * 1000L

        assertEquals("15:20", subject.stampAt(noon + stale - 1000, clock))
        assertEquals("3h ago", subject.stampAt(noon + stale, clock))
    }

    @Test
    fun `no stamp without a stamp`() {
        assertEquals("", reading().stampAt(noon) { "15:20" })
    }

    @Test
    fun `the hour is the place's own and not the device's`() {
        // The reading belongs to somewhere, and its hour is the hour it was
        // there — a phone in another zone still reads the same tile.
        // 1_755_000_000 is 12:00 UTC: 21:00 in Tokyo, 13:00 in London.
        fun hourAt(offsetMinutes: Int): String {
            val zone = reading(utcOffsetMinutes = offsetMinutes).zone
            return SimpleDateFormat("HH:mm", Locale.UK)
                .apply { timeZone = zone }
                .format(Date(noon))
        }

        assertEquals("21:00", hourAt(9 * 60))
        assertEquals("13:00", hourAt(60))
        assertNotEquals(hourAt(9 * 60), hourAt(60))
    }

    @Test
    fun `a zone west of Greenwich keeps its sign`() {
        // "GMT-07:30" and "GMT+07:30" are both valid and only one is right;
        // a lost sign would put the tile fifteen hours out.
        assertEquals(
            TimeZone.getTimeZone("GMT-07:30").rawOffset,
            reading(utcOffsetMinutes = -450).zone.rawOffset,
        )
    }
}
