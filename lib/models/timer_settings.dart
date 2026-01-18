/// Timer settings model for screen time and break time configuration
class TimerSettings {
  /// Duration of screen time (device unlocked)
  final Duration screenTime;

  /// Duration of break time (device locked)
  final Duration breakTime;

  /// Enable sound notification when timer expires
  final bool soundEnabled;

  /// Enable vibration when timer expires
  final bool vibrationEnabled;

  const TimerSettings({
    this.screenTime = const Duration(minutes: 30),
    this.breakTime = const Duration(minutes: 10),
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  TimerSettings copyWith({
    Duration? screenTime,
    Duration? breakTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return TimerSettings(
      screenTime: screenTime ?? this.screenTime,
      breakTime: breakTime ?? this.breakTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screenTimeMinutes': screenTime.inMinutes,
      'breakTimeMinutes': breakTime.inMinutes,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      screenTime: Duration(minutes: json['screenTimeMinutes'] as int? ?? 30),
      breakTime: Duration(minutes: json['breakTimeMinutes'] as int? ?? 10),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'TimerSettings(screenTime: $screenTime, breakTime: $breakTime, '
        'soundEnabled: $soundEnabled, vibrationEnabled: $vibrationEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerSettings &&
        other.screenTime == screenTime &&
        other.breakTime == breakTime &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(screenTime, breakTime, soundEnabled, vibrationEnabled);
  }
}
