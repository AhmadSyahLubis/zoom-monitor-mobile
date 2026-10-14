import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService secureStorage;
  final Dio dio;

  AuthInterceptor({required this.secureStorage, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.baseUrl = AppConfig.baseUrl;
    final token = await secureStorage.getAccessToken();
    final deviceId = await secureStorage.getDeviceId();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['X-Device-ID'] = deviceId;
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Jika menerima 401 Unauthorized dan bukan dari endpoint auth itu sendiri
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
      final refreshToken = await secureStorage.getRefreshToken();
      final deviceId = await secureStorage.getDeviceId();

      if (refreshToken != null && deviceId != null) {
        try {
          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          ));

          final response = await refreshDio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
            'device_id': deviceId,
          });

          if (response.statusCode == 200 && response.data['success'] == true) {
            final data = response.data['data'];
            final newAccessToken = data['access_token'] as String;
            final newRefreshToken = data['refresh_token'] as String;

            // Simpan token baru hasil rotasi
            await secureStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Perbarui header request asli dan retry
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Token rotasi gagal / dicabut -> Hapus token lokal untuk paksa login
          await secureStorage.clearAuth();
        }
      }
    }
    return handler.next(err);
  }
}
