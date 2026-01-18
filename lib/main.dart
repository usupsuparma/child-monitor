import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/services.dart';
import 'features/lock_screen/presentation/lock_overlay.dart';

/// Main entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final overlayService = OverlayService();
  final permissionService = PermissionService();

  final timerService = TimerService(
    storageService: storageService,
    overlayService: overlayService,
  );
  await timerService.init();

  // If timer was running before (e.g., after reboot), auto-start it
  if (timerService.state.isRunning || storageService.loadIsRunning()) {
    // Timer will auto-resume from init()
    debugPrint('Timer auto-resumed from saved state');
  }

  runApp(
    ChildMonitorApp(
      storageService: storageService,
      timerService: timerService,
      permissionService: permissionService,
      overlayService: overlayService,
    ),
  );
}

/// Overlay entry point
/// This is called when the overlay is shown
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LockOverlay()),
  );
}
