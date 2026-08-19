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
}
