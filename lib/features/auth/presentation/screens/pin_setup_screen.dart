import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../controllers/auth_controller.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pin_dots_indicator.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleKey(String digit) {
    if (!_isConfirming) {
      if (_firstPin.length < 6) {
        setState(() => _firstPin += digit);
        if (_firstPin.length == 6) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) setState(() => _isConfirming = true);
          });
        }
      }
    } else {
      if (_confirmPin.length < 6) {
        setState(() => _confirmPin += digit);
      }
    }
  }

  void _handleDelete() {
    if (!_isConfirming) {
      if (_firstPin.isNotEmpty) {
        setState(() => _firstPin = _firstPin.substring(0, _firstPin.length - 1));
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        setState(() {
          _isConfirming = false;
          _firstPin = '';
        });
      }
    }
  }

  Future<void> _submitPinSetup() async {
    if (_firstPin != _confirmPin) {
      UiFeedback.showError(context, 'Konfirmasi PIN tidak cocok. Silakan ulangi.');
      setState(() {
        _isConfirming = false;
        _firstPin = '';
        _confirmPin = '';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      UiFeedback.showError(context, 'Masukkan password akun saat ini untuk verifikasi.');
      return;
    }

    final success = await ref.read(authStateProvider.notifier).setupPin(
          pin: _confirmPin,
          currentPassword: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      UiFeedback.showSuccess(context, 'PIN 6-Digit berhasil disimpan');
      _promptBiometricDialog();
    } else {
      final error = ref.read(authStateProvider).errorMessage ?? 'Gagal menyimpan PIN';
      UiFeedback.showError(context, error);
    }
  }

  Future<void> _promptBiometricDialog() async {
    final enableBio = await UiFeedback.showConfirmDialog(
      context: context,
      title: 'Aktifkan Biometrik?',
      message: 'Apakah Anda ingin mengaktifkan sensor sidik jari / Face ID untuk login instan di perangkat ini?',
      confirmLabel: 'Ya, Aktifkan',
      cancelLabel: 'Nanti Saja',
    );

    if (enableBio) {
      await ref.read(authStateProvider.notifier).toggleBiometric(true);
    }

    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final activeLength = _isConfirming ? _confirmPin.length : _firstPin.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Setup PIN Keamanan'),
        leading: _isConfirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _isConfirming = false;
                    _confirmPin = '';
                    _firstPin = '';
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _isConfirming ? 'Konfirmasi PIN 6-Digit' : 'Buat PIN 6-Digit Baru',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Masukkan kembali 6 digit PIN yang baru dibuat'
                    : 'PIN digunakan untuk akses cepat tanpa mengetik ulang password utama',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Bulatan Indikator PIN
              PinDotsIndicator(
                pinLength: 6,
                currentLength: activeLength,
              ),
              const SizedBox(height: 24),

              // Field password verifikasi saat tahap konfirmasi selesai 6 digit
              if (_isConfirming && _confirmPin.length == 6) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Konfirmasi Password Akun',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password akun saat ini',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submitPinSetup,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Simpan PIN Baru'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Custom Keypad
              NumericKeypad(
                onKeyPressed: _handleKey,
                onDelete: _handleDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
