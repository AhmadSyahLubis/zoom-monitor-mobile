import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../controllers/auth_controller.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pin_dots_indicator.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = '';
  bool _isError = false;
  bool _hasBiometricHardware = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricSupportAndAutoLogin();
    });
  }

  Future<void> _checkBiometricSupportAndAutoLogin() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _hasBiometricHardware = canCheck || isSupported;
        });
      }
    } catch (_) {}

    final prefs = ref.read(preferencesServiceProvider);
    if (prefs.isBiometricEnabled) {
      final success = await ref.read(authStateProvider.notifier).loginWithBiometric();
      if (success && mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  void _handleKey(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _isError = false;
        _pin += digit;
      });

      if (_pin.length == 6) {
        _submitPin();
      }
    }
  }

  void _handleDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _isError = false;
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _submitPin() async {
    final success = await ref.read(authStateProvider.notifier).loginWithPin(_pin);
    if (!mounted) return;

    if (success) {
      final prefs = ref.read(preferencesServiceProvider);
      if (_hasBiometricHardware && !prefs.isBiometricEnabled) {
        final enableBio = await UiFeedback.showConfirmDialog(
          context: context,
          title: 'Aktifkan Sensor Sidik Jari?',
          message: 'Perangkat Anda mendukung sensor sidik jari. Ingin mengaktifkannya sekarang agar bisa login instan berikutnya?',
          confirmLabel: 'Ya, Aktifkan',
          cancelLabel: 'Nanti Saja',
        );
        if (enableBio) {
          await ref.read(authStateProvider.notifier).toggleBiometric(true);
        }
      }

      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } else {
      final authState = ref.read(authStateProvider);
      setState(() {
        _isError = true;
        _pin = '';
      });

      if (authState.isPinLocked) {
        _showPinLockedDialog();
      } else {
        UiFeedback.showError(
          context,
          '${authState.errorMessage ?? "PIN salah"}. Sisa percobaan: ${authState.pinAttemptsRemaining}',
        );
      }
    }
  }

  void _showPinLockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: AppColors.statusMeeting, size: 26),
            SizedBox(width: 8),
            Text('Akses PIN Terkunci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Anda telah salah memasukkan PIN sebanyak 5 kali. PIN terkunci selama 15 menit untuk keamanan akun.\n\nSilakan masuk menggunakan Password Utama Anda.',
          style: TextStyle(fontSize: 14, color: AppColors.textMain),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
            },
            child: const Text('Login dengan Password Utama', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometric() async {
    final prefs = ref.read(preferencesServiceProvider);
    if (!prefs.isBiometricEnabled) {
      UiFeedback.showError(
        context,
        'Sensor sidik jari belum diaktifkan di akun ini. Masukkan 6-digit PIN Anda terlebih dahulu untuk masuk.',
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).loginWithBiometric();
    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      final err = ref.read(authStateProvider).errorMessage;
      if (err != null) UiFeedback.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    final savedUser = prefs.savedUsername ?? 'Pengguna';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang, $savedUser',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan 6-digit PIN keamanan Anda',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),

              // Indikator 6 bulatan PIN
              PinDotsIndicator(
                pinLength: 6,
                currentLength: _pin.length,
                isError: _isError,
              ),
              const SizedBox(height: 36),

              if (authState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                NumericKeypad(
                  onKeyPressed: _handleKey,
                  onDelete: _handleDelete,
                  onBiometric: _handleBiometric,
                  showBiometric: prefs.isBiometricEnabled || _hasBiometricHardware,
                ),

              const SizedBox(height: 28),

              // Fallback to Master Password
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.password_rounded, size: 18, color: AppColors.primary),
                label: const Text(
                  'Gunakan Password Utama',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
