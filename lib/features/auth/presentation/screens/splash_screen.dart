import 'package:flutter/material.dart';
import '../../../../core/utils/image_decode_size.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_routes.dart';

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
    final auth = ref.read(authStateProvider);
    if (auth.isInitialized) {
      context.go(auth.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login);
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/icons/zoom_monitor_app_icon.png',
                  cacheWidth: imageCacheWidth(context, 84, maxWidth: 256),
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
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
