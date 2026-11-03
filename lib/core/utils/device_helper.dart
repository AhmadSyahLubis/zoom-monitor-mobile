import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static Future<String>? _installationId;

  /// Mendapatkan Device ID unik yang stabil
  static Future<String> getDeviceId() async {
    return _installationId ??= _createInstallationId();
  }

  static Future<String> _createInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'installation_device_id_v2';
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final random = Random.secure();
    final deviceId =
        'mobile-${List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

    await prefs.setString(key, deviceId);
    await prefs.remove('cached_device_id');
    return deviceId;
  }

  /// Mendapatkan nama perangkat yang human-readable
  static Future<String> getDeviceName() async {
    return _readDeviceName()
        .timeout(const Duration(seconds: 2), onTimeout: () => 'Flutter Device');
  }

  static Future<String> _readDeviceName() async {
    try {
      if (kIsWeb) {
        final web = await _deviceInfo.webBrowserInfo;
        return 'Web Browser (${web.browserName.name})';
      } else if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        return '${android.brand.toUpperCase()} ${android.model}';
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        return ios.utsname.machine;
      } else if (Platform.isWindows) {
        final win = await _deviceInfo.windowsInfo;
        return 'Windows PC (${win.computerName})';
      }
    } catch (_) {}
    return 'Flutter Device';
  }
}
