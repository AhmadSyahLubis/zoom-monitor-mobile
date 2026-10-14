class AppConstants {
  static const String appName = 'Zoom Monitor';
  static const String appVersion = '1.0.0';

  // Secure Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyDeviceId = 'device_id';
  static const String keyDeviceName = 'device_name';
  static const String keyUserPin = 'user_pin';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyHasPin = 'has_pin';
  static const String keyUsername = 'saved_username';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45);

  // Timezone
  static const String wibTimezone = 'Asia/Jakarta';
  static const int wibOffsetHours = 7;

  // PIN
  static const int pinLength = 6;
  static const int maxPinAttempts = 5;
  static const int pinLockoutDurationMinutes = 15;
}
