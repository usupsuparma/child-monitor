import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background service for running timer when app is killed
class BackgroundTimerService {
  /// Start the background timer service
  static Future<void> startService() async {
    final service = FlutterBackgroundService();

    // Configure service if not yet configured
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'child_monitor_timer',
        initialNotificationTitle: 'Child Monitor',
        initialNotificationContent: 'Timer is running',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  /// Stop the background timer service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Timer ticker - runs every second
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    await prefs.reload();

    final isRunning = prefs.getBool('is_running') ?? false;
    final currentPhase = prefs.getInt('current_phase') ?? 0;
    int remainingSeconds = prefs.getInt('remaining_time_seconds') ?? 0;

    if (!isRunning || remainingSeconds <= 0) {
      // Timer not running, just update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Child Monitor',
          content: 'Timer stopped',
        );
      }
      return;
    }

    // Decrement timer
    remainingSeconds--;
    await prefs.setInt('remaining_time_seconds', remainingSeconds);

    // Format time
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Phase name
    final phaseName = currentPhase == 1
        ? 'Screen Time'
        : currentPhase == 2
        ? 'Break Time'
        : 'Idle';

    // Update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '$phaseName - $timeStr',
        content: 'Tap to open Child Monitor',
      );
    }

    // Check if timer expired
    if (remainingSeconds <= 0) {
      await _handlePhaseTransition(prefs, currentPhase);
    }
  });

  // Listen for stop command
  service.on('stop').listen((event) {
    service.stopSelf();
  });
}

/// Handle phase transition in background
Future<void> _handlePhaseTransition(
  SharedPreferences prefs,
  int currentPhase,
) async {
  if (currentPhase == 1) {
    // Screen time ended, start break time
    final breakTimeMinutes = prefs.getInt('break_time_minutes') ?? 5;
    final breakTimeSeconds = breakTimeMinutes * 60;

    await prefs.setInt('current_phase', 2); // breakTime
    await prefs.setInt('remaining_time_seconds', breakTimeSeconds);

    // Show overlay
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (hasPermission) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: WindowSize.fullCover,
          width: WindowSize.fullCover,
        );
      }
    } catch (e) {
      // Ignore overlay errors
    }
  } else if (currentPhase == 2) {
    // Break time ended, start screen time again
    final screenTimeMinutes = prefs.getInt('screen_time_minutes') ?? 30;
    final screenTimeSeconds = screenTimeMinutes * 60;

    await prefs.setInt('current_phase', 1); // screenTime
    await prefs.setInt('remaining_time_seconds', screenTimeSeconds);

    // Hide overlay
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      // Ignore
    }
  }
}
