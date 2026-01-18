import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/services.dart';
import '../../../models/models.dart';

part 'settings_state.dart';

/// Cubit for managing settings screen state
class SettingsCubit extends Cubit<SettingsState> {
  final TimerService _timerService;
  final PermissionService _permissionService;

  SettingsCubit({
    required TimerService timerService,
    required PermissionService permissionService,
  }) : _timerService = timerService,
       _permissionService = permissionService,
       super(const SettingsState());

  /// Initialize the cubit
  Future<void> init() async {
    emit(state.copyWith(isLoading: true));

    final settings = _timerService.settings;
    final permissions = await _permissionService.getAllPermissions();

    emit(
      state.copyWith(
        isLoading: false,
        settings: settings,
        permissions: permissions,
      ),
    );
  }

  /// Update screen time duration
  Future<void> updateScreenTime(Duration duration) async {
    final newSettings = state.settings.copyWith(screenTime: duration);
    await _timerService.updateSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  /// Update break time duration
  Future<void> updateBreakTime(Duration duration) async {
    final newSettings = state.settings.copyWith(breakTime: duration);
    await _timerService.updateSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  /// Toggle sound enabled
  Future<void> toggleSound() async {
    final newSettings = state.settings.copyWith(
      soundEnabled: !state.settings.soundEnabled,
    );
    await _timerService.updateSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  /// Toggle vibration enabled
  Future<void> toggleVibration() async {
    final newSettings = state.settings.copyWith(
      vibrationEnabled: !state.settings.vibrationEnabled,
    );
    await _timerService.updateSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  /// Refresh permissions
  Future<void> refreshPermissions() async {
    final permissions = await _permissionService.getAllPermissions();
    emit(state.copyWith(permissions: permissions));
  }

  /// Request a specific permission
  Future<void> requestPermission(PermissionInfo permission) async {
    await permission.requestPermission();
    await refreshPermissions();
  }
}
