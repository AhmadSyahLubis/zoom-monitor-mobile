import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  final Dio dio;
  final Dio refreshDio;
  Future<String>? _refresh;
  AuthInterceptor(
      {required this.secureStorage, required this.dio, Dio? refreshDio})
      : refreshDio = refreshDio ??
            Dio(BaseOptions(
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
            ));

  bool _public(String path) => const [
        '/auth/login',
        '/auth/refresh',
        '/auth/biometric/challenge',
        '/auth/biometric/login'
      ].contains(path);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (!options.path.startsWith('/') ||
          options.path.startsWith('//') ||
          options.path.contains('\\')) {
        throw StateError('Endpoint API tidak valid');
      }
      options.baseUrl = AppConfig.baseUrl;
      options.extra.putIfAbsent('authEpoch', () => secureStorage.epoch);
      if (options.extra['authEpoch'] != secureStorage.epoch) {
        throw StateError('Sesi sudah berubah');
      }
      final token = await secureStorage.getAccessToken();
      if (!_public(options.path) && (token == null || token.isEmpty)) {
        throw StateError('Silakan login kembali');
      }
      if (!_public(options.path) && token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
      options.headers.remove('X-Device-ID');
      handler.next(options);
    } catch (e) {
      handler.reject(DioException(
          requestOptions: options, error: e, type: DioExceptionType.cancel));
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra['authEpoch'] != secureStorage.epoch) {
      handler.reject(DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel));
      return;
    }
    handler.next(response);
  }

  Future<String> _refreshOnce(int epoch) async {
    if (_refresh != null) return _refresh!;
    final pending = secureStorage.exclusive(() async {
      if (secureStorage.epoch != epoch) throw StateError('Sesi sudah berubah');
      final token = await secureStorage.getRefreshToken();
      final device = await secureStorage.getDeviceId();
      if (token == null || device == null) {
        throw StateError('Silakan login kembali');
      }
      final response = await refreshDio.post(
          '${AppConfig.baseUrl}/auth/refresh',
          data: {'refresh_token': token, 'device_id': device});
      if (secureStorage.epoch != epoch) throw StateError('Sesi sudah berubah');
      final root = response.data as Map<String, dynamic>;
      final data = root['data'] as Map<String, dynamic>?;
      if (root['success'] != true ||
          data?['access_token'] is! String ||
          data?['refresh_token'] is! String) {
        throw StateError('Respons refresh tidak valid');
      }
      await secureStorage.saveTokens(
          accessToken: data!['access_token'] as String,
          refreshToken: data['refresh_token'] as String);
      return data['access_token'] as String;
    });
    _refresh = pending;
    try {
      return await pending;
    } catch (_) {
      if (secureStorage.epoch == epoch) await secureStorage.clearAuth();
      rethrow;
    } finally {
      if (identical(_refresh, pending)) _refresh = null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (options.extra['authEpoch'] != secureStorage.epoch ||
        _public(options.path) ||
        err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final data = err.response?.data;
    if (data is Map && data['error_code'] == 'AUTH_FAILED') {
      handler.next(err);
      return;
    }
    if (data is! Map ||
        data['error_code'] != 'TOKEN_EXPIRED' ||
        options.extra['authRetry'] == true) {
      await secureStorage.clearAuth();
      handler.next(err);
      return;
    }
    options.extra['authRetry'] = true;
    try {
      final current = await secureStorage.getAccessToken();
      if (options.headers['Authorization'] == 'Bearer $current') {
        await _refreshOnce(secureStorage.epoch);
      }
      if (options.extra['authEpoch'] != secureStorage.epoch) {
        throw StateError('Sesi sudah berubah');
      }
      handler.resolve(await dio.fetch(options));
    } catch (e) {
      handler.next(e is DioException ? e : err);
    }
  }
}
