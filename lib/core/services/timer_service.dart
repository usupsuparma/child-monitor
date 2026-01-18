import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import 'background_timer_service.dart';
import 'overlay_service.dart';
import 'storage_service.dart';

/// Service for managing the screen time and break time timer
class TimerService {
  final StorageService _storageService;
  final OverlayService _overlayService;

  Timer? _timer;
  TimerSettings _settings = const TimerSettings();
  TimerState _state = const TimerState();

  /// Stream controller for timer state updates
  final _stateController = StreamController<TimerState>.broadcast();

  /// Stream of timer state updates
  Stream<TimerState> get stateStream => _stateController.stream;

  /// Current timer state
  TimerState get state => _state;

  /// Current timer settings
  TimerSettings get settings => _settings;

  TimerService({
    required StorageService storageService,
    required OverlayService overlayService,
  }) : _storageService = storageService,
       _overlayService = overlayService;

  /// Initialize the timer service
  Future<void> init() async {
    _settings = _storageService.loadSettings();

    // Check if there was a running timer
    final wasRunning = _storageService.loadIsRunning();
    if (wasRunning) {
      final remainingSeconds = _storageService.loadRemainingTime();
      final phaseIndex = _storageService.loadCurrentPhase();

      if (remainingSeconds > 0) {
        final phase = TimerPhase.values[phaseIndex];
        final totalDuration = phase == TimerPhase.screenTime
            ? _settings.screenTime
            : _settings.breakTime;

        _state = TimerState(
          phase: phase,
          remainingTime: Duration(seconds: remainingSeconds),
          isRunning: true,
          totalDuration: totalDuration,
        );

        // Restart background service
        await BackgroundTimerService.startService();
        _startInternalTimer();
        _emitState();
      }
    }
  }

  /// Update timer settings
  Future<void> updateSettings(TimerSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(newSettings);
  }

  /// Start the timer
  Future<void> start() async {
    if (_state.isRunning && !_state.isPaused) return;

    if (_state.isPaused) {
      // Resume from pause
      _state = _state.copyWith(isPaused: false, isRunning: true);
      _startInternalTimer();
    } else {
      // Start fresh with screen time
      _state = TimerState(
        phase: TimerPhase.screenTime,
        remainingTime: _settings.screenTime,
        isRunning: true,
        totalDuration: _settings.screenTime,
      );
      _startInternalTimer();
    }

    await _saveState();
    _emitState();

    // Start background service
    await BackgroundTimerService.startService();
  }

  /// Pause the timer
  Future<void> pause() async {
    if (!_state.isRunning || _state.isPaused) return;

    _timer?.cancel();
    _state = _state.copyWith(isPaused: true, isRunning: false);

    await _saveState();
    _emitState();

    // Note: Keep background service running but it will check isRunning flag
  }

  /// Stop the timer completely
  Future<void> stop() async {
    _timer?.cancel();

    // Stop background service
    await BackgroundTimerService.stopService();

    // Hide overlay if showing
    try {
      await _overlayService.hideOverlay();
    } catch (e) {
      debugPrint('Error hiding overlay: $e');
    }

    _state = const TimerState();

    await _storageService.clearTimerState();
    _emitState();
  }

  /// Start internal countdown timer
  void _startInternalTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_state.remainingTime.inSeconds <= 1) {
        // Timer expired, transition to next phase
        await _transitionPhase();
      } else {
        // Decrement time
        _state = _state.copyWith(
          remainingTime: Duration(seconds: _state.remainingTime.inSeconds - 1),
        );
        await _saveState();
        _emitState();
      }
    });
  }

  /// Transition between screen time and break time
  Future<void> _transitionPhase() async {
    _timer?.cancel();

    if (_state.phase == TimerPhase.screenTime) {
      // Screen time ended, start break time
      _state = TimerState(
        phase: TimerPhase.breakTime,
        remainingTime: _settings.breakTime,
        isRunning: true,
        totalDuration: _settings.breakTime,
      );

      // IMPORTANT: Save state FIRST before showing overlay
      // Overlay reads from SharedPreferences, so data must be ready
      await _saveState();
      _emitState();

      // Show overlay lock screen
      try {
        await _overlayService.showOverlay();
      } catch (e) {
        debugPrint('Error showing overlay: $e');
      }

      _startInternalTimer();
    } else if (_state.phase == TimerPhase.breakTime) {
      // Break time ended, start screen time again
      _state = TimerState(
        phase: TimerPhase.screenTime,
        remainingTime: _settings.screenTime,
        isRunning: true,
        totalDuration: _settings.screenTime,
      );

      // Hide overlay lock screen
      try {
        await _overlayService.hideOverlay();
      } catch (e) {
        debugPrint('Error hiding overlay: $e');
      }

      // Save state and start timer
      await _saveState();
      _emitState();
      _startInternalTimer();
    }
  }

  /// Save current state to storage
  Future<void> _saveState() async {
    await _storageService.saveRemainingTime(_state.remainingTime.inSeconds);
    await _storageService.saveCurrentPhase(_state.phase.index);
    await _storageService.saveIsRunning(_state.isRunning);
  }

  /// Emit current state to stream
  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }
}
