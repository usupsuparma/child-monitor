import 'package:equatable/equatable.dart';

/// Represents the current phase of the timer
enum TimerPhase {
  /// Timer is not running
  idle,

  /// Screen time is active (device unlocked)
  screenTime,

  /// Break time is active (device locked)
  breakTime,
}

/// Represents the current state of the timer
class TimerState extends Equatable {
  /// Current phase of the timer
  final TimerPhase phase;

  /// Remaining time in the current phase
  final Duration remainingTime;

  /// Whether the timer is currently running
  final bool isRunning;

  /// Whether the timer is paused
  final bool isPaused;

  /// Total duration of the current phase
  final Duration totalDuration;

  const TimerState({
    this.phase = TimerPhase.idle,
    this.remainingTime = Duration.zero,
    this.isRunning = false,
    this.isPaused = false,
    this.totalDuration = Duration.zero,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    if (totalDuration.inSeconds == 0) return 0.0;
    final elapsed = totalDuration.inSeconds - remainingTime.inSeconds;
    return elapsed / totalDuration.inSeconds;
  }

  /// Formatted remaining time string (MM:SS)
  String get formattedTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if currently in screen time phase
  bool get isScreenTime => phase == TimerPhase.screenTime;

  /// Check if currently in break time phase
  bool get isBreakTime => phase == TimerPhase.breakTime;

  /// Check if timer is idle
  bool get isIdle => phase == TimerPhase.idle;

  TimerState copyWith({
    TimerPhase? phase,
    Duration? remainingTime,
    bool? isRunning,
    bool? isPaused,
    Duration? totalDuration,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    remainingTime,
    isRunning,
    isPaused,
    totalDuration,
  ];

  @override
  String toString() {
    return 'TimerState(phase: $phase, remainingTime: $remainingTime, '
        'isRunning: $isRunning, isPaused: $isPaused)';
  }
}
