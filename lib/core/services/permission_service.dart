import 'dart:io';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents a permission with its status
class PermissionInfo {
  final String title;
  final String description;
  final bool isGranted;
  final Future<void> Function() requestPermission;

  const PermissionInfo({
    required this.title,
    required this.description,
    required this.isGranted,
    required this.requestPermission,
  });
}

/// Service for managing app permissions
class PermissionService {
  /// Check if overlay permission is granted
  Future<bool> isOverlayPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission
  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;

    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (hasPermission) return true;

    final granted = await FlutterOverlayWindow.requestPermission();
    return granted ?? false;
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if battery optimization is disabled (ignored)
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  /// Request to disable battery optimization
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final overlay = await isOverlayPermissionGranted();
    final notification = await isNotificationPermissionGranted();
    final battery = await isBatteryOptimizationDisabled();
    return overlay && notification && battery;
  }

  /// Request all permissions at once
  Future<void> requestAllPermissions() async {
    await requestOverlayPermission();
    await requestNotificationPermission();
    await requestDisableBatteryOptimization();
  }

  /// Get list of all permissions with their status
  Future<List<PermissionInfo>> getAllPermissions() async {
    return [
      PermissionInfo(
        title: 'Display Over Other Apps',
        description: 'Required to show the lock screen when break time starts',
        isGranted: await isOverlayPermissionGranted(),
        requestPermission: () async {
          await requestOverlayPermission();
        },
      ),
      PermissionInfo(
        title: 'Notifications',
        description: 'Required to show timer notifications',
        isGranted: await isNotificationPermissionGranted(),
        requestPermission: () async {
          await requestNotificationPermission();
        },
      ),
      PermissionInfo(
        title: 'Ignore Battery Optimization',
        description: 'Required to keep timer running in background',
        isGranted: await isBatteryOptimizationDisabled(),
        requestPermission: () async {
          await requestDisableBatteryOptimization();
        },
      ),
    ];
  }

  /// Get list of missing permissions
  Future<List<PermissionInfo>> getMissingPermissions() async {
    final all = await getAllPermissions();
    return all.where((p) => !p.isGranted).toList();
  }
}
