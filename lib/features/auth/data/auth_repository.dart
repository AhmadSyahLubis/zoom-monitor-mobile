import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
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

  AuthRepository(this._dio, this._secureStorage, this._prefs);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final apiRes = ApiResponse<AuthResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        final authData = apiRes.data!;
        await _secureStorage.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        await _secureStorage.saveDeviceId(request.deviceId);
        await _secureStorage.saveDeviceName(request.deviceName);
        await _prefs.setSavedUsername(request.username);
        await _prefs.setHasPin(authData.hasPin);
        await _prefs.setBiometricEnabled(authData.biometricEnabled);

        return authData;
      } else {
        throw AuthException(
          message: apiRes.message.isNotEmpty ? apiRes.message : 'Login gagal',
          errorCode: apiRes.errorCode,
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<AuthResponse> pinLogin(PinLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.pinLogin,
        data: request.toJson(),
      );

      final apiRes = ApiResponse<AuthResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        final authData = apiRes.data!;
        await _secureStorage.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        await _secureStorage.saveDeviceId(request.deviceId);
        await _prefs.setSavedUsername(request.username);
        await _prefs.setHasPin(authData.hasPin);
        await _prefs.setBiometricEnabled(authData.biometricEnabled);

        return authData;
      } else {
        throw AuthException(
          message: apiRes.message.isNotEmpty ? apiRes.message : 'PIN salah',
          errorCode: apiRes.errorCode,
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<bool> setupPin(PinSetupRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.pinSetup,
        data: request.toJson(),
      );

      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        await _prefs.setHasPin(true);
        return true;
      } else {
        throw AuthException(
          message: apiRes.message.isNotEmpty ? apiRes.message : 'Gagal setup PIN',
          errorCode: apiRes.errorCode,
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<String> enableBiometric(String deviceId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.biometricEnable,
        data: {'device_id': deviceId},
      );

      final rootData = response.data as Map<String, dynamic>? ?? {};
      final data = (rootData['data'] is Map<String, dynamic>)
          ? rootData['data'] as Map<String, dynamic>
          : rootData;
      final biometricToken = data['biometric_token'] as String? ??
          rootData['biometric_token'] as String? ??
          '';

      if (biometricToken.isNotEmpty) {
        await _secureStorage.storage.write(key: 'biometric_token', value: biometricToken);
        await _prefs.setBiometricEnabled(true);
      }

      return biometricToken;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<bool> disableBiometric(String deviceId) async {
    try {
      await _dio.post(
        ApiEndpoints.biometricDisable,
        data: {'device_id': deviceId},
      );
      await _secureStorage.storage.delete(key: 'biometric_token');
      await _prefs.setBiometricEnabled(false);
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<AuthResponse> biometricLogin(BiometricLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.biometricLogin,
        data: request.toJson(),
      );

      final apiRes = ApiResponse<AuthResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        final authData = apiRes.data!;
        await _secureStorage.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );
        await _secureStorage.saveDeviceId(request.deviceId);
        await _prefs.setSavedUsername(request.username);
        await _prefs.setHasPin(authData.hasPin);
        await _prefs.setBiometricEnabled(authData.biometricEnabled);

        return authData;
      } else {
        throw AuthException(
          message: apiRes.message.isNotEmpty ? apiRes.message : 'Login Biometrik gagal',
          errorCode: apiRes.errorCode,
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<UserProfile?> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final apiRes = ApiResponse<UserProfile>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        await _prefs.setHasPin(apiRes.data!.hasPin);
        await _prefs.setBiometricEnabled(apiRes.data!.biometricEnabled);
        return apiRes.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      _handleDioError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await _secureStorage.clearAuth();
  }

  void _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final map = e.response!.data as Map<String, dynamic>;
      final message = map['message'] as String? ?? 'Terjadi kesalahan pada server';
      final errorCode = map['error_code'] as String?;
      throw AuthException(
        message: message,
        errorCode: errorCode,
        statusCode: e.response?.statusCode,
      );
    }
    throw AuthException(
      message: e.message ?? 'Koneksi ke server gagal. Pastikan backend aktif.',
      statusCode: e.response?.statusCode,
    );
  }
}
