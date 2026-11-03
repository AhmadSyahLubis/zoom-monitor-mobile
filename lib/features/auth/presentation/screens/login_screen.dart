import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/device_helper.dart';
import '../../../../core/utils/image_decode_size.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _deviceName = 'Memuat perangkat...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final name = await DeviceHelper.getDeviceName();
    if (mounted) {
      setState(() {
        _deviceName = name;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(authStateProvider.notifier).loginWithPassword(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.dashboard);
    } else {
      final error = ref.read(authStateProvider).errorMessage ?? 'Login gagal';
      UiFeedback.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ContentSurface(
                padding: const EdgeInsets.all(22),
                radius: 24,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/icons/zoom_monitor_app_icon.png',
                              cacheWidth: imageCacheWidth(
                                context,
                                96,
                                maxWidth: 256,
                              ),
                              width: 42,
                              height: 42,
                              semanticLabel: 'Ikon Zoom Monitor',
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Zoom Monitor',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/sumatera-utara.png',
                            width: 29,
                            height: 36,
                            fit: BoxFit.contain,
                            semanticLabel: 'Lambang Provinsi Sumatera Utara',
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pemerintah Provinsi\nSumatera Utara',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 125,
                            height: 30,
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF173D72),
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/kolaborasi-sumut-berkah.png',
                                fit: BoxFit.contain,
                                semanticLabel: 'Kolaborasi Sumut Berkah',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Masuk ke akun Anda',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 27,
                          height: 1.12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Akses akun dan jadwal rapat instansi.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Error Banner jika ada
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusMeetingBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.statusMeeting
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.warningCircle,
                                  color: AppColors.statusMeeting, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(
                                      color: AppColors.statusMeeting,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Username Input
                      const Text(
                        'Username',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textMain),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          hintText: 'Masukkan username',
                          prefixIcon: Icon(PhosphorIconsRegular.user,
                              color: AppColors.textMuted),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Username wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      const Text(
                        'Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textMain),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          prefixIcon: const Icon(PhosphorIconsRegular.lockKey,
                              color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIconsRegular.eyeSlash
                                  : PhosphorIconsRegular.eye,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Tombol Masuk
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Masuk ke Akun',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),

                      const Divider(height: 1),
                      if (ref
                          .watch(preferencesServiceProvider)
                          .isBiometricEnabled)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: OutlinedButton.icon(
                              onPressed: authState.isLoading
                                  ? null
                                  : () async {
                                      final ok = await ref
                                          .read(authStateProvider.notifier)
                                          .loginWithBiometric();
                                      if (context.mounted && ok) {
                                        context.go(AppRoutes.dashboard);
                                      }
                                    },
                              icon:
                                  const Icon(PhosphorIconsRegular.fingerprint),
                              label: const Text('Masuk dengan biometrik'),
                            )),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          const Icon(PhosphorIconsRegular.deviceMobile,
                              size: 17, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Perangkat: $_deviceName',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
