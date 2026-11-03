import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/security/device_biometrics.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'models/auth_response.dart';
import 'models/login_request.dart';
import 'models/user_profile.dart';

class AuthException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;
  AuthException({required this.message, this.errorCode, this.statusCode});
  @override
  String toString() => message;
}

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final PreferencesService _prefs;
  final DeviceBiometrics biometrics;
  AuthRepository(this._dio, this._secureStorage, this._prefs,
      {DeviceBiometrics? biometrics})
      : biometrics = biometrics ?? DeviceBiometrics();

  Future<AuthResponse> _accept(
      Response response, String username, int epoch) async {
    if (_secureStorage.epoch != epoch) {
      throw AuthException(message: 'Sesi sudah berubah');
    }
    final root = response.data as Map<String, dynamic>;
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw AuthException(message: 'Respons login tidak valid');
    }
    final data = AuthResponse.fromJson(root['data'] as Map<String, dynamic>);
    if (data.accessToken.isEmpty ||
        data.refreshToken.isEmpty ||
        data.user.id == 0) {
      throw AuthException(message: 'Respons login tidak lengkap');
    }
    await _secureStorage.startSession(
        accessToken: data.accessToken, refreshToken: data.refreshToken);
    await _prefs.setSavedUsername(username);
    await _prefs.setHasPin(false);
    await _prefs.setBiometricEnabled(
        data.biometricEnabled && await biometrics.hasKey());
    return data;
  }

  Future<AuthResponse> login(LoginRequest request) =>
      _secureStorage.exclusive(() async {
        final epoch = _secureStorage.epoch;
        try {
          final response =
              await _dio.post(ApiEndpoints.login, data: request.toJson());
          await _secureStorage.saveDeviceId(request.deviceId);
          await _secureStorage.saveDeviceName(request.deviceName);
          return await _accept(response, request.username, epoch);
        } on DioException catch (e) {
          throw _error(e);
        }
      });

  Future<void> enableBiometric(String deviceId, String password) async {
    try {
      final publicKey = await biometrics.createKey();
      // Confirm the new key can perform a biometric-gated operation before registering it.
      await biometrics.sign('zoom-monitor-api:enrollment-check:v1');
      final response = await _dio.post(ApiEndpoints.biometricEnable, data: {
        'device_id': deviceId,
        'current_password': password,
        'public_key': publicKey
      });
      if (response.data is! Map || response.data['success'] != true) {
        throw AuthException(message: 'Pendaftaran biometrik gagal');
      }
      await _prefs.setBiometricEnabled(true);
    } catch (e) {
      await biometrics.deleteKey();
      await _prefs.setBiometricEnabled(false);
      if (e is DioException) throw _error(e);
      rethrow;
    }
  }

  Future<bool> disableBiometric(String deviceId) async {
    try {
      await _dio
          .post(ApiEndpoints.biometricDisable, data: {'device_id': deviceId});
      await biometrics.deleteKey();
      await _prefs.setBiometricEnabled(false);
      return true;
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  Future<AuthResponse> biometricLogin(
          {required String username, required String deviceId}) =>
      _secureStorage.exclusive(() async {
        final epoch = _secureStorage.epoch;
        try {
          if (!await biometrics.hasKey()) {
            throw AuthException(
                message: 'Daftarkan biometrik setelah login password');
          }
          final response = await _dio.post(ApiEndpoints.biometricChallenge,
              data: {'username': username, 'device_id': deviceId});
          final root = response.data as Map<String, dynamic>;
          final data = root['data'] as Map<String, dynamic>?;
          if (root['success'] != true ||
              data?['algorithm'] != 'ES256' ||
              data?['challenge_id'] is! String ||
              data?['challenge'] is! String) {
            throw AuthException(message: 'Tantangan perangkat tidak valid');
          }
          final signature = await biometrics.sign(data!['challenge'] as String);
          if (_secureStorage.epoch != epoch) {
            throw AuthException(message: 'Sesi sudah berubah');
          }
          final signed = await _dio.post(ApiEndpoints.biometricLogin,
              data: BiometricLoginRequest(
                      username: username,
                      deviceId: deviceId,
                      challengeId: data['challenge_id'] as String,
                      signature: signature)
                  .toJson());
          return await _accept(signed, username, epoch);
        } on DioException catch (e) {
          throw _error(e);
        }
      });

  Future<UserProfile?> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      if (response.data is! Map ||
          response.data['success'] != true ||
          response.data['data'] is! Map<String, dynamic>) {
        return null;
      }
      final user =
          UserProfile.fromJson(response.data['data'] as Map<String, dynamic>);
      await _prefs.setHasPin(false);
      await _prefs.setBiometricEnabled(
          user.biometricEnabled && await biometrics.hasKey());
      return user.id > 0 ? user : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw _error(e);
    }
  }

  Future<void> logout() async {
    final keepBiometric =
        _prefs.isBiometricEnabled && await biometrics.hasKey();
    var confirmedRetained = false;
    try {
      final response = await _dio
          .post(ApiEndpoints.logout, data: {'keep_biometric': keepBiometric});
      final root = response.data;
      confirmedRetained = keepBiometric &&
          root is Map &&
          root['success'] == true &&
          root['data'] is Map &&
          root['data']['biometric_retained'] == true;
    } finally {
      await _secureStorage.clearAuth();
      if (!confirmedRetained) {
        await _prefs.setBiometricEnabled(false);
        await biometrics.deleteKey();
      }
    }
  }

  AuthException _error(DioException error) {
    final data = error.response?.data;
    return AuthException(
        message: data is Map && data['message'] is String
            ? data['message'] as String
            : 'Koneksi gagal. Silakan coba lagi.',
        errorCode: data is Map ? data['error_code'] as String? : null,
        statusCode: error.response?.statusCode);
  }
}
