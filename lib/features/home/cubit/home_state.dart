part of 'home_cubit.dart';

/// State for home screen
class HomeState extends Equatable {
  /// Whether initial loading is in progress
  final bool isLoading;

  /// Current timer state
  final TimerState timerState;

  /// Current timer settings
  final TimerSettings settings;

  /// Whether all required permissions are granted
  final bool hasAllPermissions;

  /// Error message to display
  final String? errorMessage;

  const HomeState({
    this.isLoading = true,
    this.timerState = const TimerState(),
    this.settings = const TimerSettings(),
    this.hasAllPermissions = false,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    TimerState? timerState,
    TimerSettings? settings,
    bool? hasAllPermissions,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      timerState: timerState ?? this.timerState,
      settings: settings ?? this.settings,
      hasAllPermissions: hasAllPermissions ?? this.hasAllPermissions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    timerState,
    settings,
    hasAllPermissions,
    errorMessage,
  ];
}
