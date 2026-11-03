import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/device_helper.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../booking/presentation/controllers/booking_controller.dart';
import '../../../booking/presentation/controllers/schedules_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../recording/presentation/controllers/recording_controller.dart';
import '../../data/auth_repository.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return AuthRepository(dio, secureStorage, prefs);
});

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;
  final bool isPinLocked;
  final int pinAttemptsRemaining;
  final bool isInitialized;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.errorCode,
    this.isPinLocked = false,
    this.pinAttemptsRemaining = 5,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    String? errorCode,
    bool? isPinLocked,
    int? pinAttemptsRemaining,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinAttemptsRemaining: pinAttemptsRemaining ?? this.pinAttemptsRemaining,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SecureStorageService _secureStorage;
  final PreferencesService _prefs;
  final Ref _ref;

  AuthController(this._repo, this._secureStorage, this._prefs, this._ref)
      : super(AuthState()) {
    _secureStorage.onSessionInvalidated = _sessionInvalidated;
    checkInitialAuth();
  }

  void _clearData() {
    ApiCacheManager().clear();
    _ref.invalidate(dashboardAccountsProvider);
    _ref.invalidate(accountsListProvider);
    _ref.invalidate(schedulesProvider);
    _ref.invalidate(recordingsListProvider);
    _ref.invalidate(recordingFilterProvider);
    _ref.invalidate(accountControllerProvider);
    _ref.invalidate(bookingControllerProvider);
    _ref.invalidate(schedulesControllerProvider);
  }

  void _sessionInvalidated() {
    if (!mounted) return;
    _clearData();
    state = AuthState(isInitialized: true);
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _secureStorage.getAccessToken();
      final installationId = await DeviceHelper.getDeviceId();
      if (token != null &&
          await _secureStorage.getDeviceId() != installationId) {
        await _secureStorage.clearAuth();
        await _repo.biometrics.deleteKey();
        await _prefs.setBiometricEnabled(false);
        if (mounted) {
          state = AuthState(isInitialized: true);
        }
        return;
      }
      await _prefs.setHasPin(false);
      final hasKey = await _repo.biometrics.hasKey();
      if (!hasKey) await _prefs.setBiometricEnabled(false);
      if (_prefs.isBiometricEnabled && hasKey) {
        state = AuthState(isInitialized: true);
        return;
      }
      final profile = token == null ? null : await _repo.getMe();
      if (mounted) state = AuthState(user: profile, isInitialized: true);
    } catch (_) {
      if (mounted) {
        state = AuthState(
            isInitialized: true,
            errorMessage:
                'Sesi belum dapat diverifikasi. Silakan login kembali.');
      }
    }
  }

  Future<bool> loginWithPassword(
      {required String username, required String password}) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.login(LoginRequest(
          username: username,
          password: password,
          deviceId: await DeviceHelper.getDeviceId(),
          deviceName: await DeviceHelper.getDeviceName()));
      _clearData();
      state = AuthState(user: result.user, isInitialized: true);
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: e is AuthException
                ? e.message
                : 'Login gagal. Silakan coba lagi.');
      }
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final username = _prefs.savedUsername;
      if (username == null || username.isEmpty) {
        throw AuthException(message: 'Silakan login password terlebih dahulu');
      }
      final result = await _repo.biometricLogin(
          username: username, deviceId: await DeviceHelper.getDeviceId());
      _clearData();
      state = AuthState(user: result.user, isInitialized: true);
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: e is AuthException
                ? e.message
                : 'Biometrik dibatalkan atau tidak tersedia. Gunakan password.');
      }
      return false;
    }
  }

  Future<bool> toggleBiometric(bool enable, {String? currentPassword}) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deviceId = await DeviceHelper.getDeviceId();
      if (enable) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw AuthException(message: 'Konfirmasi password diperlukan');
        }
        await _repo.enableBiometric(deviceId, currentPassword);
      } else {
        await _repo.disableBiometric(deviceId);
      }
      state = state.copyWith(
          isLoading: false,
          user: state.user?.copyWith(biometricEnabled: enable));
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: e is AuthException
                ? e.message
                : 'Biometrik belum dapat diatur. Gunakan perangkat yang mendukung autentikasi aman.');
      }
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    String? error;
    try {
      await _repo.logout();
    } catch (_) {
      error =
          'Keluar di perangkat ini. Pencabutan sesi server belum dapat dikonfirmasi.';
    }
    _clearData();
    if (mounted) state = AuthState(isInitialized: true, errorMessage: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _secureStorage.onSessionInvalidated = null;
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return AuthController(repo, secureStorage, prefs, ref);
});
