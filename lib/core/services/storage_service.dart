import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/timer_settings.dart';

/// Service for persisting app data using SharedPreferences
class StorageService {
  static const String _settingsKey = 'timer_settings';
  static const String _remainingTimeKey = 'remaining_time_seconds';
  static const String _currentPhaseKey = 'current_phase';
  static const String _isRunningKey = 'is_running';
  static const String _screenTimeMinutesKey = 'screen_time_minutes';
  static const String _breakTimeMinutesKey = 'break_time_minutes';

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ========================
  // Timer Settings
  // ========================

  /// Save timer settings
  Future<void> saveSettings(TimerSettings settings) async {
    final json = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, json);

    // Also save individual values for background service
    await prefs.setInt(_screenTimeMinutesKey, settings.screenTime.inMinutes);
    await prefs.setInt(_breakTimeMinutesKey, settings.breakTime.inMinutes);
  }

  /// Load timer settings
  TimerSettings loadSettings() {
    final json = prefs.getString(_settingsKey);
    if (json == null) {
      return const TimerSettings();
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TimerSettings.fromJson(map);
    } catch (e) {
      return const TimerSettings();
    }
  }

  // ========================
  // Timer State (for persistence across app restarts)
  // ========================

  /// Save remaining time in seconds
  Future<void> saveRemainingTime(int seconds) async {
    await prefs.setInt(_remainingTimeKey, seconds);
  }

  /// Load remaining time in seconds
  int loadRemainingTime() {
    return prefs.getInt(_remainingTimeKey) ?? 0;
  }

  /// Save current phase (0=idle, 1=screenTime, 2=breakTime)
  Future<void> saveCurrentPhase(int phase) async {
    await prefs.setInt(_currentPhaseKey, phase);
  }

  /// Load current phase
  int loadCurrentPhase() {
    return prefs.getInt(_currentPhaseKey) ?? 0;
  }

  /// Save running state
  Future<void> saveIsRunning(bool isRunning) async {
    await prefs.setBool(_isRunningKey, isRunning);
  }

  /// Load running state
  bool loadIsRunning() {
    return prefs.getBool(_isRunningKey) ?? false;
  }

  /// Clear timer state (when stopped)
  Future<void> clearTimerState() async {
    await prefs.remove(_remainingTimeKey);
    await prefs.remove(_currentPhaseKey);
    await prefs.remove(_isRunningKey);
  }

  // ========================
  // Background Service helpers
  // ========================

  /// Get screen time in minutes
  int getScreenTimeMinutes() {
    return prefs.getInt(_screenTimeMinutesKey) ?? 30;
  }

  /// Get break time in minutes
  int getBreakTimeMinutes() {
    return prefs.getInt(_breakTimeMinutesKey) ?? 5;
  }

  // ========================
  // Utility Methods
  // ========================

  /// Clear all stored data
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
