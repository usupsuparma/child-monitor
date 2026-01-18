import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/services.dart';
import '../../../models/models.dart';

part 'home_state.dart';

/// Cubit for managing home screen state
class HomeCubit extends Cubit<HomeState> {
  final TimerService _timerService;
  final PermissionService _permissionService;
  StreamSubscription<TimerState>? _timerSubscription;

  HomeCubit({
    required TimerService timerService,
    required PermissionService permissionService,
  }) : _timerService = timerService,
       _permissionService = permissionService,
       super(const HomeState());

  /// Initialize the cubit
  Future<void> init() async {
    emit(state.copyWith(isLoading: true));

    // Check permissions and auto-request if not granted
    var hasPermissions = await _permissionService.areAllPermissionsGranted();

    if (!hasPermissions) {
      // Auto-request all permissions
      await _permissionService.requestAllPermissions();
      hasPermissions = await _permissionService.areAllPermissionsGranted();
    }

    // Get initial timer state
    final timerState = _timerService.state;
    final settings = _timerService.settings;

    emit(
      state.copyWith(
        isLoading: false,
        timerState: timerState,
        settings: settings,
        hasAllPermissions: hasPermissions,
      ),
    );

    // Subscribe to timer state changes
    _timerSubscription = _timerService.stateStream.listen((timerState) {
      emit(state.copyWith(timerState: timerState));
    });
  }

  /// Start the timer
  Future<void> startTimer() async {
    // Check overlay permission first
    final hasOverlay = await _permissionService.isOverlayPermissionGranted();
    if (!hasOverlay) {
      emit(
        state.copyWith(errorMessage: 'Please grant overlay permission first'),
      );
      return;
    }

    await _timerService.start();
  }

  /// Pause the timer
  Future<void> pauseTimer() async {
    await _timerService.pause();
  }

  /// Resume the timer
  Future<void> resumeTimer() async {
    await _timerService.start();
  }

  /// Stop the timer
  Future<void> stopTimer() async {
    await _timerService.stop();
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Refresh permissions status
  Future<void> refreshPermissions() async {
    final hasPermissions = await _permissionService.areAllPermissionsGranted();
    emit(state.copyWith(hasAllPermissions: hasPermissions));
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
