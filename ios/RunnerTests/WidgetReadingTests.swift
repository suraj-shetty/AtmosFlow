import XCTest

/// The half of the widget that resolves rather than draws.
///
/// This is the seam the app cannot see: the app publishes a schedule and walks
/// away, and everything the tile shows about *when* — which sky, how old — is
/// worked out over here, possibly a day later. A bug in it does not crash, it
/// just quietly paints the wrong sky until someone opens the app.
final class WidgetReadingTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_755_000_000)

    private func reading(
        changes: [WidgetReading.SkyChange] = [],
        updatedAt: Date? = nil,
        utcOffsetMinutes: Int = 0
    ) -> WidgetReading {
        WidgetReading(
            condition: .clear,
            conditionLabel: "Clear",
            temperature: "22°",
            humidity: "58%",
            place: "SF",
            skyChanges: changes,
            updatedAt: updatedAt,
            utcOffsetMinutes: utcOffsetMinutes
        )
    }

    // MARK: - Parsing

    func testParsesTheScheduleTheAppSends() {
        let changes = WidgetReading.parseSchedule("1755000000:afternoon,1755010000:evening")

        XCTAssertEqual(changes.count, 2)
        XCTAssertEqual(changes[0].sky, .afternoon)
        XCTAssertEqual(changes[0].at, Date(timeIntervalSince1970: 1_755_000_000))
        XCTAssertEqual(changes[1].sky, .evening)
    }

    func testDropsUnreadablePairsRatherThanDefaultingThem() {
        // A pair defaulted to a real sky would sit in the middle of an
        // otherwise good run and paint the wrong gradient with confidence.
        let changes = WidgetReading.parseSchedule(
            "1755000000:afternoon,nonsense,1755010000:midwinter,1755020000:night"
        )

        XCTAssertEqual(changes.map(\.sky), [.afternoon, .night])
    }

    func testAnEmptyScheduleParsesToNothing() {
        XCTAssertTrue(WidgetReading.parseSchedule("").isEmpty)
    }

    // MARK: - Sky lookup

    func testHoldsTheLastSkyToHaveStarted() {
        let subject = reading(changes: [
            .init(at: noon, sky: .afternoon),
            .init(at: noon.addingTimeInterval(3600), sky: .evening),
            .init(at: noon.addingTimeInterval(7200), sky: .night),
        ])

        XCTAssertEqual(subject.sky(at: noon), .afternoon)
        XCTAssertEqual(subject.sky(at: noon.addingTimeInterval(1800)), .afternoon)
        // A moment landing exactly on a change belongs to the new sky.
        XCTAssertEqual(subject.sky(at: noon.addingTimeInterval(3600)), .evening)
        // Past the end of the schedule the last sky stands, rather than
        // falling back to a default that would flip the tile at random.
        XCTAssertEqual(subject.sky(at: noon.addingTimeInterval(90_000)), .night)
    }

    func testAMomentBeforeTheScheduleTakesItsFirstSky() {
        let subject = reading(changes: [
            .init(at: noon, sky: .evening),
            .init(at: noon.addingTimeInterval(3600), sky: .night),
        ])

        XCTAssertEqual(subject.sky(at: noon.addingTimeInterval(-3600)), .evening)
    }

    // MARK: - Age

    func testAgeIsCoarseAndReadable() {
        let at = { (seconds: TimeInterval) in
            WidgetReading.age(of: self.noon, at: self.noon.addingTimeInterval(seconds))
        }

        XCTAssertEqual(at(0), "Just now")
        XCTAssertEqual(at(119), "Just now")
        XCTAssertEqual(at(120), "2m ago")
        XCTAssertEqual(at(3599), "59m ago")
        XCTAssertEqual(at(3600), "1h ago")
        XCTAssertEqual(at(86_399), "23h ago")
        XCTAssertEqual(at(86_400), "Yesterday")
        XCTAssertEqual(at(172_800), "2d ago")
    }

    func testAClockSkewedBackwardsDoesNotReadAsTheFuture() {
        // The reading's stamp comes from the forecast's own timezone and the
        // comparison from the device — a phone whose clock is a minute behind
        // must not print "-1m ago".
        XCTAssertEqual(
            WidgetReading.age(of: noon, at: noon.addingTimeInterval(-60)),
            "Just now"
        )
    }

    func testNoStampMeansNoClaimAboutAge() {
        XCTAssertEqual(WidgetReading.age(of: nil, at: noon), "")
    }

    // MARK: - Timeline

    func testAsksToBeRedrawnAtEverySkyChange() {
        let subject = reading(changes: [
            .init(at: noon.addingTimeInterval(-3600), sky: .afternoon),
            .init(at: noon.addingTimeInterval(3600), sky: .evening),
            .init(at: noon.addingTimeInterval(7200), sky: .night),
        ])

        let moments = subject.moments(from: noon)

        XCTAssertEqual(moments.first, noon)
        XCTAssertTrue(moments.contains(noon.addingTimeInterval(3600)))
        XCTAssertTrue(moments.contains(noon.addingTimeInterval(7200)))
        // A change already in the past is not a reason to redraw.
        XCTAssertFalse(moments.contains(noon.addingTimeInterval(-3600)))
        XCTAssertEqual(moments, moments.sorted())
    }

    func testKeepsTickingEvenWithNoSkyChangesLeft() {
        // The age has to keep up with itself, so the timeline cannot simply
        // end when the schedule does.
        let moments = reading().moments(from: noon)

        XCTAssertGreaterThan(moments.count, 24)
        XCTAssertLessThan(
            moments.last!.timeIntervalSince(noon),
            WidgetReading.horizon
        )
    }

    func testTheSkyResolvesPerEntryNotPerPublish() {
        // The whole point: one stored reading, drawn at two moments, gives two
        // different skies without the app running in between.
        let subject = reading(
            changes: [
                .init(at: noon, sky: .afternoon),
                .init(at: noon.addingTimeInterval(3600), sky: .night),
            ],
            updatedAt: noon
        )

        XCTAssertEqual(subject.entry(at: noon).sky, .afternoon)
        XCTAssertEqual(subject.entry(at: noon).caption, "Afternoon · Clear")
        XCTAssertEqual(subject.entry(at: noon.addingTimeInterval(7200)).sky, .night)
        XCTAssertEqual(
            subject.entry(at: noon.addingTimeInterval(7200)).caption,
            "Night · Clear"
        )
        // Two hours on, the reading still prints the hour it was taken at;
        // four hours on it has to admit its age instead.
        XCTAssertEqual(
            subject.entry(at: noon.addingTimeInterval(7200)).stamp,
            subject.clock(noon)
        )
        XCTAssertEqual(
            subject.entry(at: noon.addingTimeInterval(4 * 3600)).stamp,
            "4h ago"
        )
    }

    // MARK: - The stamp

    func testAFreshReadingPrintsTheHourItWasTakenAt() {
        let subject = reading(updatedAt: noon)

        XCTAssertEqual(
            subject.stamp(at: noon.addingTimeInterval(600), clock: { _ in "15:20" }),
            "15:20"
        )
    }

    func testAStaleReadingGivesTheHourUpForItsAge() {
        // An hour on its own reads as current. Once it is old enough that it
        // is not, the tile has to say so rather than print a plausible time.
        let subject = reading(updatedAt: noon)
        let clock: (Date) -> String = { _ in "15:20" }

        XCTAssertEqual(
            subject.stamp(at: noon.addingTimeInterval(WidgetReading.staleAfter - 1), clock: clock),
            "15:20"
        )
        XCTAssertEqual(
            subject.stamp(at: noon.addingTimeInterval(WidgetReading.staleAfter), clock: clock),
            "3h ago"
        )
    }

    func testNoStampWithoutAStamp() {
        XCTAssertEqual(reading().stamp(at: noon, clock: { _ in "15:20" }), "")
    }

    func testTheHourIsThePlacesOwnAndNotTheDevices() {
        // The reading belongs to somewhere, and its hour is the hour it was
        // there — a phone in another zone still reads the same tile.
        let tokyo = reading(updatedAt: noon, utcOffsetMinutes: 9 * 60)
        let london = reading(updatedAt: noon, utcOffsetMinutes: 60)

        // 1_755_000_000 is 12:00 UTC: 21:00 in Tokyo, 13:00 in London.
        XCTAssertEqual(tokyo.clock(noon), short(noon, offsetMinutes: 9 * 60))
        XCTAssertEqual(london.clock(noon), short(noon, offsetMinutes: 60))
        XCTAssertNotEqual(tokyo.clock(noon), london.clock(noon))
    }

    func testTheHourFollowsWhicheverClockTheDeviceIsSetTo() {
        // The tile reads 12- or 24-hour because the device does, and the app
        // is never told which. That only holds while the hour comes from the
        // locale's own short style — a hand-written "HH:mm" would pin every
        // phone to 24-hour, and this is what would catch it.
        XCTAssertEqual(
            reading(updatedAt: noon, utcOffsetMinutes: 0).clock(noon),
            short(noon, offsetMinutes: 0)
        )
    }

    /// The system's own short time — the answer the tile has to agree with.
    private func short(_ date: Date, offsetMinutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone(secondsFromGMT: offsetMinutes * 60)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
