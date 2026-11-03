import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  static const sessionKey = 'session_bundle_v2';
  String? _access;
  String? _refresh;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _tail = Future.value();
  int epoch = 0;
  void Function()? onSessionInvalidated;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                  accessibility: KeychainAccessibility.unlocked_this_device),
            );

  FlutterSecureStorage get storage => _storage;

  Future<T> exclusive<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> _load() async {
    if (_loaded) return;
    return _loading ??= () async {
      final initialEpoch = epoch;
      final raw = await _storage.read(key: sessionKey);
      Map<String, dynamic>? bundle;
      try {
        if (raw != null) bundle = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        bundle = null;
      }
      if (initialEpoch == epoch) {
        final access = bundle?['access_token'];
        final refresh = bundle?['refresh_token'];
        final valid = access is String &&
            access.isNotEmpty &&
            refresh is String &&
            refresh.isNotEmpty;
        _access = valid ? access : null;
        _refresh = valid ? refresh : null;
        _loaded = true;
        if (!valid && raw != null) {
          await _storage.delete(key: sessionKey);
        }
      }
      for (final key in [
        'access_token',
        'refresh_token',
        'biometric_token',
        'user_pin'
      ]) {
        await _storage.delete(key: key);
      }
    }();
  }

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Respons token tidak valid');
    }
    final before = epoch;
    await _storage.write(
        key: sessionKey,
        value: jsonEncode(
            {'access_token': accessToken, 'refresh_token': refreshToken}));
    if (before != epoch) {
      await _storage.delete(key: sessionKey);
      throw StateError('Sesi sudah berubah');
    }
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
  }

  Future<void> startSession(
      {required String accessToken, required String refreshToken}) async {
    epoch++;
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<String?> getAccessToken() async {
    await _load();
    return _access;
  }

  Future<String?> getRefreshToken() async {
    await _load();
    return _refresh;
  }

  Future<void> saveDeviceId(String value) =>
      _storage.write(key: AppConstants.keyDeviceId, value: value);
  Future<String?> getDeviceId() => _storage.read(key: AppConstants.keyDeviceId);
  Future<void> saveDeviceName(String value) =>
      _storage.write(key: AppConstants.keyDeviceName, value: value);
  Future<String?> getDeviceName() =>
      _storage.read(key: AppConstants.keyDeviceName);

  Future<void> clearAuth() async {
    epoch++;
    _access = null;
    _refresh = null;
    _loaded = true;
    onSessionInvalidated?.call();
    await _storage.delete(key: sessionKey);
    for (final key in [
      'access_token',
      'refresh_token',
      'biometric_token',
      'user_pin'
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<void> clearAll() async {
    await clearAuth();
    await _storage.deleteAll();
  }
}
