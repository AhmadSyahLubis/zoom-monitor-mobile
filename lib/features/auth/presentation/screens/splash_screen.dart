import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineInitialRoute();
    });
  }

  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final secureStorage = ref.read(secureStorageServiceProvider);
    final prefs = ref.read(preferencesServiceProvider);

    final token = await secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    if (prefs.isBiometricEnabled || prefs.hasPin) {
      if (mounted) context.go(AppRoutes.pinLogin);
      return;
    }

    // Cek profil jika tidak ada PIN & biometrik
    final profile = await ref.read(authRepositoryProvider).getMe();
    if (!mounted) return;

    if (profile != null) {
      if (!profile.hasPin) {
        context.go(AppRoutes.pinSetup);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icons/zoom_monitor_app_icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Zoom Monitor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ruang kerja rapat perusahaan',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
