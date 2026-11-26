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
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/booking/presentation/screens/schedules_screen.dart';
import 'features/booking/presentation/screens/search_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/recording/presentation/screens/recordings_screen.dart';
import 'features/requests/presentation/requests_screen.dart';
import 'features/requests/presentation/request_form_screen.dart';
import 'features/requests/presentation/opd_accounts_screen.dart';
import 'features/requests/presentation/system_health_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, route) {
      final auth = ref.read(authStateProvider);
      final path = route.uri.path;
      if (!auth.isInitialized) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (!auth.isAuthenticated) {
        return path == AppRoutes.login ? null : AppRoutes.login;
      }
      if ([
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.pinLogin,
        AppRoutes.pinSetup
      ].contains(path)) {
        return AppRoutes.dashboard;
      }
      final adminPaths = [
        AppRoutes.search,
        AppRoutes.schedules,
        AppRoutes.recordings,
        AppRoutes.accounts,
        AppRoutes.accountForm,
        AppRoutes.opdAccounts,
        AppRoutes.systemHealth
      ];
      if (adminPaths.contains(path) && auth.user?.isAdmin != true)
        return AppRoutes.requests;
      return null;
    },
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
        redirect: (context, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        redirect: (context, state) => AppRoutes.login,
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
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
          path: AppRoutes.requests,
          pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey, child: const RequestsScreen())),
      GoRoute(
          path: AppRoutes.history,
          pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey, child: const RequestsScreen(history: true))),
      GoRoute(
          path: AppRoutes.requestForm,
          builder: (context, state) => const RequestFormScreen()),
      GoRoute(
          path: AppRoutes.opdAccounts,
          builder: (context, state) => const OpdAccountsScreen()),
      GoRoute(
          path: AppRoutes.systemHealth,
          builder: (context, state) => const SystemHealthScreen()),
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
  ref.listen(authStateProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isInitialized != next.isInitialized) {
      router.refresh();
    }
  });
  ref.onDispose(router.dispose);
  return router;
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
