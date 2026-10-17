class AppConfig {
  static const String _defaultEnvUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Base URL bawaan menggunakan localhost port 8080
  /// Bekerja langsung via adb reverse tcp:8080 tcp:8080 di device fisik,
  /// serta di browser web, desktop, dan simulator.
  static const String defaultBaseUrl = 'http://localhost:8080/api/v1';

  static String customUrl = '';

  /// Base URL API Zoom Monitor
  static String get baseUrl {
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (_defaultEnvUrl.isNotEmpty) {
      return _defaultEnvUrl;
    }
    return defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45); // Zoom API butuh waktu paralel
}
