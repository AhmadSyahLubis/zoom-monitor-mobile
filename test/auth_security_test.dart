import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_monitor_mobile/core/network/auth_interceptor.dart';
import 'package:zoom_monitor_mobile/core/security/device_biometrics.dart';
import 'package:zoom_monitor_mobile/core/storage/preferences_service.dart';
import 'package:zoom_monitor_mobile/core/storage/secure_storage_service.dart';
import 'package:zoom_monitor_mobile/features/auth/data/auth_repository.dart';
import 'package:zoom_monitor_mobile/features/auth/data/models/login_request.dart';

class OfflineAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  OfflineAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody reply(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

class OfflineBiometrics extends DeviceBiometrics {
  String? signed;
  int deleted = 0;
  @override
  Future<String> createKey() async => 'offline-public-key';
  @override
  Future<bool> hasKey() async => true;
  @override
  Future<String> sign(String challenge) async {
    signed = challenge;
    return 'offline-signature';
  }

  @override
  Future<void> deleteKey() async {
    deleted++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('legacy tokens and PIN are discarded instead of restored', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'legacy-access',
      'refresh_token': 'legacy-refresh',
      'biometric_token': 'legacy-bio',
      'user_pin': 'legacy-pin'
    });
    final storage = SecureStorageService();
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.storage.read(key: 'biometric_token'), isNull);
    expect(await storage.storage.read(key: 'user_pin'), isNull);
  });

  test('password login saves one token bundle without saving the password',
      () async {
    final storage = SecureStorageService();
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        expect(options.path, '/auth/login');
        expect(options.data['device_id'], 'offline-device');
        return reply(200, {
          'success': true,
          'data': {
            'access_token': 'offline-access',
            'refresh_token': 'offline-refresh',
            'user': {
              'id': 1,
              'username': 'offline-account',
              'name': 'Offline profile'
            }
          }
        });
      });
    final repo =
        AuthRepository(dio, storage, prefs, biometrics: OfflineBiometrics());
    await repo.login(LoginRequest(
        username: 'offline-account',
        password: 'offline-password',
        deviceId: 'offline-device',
        deviceName: 'Offline device'));
    expect(await storage.getAccessToken(), 'offline-access');
    expect(await storage.getDeviceId(), 'offline-device');
    expect(
        (await storage.storage.readAll())
            .values
            .any((value) => value.contains('offline-password')),
        isFalse);
    dio.close();
  });

  test('enrollment sends only public key and explicit password confirmation',
      () async {
    final storage = SecureStorageService();
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final key = OfflineBiometrics();
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        expect(options.path, '/auth/biometric/enable');
        expect(options.data, {
          'device_id': 'offline-device',
          'current_password': 'offline-password',
          'public_key': 'offline-public-key'
        });
        return reply(200, {
          'success': true,
          'data': {'algorithm': 'ES256', 'device_id': 'offline-device'}
        });
      });
    await AuthRepository(dio, storage, prefs, biometrics: key)
        .enableBiometric('offline-device', 'offline-password');
    expect(prefs.isBiometricEnabled, isTrue);
    expect(key.signed, 'zoom-monitor-api:enrollment-check:v1');
    expect(
        (await storage.storage.readAll())
            .values
            .any((value) => value.contains('offline-password')),
        isFalse);
    dio.close();
  });

  test('logout keeps biometric key only after API confirms retention',
      () async {
    for (final retained in [true, false]) {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final storage = SecureStorageService();
      await storage.startSession(
          accessToken: 'offline-access', refreshToken: 'offline-refresh');
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      await prefs.setBiometricEnabled(true);
      await prefs.setSavedUsername('offline-account');
      final key = OfflineBiometrics();
      final dio = Dio()
        ..httpClientAdapter = OfflineAdapter((options) async {
          expect(options.path, '/auth/logout');
          expect(options.data, {'keep_biometric': true});
          return reply(200, {
            'success': true,
            'data': retained ? {'biometric_retained': true} : null,
          });
        });
      await AuthRepository(dio, storage, prefs, biometrics: key).logout();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(prefs.isBiometricEnabled, retained);
      expect(prefs.savedUsername, 'offline-account');
      expect(key.deleted, retained ? 0 : 1);
      dio.close();
    }
  });

  test('concurrent expired requests share a single refresh and token pair',
      () async {
    final storage = SecureStorageService();
    await storage.startSession(
        accessToken: 'old-access', refreshToken: 'old-refresh');
    await storage.saveDeviceId('offline-device');
    var refreshCalls = 0;
    final refresh = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        expect(options.path, endsWith('/auth/refresh'));
        expect(options.data,
            {'refresh_token': 'old-refresh', 'device_id': 'offline-device'});
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return reply(200, {
          'success': true,
          'data': {'access_token': 'new-access', 'refresh_token': 'new-refresh'}
        });
      });
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        expect(options.method, 'GET');
        return options.headers['Authorization'] == 'Bearer old-access'
            ? reply(401, {'error_code': 'TOKEN_EXPIRED'})
            : reply(200, {'success': true});
      });
    dio.interceptors.add(
        AuthInterceptor(secureStorage: storage, dio: dio, refreshDio: refresh));
    final responses =
        await Future.wait(List.generate(8, (_) => dio.get('/dashboard')));
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
    expect(await storage.getRefreshToken(), 'new-refresh');
    dio.close();
    refresh.close();
  });

  test('logout during refresh cannot resurrect credentials', () async {
    final storage = SecureStorageService();
    await storage.startSession(accessToken: 'old', refreshToken: 'refresh');
    await storage.saveDeviceId('device');
    final started = Completer<void>();
    final finish = Completer<void>();
    final refresh = Dio()
      ..httpClientAdapter = OfflineAdapter((_) async {
        started.complete();
        await finish.future;
        return reply(200, {
          'success': true,
          'data': {'access_token': 'late', 'refresh_token': 'late-refresh'}
        });
      });
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter(
          (_) async => reply(401, {'error_code': 'TOKEN_EXPIRED'}));
    dio.interceptors.add(
        AuthInterceptor(secureStorage: storage, dio: dio, refreshDio: refresh));
    final request = dio.get('/dashboard');
    final assertion = expectLater(request, throwsA(isA<DioException>()));
    await started.future;
    await storage.clearAuth();
    finish.complete();
    await assertion;
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    dio.close();
    refresh.close();
  });

  test(
      'revoked sessions never attempt refresh, step-up failure keeps current session',
      () async {
    for (final code in ['SESSION_REVOKED', 'AUTH_FAILED']) {
      final storage = SecureStorageService();
      await storage.startSession(
          accessToken: 'access', refreshToken: 'refresh');
      final dio = Dio()
        ..httpClientAdapter =
            OfflineAdapter((_) async => reply(401, {'error_code': code}));
      final refresh = Dio()
        ..httpClientAdapter = OfflineAdapter((_) async {
          fail('unexpected refresh');
        });
      dio.interceptors.add(AuthInterceptor(
          secureStorage: storage, dio: dio, refreshDio: refresh));
      await expectLater(
          dio.post('/auth/biometric/enable'), throwsA(isA<DioException>()));
      expect(await storage.getAccessToken(),
          code == 'AUTH_FAILED' ? 'access' : null);
      dio.close();
      refresh.close();
    }
  });

  test('biometric login signs server challenge and never sends a static token',
      () async {
    final storage = SecureStorageService();
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final key = OfflineBiometrics();
    final paths = <String>[];
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        paths.add(options.path);
        expect(options.method, 'POST');
        if (options.path == '/auth/biometric/challenge') {
          return reply(200, {
            'success': true,
            'data': {
              'challenge_id': 'offline-challenge-id',
              'challenge': 'exact UTF-8 challenge',
              'algorithm': 'ES256'
            }
          });
        }
        expect(options.path, '/auth/biometric/login');
        expect(options.data, {
          'username': 'offline-account',
          'device_id': 'offline-device',
          'challenge_id': 'offline-challenge-id',
          'signature': 'offline-signature'
        });
        return reply(200, {
          'success': true,
          'data': {
            'access_token': 'offline-access',
            'refresh_token': 'offline-refresh',
            'user': {
              'id': 1,
              'username': 'offline-account',
              'name': 'Offline profile'
            },
            'biometric_enabled': true
          }
        });
      });
    final repo = AuthRepository(dio, storage, prefs, biometrics: key);
    await repo.biometricLogin(
        username: 'offline-account', deviceId: 'offline-device');
    expect(paths, ['/auth/biometric/challenge', '/auth/biometric/login']);
    expect(key.signed, 'exact UTF-8 challenge');
    expect(await storage.storage.read(key: 'biometric_token'), isNull);
    expect(await storage.getAccessToken(), 'offline-access');
    dio.close();
  });
}
