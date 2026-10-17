import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/device_helper.dart';
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
      final user = ref.read(authStateProvider).user;
      if (user != null && !user.hasPin) {
        context.go(AppRoutes.pinSetup);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      final error = ref.read(authStateProvider).errorMessage ?? 'Login gagal';
      UiFeedback.showError(context, error);
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(PhosphorIconsRegular.hardDrives,
                color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Konfigurasi URL API',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih atau masukkan alamat backend server:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL Backend',
                hintText: AppConfig.defaultBaseUrl,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('localhost:8080',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.text = AppConfig.defaultBaseUrl;
                  },
                ),
                ActionChip(
                  label: const Text('127.0.0.1:8080',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.text = 'http://127.0.0.1:8080/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('Emulator 10.0.2.2',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.text = 'http://10.0.2.2:8080/api/v1';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                AppConfig.customUrl = newUrl;
                setState(() {});
                Navigator.of(ctx).pop();
                UiFeedback.showSuccess(
                    context, 'Alamat server diatur ke $newUrl');
              }
            },
            child: const Text('Simpan & Terapkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 150,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/hybrid_desk_login.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.centerRight,
                                excludeFromSemantics: true,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: [
                                      Color(0xD9182640),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 15,
                                bottom: 15,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.asset(
                                        'assets/icons/zoom_monitor_app_icon.png',
                                        width: 36,
                                        height: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    const Text(
                                      'Zoom Monitor',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        'Akses akun dan jadwal rapat perusahaan.',
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
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          prefixIcon: const Icon(PhosphorIconsRegular.lockKey,
                              color: AppColors.textMuted),
                          suffixIcon: IconButton(
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
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: _showServerConfigDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.hardDrives,
                                  size: 17, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Server: ${AppConfig.baseUrl}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(PhosphorIconsRegular.pencilSimple,
                                  size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
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
