import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/device_helper.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthController(this._repo, this._secureStorage, this._prefs) : super(AuthState()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isInitialized: true, clearUser: true);
        return;
      }

      final profile = await _repo.getMe();
      if (profile != null) {
        state = state.copyWith(
          user: profile,
          isLoading: false,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          clearUser: true,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        clearUser: true,
      );
    }
  }

  Future<bool> loginWithPassword({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();

      final res = await _repo.login(LoginRequest(
        username: username,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      ));

      state = state.copyWith(
        user: res.user,
        isLoading: false,
        isPinLocked: false,
        pinAttemptsRemaining: 5,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorCode: e.errorCode,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal terhubung ke server',
      );
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final username = _prefs.savedUsername ?? 'admin';
      final deviceId = await DeviceHelper.getDeviceId();

      final res = await _repo.pinLogin(PinLoginRequest(
        username: username,
        pin: pin,
        deviceId: deviceId,
      ));

      state = state.copyWith(
        user: res.user,
        isLoading: false,
        isPinLocked: false,
        pinAttemptsRemaining: 5,
      );
      return true;
    } on AuthException catch (e) {
      final isLocked = e.statusCode == 423 || e.errorCode == 'PIN_LOCKED';
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorCode: e.errorCode,
        isPinLocked: isLocked,
        pinAttemptsRemaining: (state.pinAttemptsRemaining - 1).clamp(0, 5),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal verifikasi PIN',
      );
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        state = state.copyWith(errorMessage: 'Perangkat tidak mendukung sensor sidik jari');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari untuk masuk ke Zoom Monitor',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) return false;

      state = state.copyWith(isLoading: true, clearError: true);
      final username = _prefs.savedUsername ?? 'admin';
      final deviceId = await DeviceHelper.getDeviceId();
      final bioToken = await _secureStorage.storage.read(key: 'biometric_token');

      if (bioToken == null || bioToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Sensor sidik jari belum didaftarkan di server. Silakan masuk via PIN terlebih dahulu.',
        );
        return false;
      }

      final res = await _repo.biometricLogin(BiometricLoginRequest(
        username: username,
        deviceId: deviceId,
        biometricToken: bioToken,
      ));

      state = state.copyWith(
        user: res.user,
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorCode: e.errorCode,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verifikasi sidik jari gagal: $e',
      );
      return false;
    }
  }

  Future<bool> setupPin({
    required String pin,
    required String currentPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.setupPin(PinSetupRequest(
        pin: pin,
        currentPassword: currentPassword,
      ));

      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(hasPin: true),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorCode: e.errorCode,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengatur PIN baru',
      );
      return false;
    }
  }

  Future<bool> toggleBiometric(bool enable) async {
    try {
      final deviceId = await DeviceHelper.getDeviceId();
      if (enable) {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        if (canCheck || isSupported) {
          final didAuth = await _localAuth.authenticate(
            localizedReason: 'Pindai sensor sidik jari Anda untuk konfirmasi aktivasi',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );
          if (!didAuth) return false;
        }

        await _repo.enableBiometric(deviceId);
        if (state.user != null) {
          state = state.copyWith(user: state.user!.copyWith(biometricEnabled: true));
        }
      } else {
        await _repo.disableBiometric(deviceId);
        if (state.user != null) {
          state = state.copyWith(user: state.user!.copyWith(biometricEnabled: false));
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengatur sidik jari: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    ApiCacheManager().clear();
    await _repo.logout();
    state = AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return AuthController(repo, secureStorage, prefs);
});
