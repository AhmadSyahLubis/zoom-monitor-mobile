import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/glass_surface.dart';
import 'features/account/data/models/zoom_account.dart';
import 'features/account/presentation/screens/account_form_screen.dart';
import 'features/account/presentation/screens/accounts_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/pin_login_screen.dart';
import 'features/auth/presentation/screens/pin_setup_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/booking/presentation/screens/schedules_screen.dart';
import 'features/booking/presentation/screens/search_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/recording/presentation/screens/recordings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLogin,
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.schedules,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SchedulesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recordings,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const RecordingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const AccountsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountForm,
        builder: (context, state) {
          final account = state.extra as ZoomAccount?;
          return AccountFormScreen(initialAccount: account);
        },
      ),
    ],
  );
});

class ZoomMonitorApp extends ConsumerWidget {
  const ZoomMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Zoom Monitor',
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          AppBackdrop(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
