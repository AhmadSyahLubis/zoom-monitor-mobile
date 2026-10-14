import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // In-memory cache to eliminate Android Keystore / EncryptedSharedPreferences disk latency
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedDeviceId;
  String? _cachedDeviceName;
  String? _cachedUserPin;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  FlutterSecureStorage get storage => _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: AppConstants.keyAccessToken, value: accessToken),
      _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    _cachedAccessToken = await _storage.read(key: AppConstants.keyAccessToken);
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    return _cachedRefreshToken;
  }

  Future<void> saveDeviceId(String deviceId) async {
    _cachedDeviceId = deviceId;
    await _storage.write(key: AppConstants.keyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId;
    _cachedDeviceId = await _storage.read(key: AppConstants.keyDeviceId);
    return _cachedDeviceId;
  }

  Future<void> saveDeviceName(String name) async {
    _cachedDeviceName = name;
    await _storage.write(key: AppConstants.keyDeviceName, value: name);
  }

  Future<String?> getDeviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName;
    _cachedDeviceName = await _storage.read(key: AppConstants.keyDeviceName);
    return _cachedDeviceName;
  }

  Future<void> saveUserPin(String pin) async {
    _cachedUserPin = pin;
    await _storage.write(key: AppConstants.keyUserPin, value: pin);
  }

  Future<String?> getUserPin() async {
    if (_cachedUserPin != null) return _cachedUserPin;
    _cachedUserPin = await _storage.read(key: AppConstants.keyUserPin);
    return _cachedUserPin;
  }

  Future<void> clearAuth() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserPin = null;
    await Future.wait([
      _storage.delete(key: AppConstants.keyAccessToken),
      _storage.delete(key: AppConstants.keyRefreshToken),
      _storage.delete(key: AppConstants.keyUserPin),
    ]);
  }

  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedDeviceId = null;
    _cachedDeviceName = null;
    _cachedUserPin = null;
    await _storage.deleteAll();
  }
}
