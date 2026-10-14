import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static Dio createDio(dynamic secureStorage) {
    final storageService = secureStorage is SecureStorageService
        ? secureStorage
        : SecureStorageService(secureStorage is FlutterSecureStorage ? secureStorage : null);

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        secureStorage: storageService,
        dio: dio,
      ),
    );

    return dio;
  }
}
