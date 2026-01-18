/// App string constants for Child Monitor app
class AppStrings {
  AppStrings._();

  // App info
  static const String appName = 'Child Monitor';
  static const String appDescription = 'Manage your child\'s screen time';

  // Timer phases
  static const String screenTimeLabel = 'Screen Time';
  static const String breakTimeLabel = 'Break Time';
  static const String idleLabel = 'Idle';

  // Button labels
  static const String startButton = 'Start';
  static const String stopButton = 'Stop';
  static const String pauseButton = 'Pause';
  static const String resumeButton = 'Resume';
  static const String settingsButton = 'Settings';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String screenTimeDuration = 'Screen Time Duration';
  static const String breakTimeDuration = 'Break Time Duration';
  static const String soundEnabled = 'Sound Notification';
  static const String vibrationEnabled = 'Vibration';
  static const String permissionsTitle = 'Permissions';

  // Permissions
  static const String overlayPermissionTitle = 'Display Over Other Apps';
  static const String overlayPermissionDesc =
      'Required to show lock screen when break time starts';
  static const String notificationPermissionTitle = 'Notifications';
  static const String notificationPermissionDesc =
      'Required to show timer notifications';
  static const String grantPermission = 'Grant Permission';
  static const String permissionGranted = 'Granted';

  // Lock screen
  static const String lockScreenTitle = 'Break Time!';
  static const String lockScreenMessage =
      'Time for a break. The screen will unlock in:';
  static const String lockScreenMotivation =
      'Rest your eyes and relax for a moment 😊';

  // Status messages
  static const String timerRunning = 'Timer is running';
  static const String timerPaused = 'Timer is paused';
  static const String timerIdle = 'Tap Start to begin';
  static const String screenTimeActive = 'Screen time is active';
  static const String breakTimeActive = 'Break time is active';

  // Error messages
  static const String permissionRequired =
      'Please grant the required permissions to use this app';
  static const String overlayPermissionRequired =
      'Overlay permission is required to show the lock screen';

  // Time formats
  static const String minutesLabel = 'min';
  static const String secondsLabel = 'sec';
}
