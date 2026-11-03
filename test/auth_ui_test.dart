import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_monitor_mobile/core/providers/core_providers.dart';
import 'package:zoom_monitor_mobile/core/storage/preferences_service.dart';
import 'package:zoom_monitor_mobile/core/storage/secure_storage_service.dart';
import 'package:zoom_monitor_mobile/core/theme/app_theme.dart';
import 'package:zoom_monitor_mobile/features/auth/data/auth_repository.dart';
import 'package:zoom_monitor_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zoom_monitor_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'auth_security_test.dart' show OfflineAdapter, OfflineBiometrics, reply;

class OfflineUIController extends AuthController {
  final List<String> actions;
  OfflineUIController(
      super.repo, super.storage, super.prefs, super.ref, this.actions);
  @override
  Future<void> checkInitialAuth() async {
    state = AuthState(isInitialized: true);
  }

  @override
  Future<bool> loginWithPassword(
      {required String username, required String password}) async {
    actions.add('password');
    state = AuthState(
        isInitialized: true, errorMessage: 'Login ditolak pada tes offline');
    return false;
  }

  @override
  Future<bool> loginWithBiometric() async {
    actions.add('biometric');
    state = AuthState(
        isInitialized: true,
        errorMessage: 'Biometrik ditolak pada tes offline');
    return false;
  }

  @override
  Future<bool> toggleBiometric(bool enable, {String? currentPassword}) async {
    if (enable && currentPassword != null && currentPassword.isNotEmpty) {
      actions.add('enrollment');
    }
    state = AuthState(
        isInitialized: true,
        errorMessage: 'Pendaftaran ditolak pada tes offline');
    return false;
  }
}

void main() {
  testWidgets(
      'biometric enrollment requires explicit password confirmation and can be cancelled',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final shared = await SharedPreferences.getInstance();
    final storage = SecureStorageService();
    final actions = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://offline.invalid'))
      ..httpClientAdapter = OfflineAdapter((options) async {
        if (options.path != '/dashboard' || options.method != 'GET') {
          fail('Unexpected API request blocked');
        }
        return reply(200, {'success': true, 'data': []});
      });
    addTearDown(dio.close);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(shared),
          secureStorageServiceProvider.overrideWithValue(storage),
          dioClientProvider.overrideWithValue(dio),
          authRepositoryProvider.overrideWithValue(AuthRepository(
              dio, storage, PreferencesService(shared),
              biometrics: OfflineBiometrics())),
          authStateProvider.overrideWith((ref) => OfflineUIController(
              ref.read(authRepositoryProvider),
              storage,
              PreferencesService(shared),
              ref,
              actions)),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const DashboardScreen())));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Keamanan & biometrik'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi password akun'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'offline-password');
    await tester.tap(find.text('Daftarkan perangkat'));
    await tester.pumpAndSettle();
    expect(actions, ['enrollment']);
    expect(find.textContaining('PIN'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets(
      'login validation, password visibility and biometric failure remain usable on narrow screen',
      (tester) async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
        .load();
    for (final entry in {
      'PhosphorRegular': 'Phosphor.ttf',
      'PhosphorBold': 'Phosphor-Bold.ttf',
      'PhosphorFill': 'Phosphor-Fill.ttf'
    }.entries) {
      await (FontLoader('packages/phosphor_icons/${entry.key}')
            ..addFont(rootBundle
                .load('packages/phosphor_icons/lib/fonts/${entry.value}')))
          .load();
    }
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'biometric_enabled': true, 'saved_username': 'offline-account'});
    FlutterSecureStorage.setMockInitialValues({});
    const infoChannel = MethodChannel('dev.fluttercommunity.plus/device_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            infoChannel, (_) async => <String, dynamic>{});
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(infoChannel, null));
    final shared = await SharedPreferences.getInstance();
    final storage = SecureStorageService();
    final paths = <String>[];
    final actions = <String>[];
    final bio = OfflineBiometrics();
    final dio = Dio()
      ..httpClientAdapter = OfflineAdapter((options) async {
        paths.add(options.path);
        fail('Widget tests must not make API requests: ${options.path}');
      });
    addTearDown(dio.close);
    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(shared),
          secureStorageServiceProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(AuthRepository(
              dio, storage, PreferencesService(shared),
              biometrics: bio)),
          authStateProvider.overrideWith((ref) => OfflineUIController(
              ref.read(authRepositoryProvider),
              storage,
              PreferencesService(shared),
              ref,
              actions)),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: RepaintBoundary(key: boundary, child: const LoginScreen()))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk ke Akun'));
    await tester.tap(find.text('Masuk ke Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(paths, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'offline-account');
    await tester.enterText(find.byType(TextFormField).last, 'offline-password');
    await tester.ensureVisible(find.byTooltip('Tampilkan password'));
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse);
    await tester.tap(find.byTooltip('Sembunyikan password'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk ke Akun'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Masuk ke Akun'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    expect(actions, ['password']);
    await tester.pumpAndSettle();
    expect(find.text('Login ditolak pada tes offline'), findsWidgets);
    await tester.ensureVisible(find.text('Masuk dengan biometrik'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Masuk dengan biometrik'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(actions, ['password', 'biometric']);
    expect(paths, isEmpty);
    expect(find.textContaining('PIN'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/security-login.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
