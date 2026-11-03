import 'package:flutter/services.dart';

class DeviceBiometrics {
  static const channel = MethodChannel('zoom_monitor/device_biometrics_v2');

  Future<bool> hasKey() async {
    try {
      return await channel.invokeMethod<bool>('hasKey') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<String> createKey() async {
    final value = await channel.invokeMethod<String>('createKey');
    if (value == null || value.isEmpty) {
      throw StateError('Kunci perangkat tidak tersedia');
    }
    return value;
  }

  Future<String> sign(String challenge) async {
    final value =
        await channel.invokeMethod<String>('sign', {'challenge': challenge});
    if (value == null || value.isEmpty) {
      throw StateError('Verifikasi biometrik dibatalkan');
    }
    return value;
  }

  Future<void> deleteKey() async {
    try {
      await channel.invokeMethod<void>('deleteKey');
    } on MissingPluginException {
      /* Password login remains available on unsupported platforms. */
    }
  }
}
