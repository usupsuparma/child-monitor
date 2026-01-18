import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Service for managing overlay window (lock screen)
class OverlayService {
  /// Check if overlay permission is granted
  Future<bool> hasOverlayPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission
  /// Returns true if permission was granted
  Future<bool> requestOverlayPermission() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (hasPermission) {
      return true;
    }

    // This opens the system settings for overlay permission
    final granted = await FlutterOverlayWindow.requestPermission();
    return granted ?? false;
  }

  /// Show the lock screen overlay
  Future<void> showOverlay() async {
    final hasPermission = await hasOverlayPermission();
    if (!hasPermission) {
      throw Exception('Overlay permission not granted');
    }

    // Check if overlay is already showing
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) {
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: 'Child Monitor',
      overlayContent: 'Break Time Active',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
      startPosition: const OverlayPosition(0, 0),
    );
  }

  /// Hide the lock screen overlay
  Future<void> hideOverlay() async {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  /// Check if overlay is currently visible
  Future<bool> isOverlayActive() async {
    return await FlutterOverlayWindow.isActive();
  }

  /// Resize the overlay (useful for different states)
  Future<void> resizeOverlay(int width, int height) async {
    await FlutterOverlayWindow.resizeOverlay(width, height, true);
  }
}
