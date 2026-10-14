import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Mendapatkan Device ID unik yang stabil
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'cached_device_id';
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String deviceId = '';
    try {
      if (kIsWeb) {
        final web = await _deviceInfo.webBrowserInfo;
        deviceId = 'web-${web.userAgent.hashCode.abs()}';
      } else if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        deviceId = android.id.isNotEmpty ? android.id : 'android-${android.model.hashCode.abs()}';
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? 'ios-${ios.name.hashCode.abs()}';
      } else if (Platform.isWindows) {
        final win = await _deviceInfo.windowsInfo;
        deviceId = win.deviceId.isNotEmpty ? win.deviceId : 'win-${win.computerName.hashCode.abs()}';
      } else {
        deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }

    await prefs.setString(key, deviceId);
    return deviceId;
  }

  /// Mendapatkan nama perangkat yang human-readable
  static Future<String> getDeviceName() async {
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
