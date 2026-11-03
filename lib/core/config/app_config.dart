import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultEnvUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String defaultBaseUrl =
      'https://zoom-api.sumutcerdas.web.id/api/v1';

  /// Base URL API Zoom Monitor
  static String get baseUrl {
    if (kReleaseMode) {
      return defaultBaseUrl;
    }
    if (_defaultEnvUrl.isNotEmpty) {
      return _defaultEnvUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    return defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout =
      Duration(seconds: 45); // Zoom API butuh waktu paralel
}
