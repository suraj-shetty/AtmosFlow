/// The five skies the widget design paints, and how a real forecast picks one.
///
/// The design draws each widget over one of five gradients — dawn, morning,
/// afternoon, evening, night — rather than the app's own day/night pair. They
/// are anchored to the sun rather than to the clock: dawn is the hour around
/// sunrise wherever the place is, not 5 AM everywhere.
enum SkyTime {
  dawn('Dawn'),
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  night('Night');

  const SkyTime(this.label);

  /// The word the widget prints — "Dawn · Clear".
  final String label;

  /// Whether this sky is dark enough to take white copy.
  ///
  /// The design's own answer: dawn, evening and night print white, morning and
  /// afternoon print ink.
  bool get isDark => this != SkyTime.morning && this != SkyTime.afternoon;

  /// Which sky [now] falls in, given the day's sun.
  ///
  /// The bands run: an hour before sunrise through 90 minutes after it is
  /// dawn; from there to solar noon is morning; noon until 90 minutes before
  /// sunset is afternoon; through to an hour past sunset is evening; the rest
  /// is night. Solar noon is taken as the midpoint of the two, so a long
  /// Reykjavík summer day splits the same way a short one does.
  static SkyTime resolve({
    required DateTime now,
    required DateTime sunrise,
    required DateTime sunset,
  }) {
    final dawnStart = sunrise.subtract(const Duration(hours: 1));
    final dawnEnd = sunrise.add(const Duration(minutes: 90));
    final eveningStart = sunset.subtract(const Duration(minutes: 90));
    final eveningEnd = sunset.add(const Duration(hours: 1));
    final noon = sunrise.add(
      Duration(microseconds: sunset.difference(sunrise).inMicroseconds ~/ 2),
    );

    if (now.isBefore(dawnStart) || !now.isBefore(eveningEnd)) {
      return SkyTime.night;
    }
    if (now.isBefore(dawnEnd)) return SkyTime.dawn;
    if (!now.isBefore(eveningStart)) return SkyTime.evening;
    return now.isBefore(noon) ? SkyTime.morning : SkyTime.afternoon;
  }

  /// Every moment the sky changes between [start] and [start] + [window],
  /// so a widget can move through the day on its own.
  ///
  /// The widget draws whatever the app last fetched, which may be hours old —
  /// left with a single sky resolved at publish time it would still be
  /// painting an afternoon at midnight. Handing it the whole run of changes
  /// lets it advance without the app, and without a network call it could not
  /// make anyway.
  ///
  /// The bands are not restated here: each candidate moment is put back
  /// through [resolve], so the schedule cannot drift from the live answer.
  /// Candidates are the five band edges of each day in [days] — which is what
  /// makes the result exact rather than sampled — and the run is collapsed so
  /// only actual changes survive.
  ///
  /// Everything is naive wall-clock, like [resolve] and like the stamps the
  /// API returns. Converting to absolute instants is the caller's job, and
  /// needs the place's UTC offset.
  static List<SkyChange> scheduleFrom({
    required DateTime start,
    required Duration window,
    required List<SunDay> days,
  }) {
    if (days.isEmpty) return const [];

    final end = start.add(window);
    final candidates = <DateTime>{start};
    for (final day in days) {
      candidates.addAll([
        day.sunrise.subtract(const Duration(hours: 1)),
        day.sunrise.add(const Duration(minutes: 90)),
        day.sunrise.add(
          Duration(
            microseconds:
                day.sunset.difference(day.sunrise).inMicroseconds ~/ 2,
          ),
        ),
        day.sunset.subtract(const Duration(minutes: 90)),
        day.sunset.add(const Duration(hours: 1)),
      ]);
    }

    final moments =
        candidates
            .where((t) => !t.isBefore(start) && !t.isAfter(end))
            .toList(growable: false)
          ..sort();

    final changes = <SkyChange>[];
    for (final moment in moments) {
      final day = _dayFor(moment, days);
      final sky = resolve(
        now: moment,
        sunrise: day.sunrise,
        sunset: day.sunset,
      );
      // A boundary that does not actually change anything — a polar day where
      // two bands collapse onto each other — is not worth an entry.
      if (changes.isNotEmpty && changes.last.sky == sky) continue;
      changes.add(SkyChange(at: moment, sky: sky));
    }
    return changes;
  }

  /// The sun that governs [moment] — the day whose lit span actually contains
  /// it, taking the span to be the one [resolve] draws its bands across:
  /// an hour before sunrise through an hour after sunset.
  ///
  /// Two simpler rules both fail, in opposite directions. The last sunrise to
  /// have happened loses dawn, which opens a full hour before the sun does, so
  /// the moment a dawn begins belongs to a day that has not started yet. The
  /// nearest sunrise loses evening: by late afternoon tomorrow's sunrise is
  /// the closer of the two, and the day gets read against a sun that has not
  /// come up, which resolves as night.
  ///
  /// Outside every span it is night whichever day is used, so the nearest one
  /// is picked and the answer is the same either way. Nothing here touches
  /// the calendar date, which is what keeps a polar day working when its
  /// sunset lands on the following one.
  static SunDay _dayFor(DateTime moment, List<SunDay> days) {
    var best = days.first;
    var closest = Duration(microseconds: 1 << 62);

    for (final day in days) {
      final opens = day.sunrise.subtract(const Duration(hours: 1));
      final closes = day.sunset.add(const Duration(hours: 1));
      if (!moment.isBefore(opens) && moment.isBefore(closes)) return day;

      final distance = moment.isBefore(opens)
          ? opens.difference(moment)
          : moment.difference(closes);
      if (distance >= closest) continue;
      best = day;
      closest = distance;
    }
    return best;
  }
}

/// One day's sun, as [SkyTime.scheduleFrom] needs it.
class SunDay {
  const SunDay({required this.sunrise, required this.sunset});

  final DateTime sunrise;
  final DateTime sunset;
}

/// The sky becomes [sky] at [at], and stays that way until the next change.
class SkyChange {
  const SkyChange({required this.at, required this.sky});

  final DateTime at;
  final SkyTime sky;
}
