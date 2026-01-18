part of 'settings_cubit.dart';

/// State for settings screen
class SettingsState extends Equatable {
  /// Whether initial loading is in progress
  final bool isLoading;

  /// Current timer settings
  final TimerSettings settings;

  /// List of permissions with their status
  final List<PermissionInfo> permissions;

  const SettingsState({
    this.isLoading = true,
    this.settings = const TimerSettings(),
    this.permissions = const [],
  });

  SettingsState copyWith({
    bool? isLoading,
    TimerSettings? settings,
    List<PermissionInfo>? permissions,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [isLoading, settings, permissions];
}
