class AppConfig {
  static const String _defaultEnvUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// IP Wi-Fi Laptop di jaringan saat ini
  static const String defaultHostIp = '10.70.0.153';

  static String customUrl = '';

  /// Base URL API Zoom Monitor
  /// Mendukung langsung IP Wi-Fi laptop (192.168.1.101:8080) dan adb reverse (127.0.0.1:8080)
  static String get baseUrl {
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (_defaultEnvUrl.isNotEmpty) {
      return _defaultEnvUrl;
    }
    return 'http://$defaultHostIp:8080/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45); // Zoom API butuh waktu paralel
}
