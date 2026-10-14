import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import 'package:local_auth/local_auth.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/account_card.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/stats_overview_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final dashboardState = ref.watch(dashboardAccountsProvider);
    final user = authState.user;
    final userName =
        user?.name.isNotEmpty == true ? user!.name : 'Administrator';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/zoom_monitor_app_icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Zoom Monitor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          GlassIconButton(
            icon: PhosphorIconsRegular.magnifyingGlass,
            tooltip: 'Cari Ruang Kosong',
            onPressed: () => context.push(AppRoutes.search),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            icon: const Icon(PhosphorIconsRegular.dotsThree, size: 23),
            onSelected: (action) async {
              if (action == 'security') {
                _showSecurityModal(context, ref);
              } else if (action == 'logout') {
                await _logout(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'security',
                child: Text('Keamanan & biometrik'),
              ),
              PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(dashboardAccountsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHero(
                      userName: userName,
                      onSearch: () => context.push(AppRoutes.search),
                    ),
                    if (!dashboardState.hasError) ...[
                      const SizedBox(height: 18),
                      RepaintBoundary(
                        child: dashboardState.when(
                          data: (accounts) {
                            final total = accounts.length;
                            final available = accounts
                                .where((a) => a.status == 'available')
                                .length;
                            final busy = accounts
                                .where((a) =>
                                    a.status == 'meeting' ||
                                    a.status == 'in_meeting' ||
                                    a.status == 'busy')
                                .length;
                            return StatsOverviewBar(
                              totalAccounts: total,
                              availableAccounts: available,
                              busyAccounts: busy,
                            );
                          },
                          loading: () => _buildShimmerBar(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 26),

                    // Section Title & Quick Nav
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status akun',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.accounts),
                          child: const Text('Lihat semua',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // List Akun Zoom (Virtualised via SliverList)
            dashboardState.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                      child: _buildEmptyState(context),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  sliver: SliverList.separated(
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) => RepaintBoundary(
                      child: AccountCard(
                        account: accounts[idx],
                        onTap: () => context.push(AppRoutes.schedules),
                      ),
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  child: _buildShimmerList(),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  child: ContentSurface(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(PhosphorIconsRegular.warningCircle,
                            size: 36, color: AppColors.statusMeeting),
                        const SizedBox(height: 8),
                        const Text(
                          'Akun belum dapat dimuat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Periksa koneksi lalu coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(dashboardAccountsProvider.notifier)
                              .refresh(),
                          child: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppGlassNavBar(currentIndex: 0),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: PhosphorIconsRegular.usersThree,
      title: 'Belum Ada Akun Zoom Terhubung',
      message:
          'Tambahkan akun Zoom Server-to-Server (S2S) untuk memulai monitoring otomatis.',
      action: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.accountForm),
        icon: const Icon(PhosphorIconsBold.plus, size: 18),
        label: const Text('Tambah Akun Zoom'),
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await UiFeedback.showConfirmDialog(
      context: context,
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin keluar dari Zoom Monitor?',
      confirmLabel: 'Ya, Keluar',
      confirmColor: AppColors.statusMeeting,
    );
    if (confirm) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  void _showSecurityModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final prefs = ref.watch(preferencesServiceProvider);
          final user = ref.watch(authStateProvider).user;
          final isBioEnabled = prefs.isBiometricEnabled;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(PhosphorIconsFill.shieldCheck,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keamanan & Biometrik',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain),
                              ),
                              Text(
                                user?.username != null
                                    ? '@${user!.username}'
                                    : 'Zoom Monitor Enterprise',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Switch Biometrik
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isBioEnabled
                                  ? AppColors.primaryLight
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIconsFill.fingerprint,
                              color: isBioEnabled
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Login Sensor Sidik Jari',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textMain),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBioEnabled
                                      ? 'Aktif, buka aplikasi tanpa PIN'
                                      : 'Nonaktif, memerlukan PIN 6 digit',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isBioEnabled
                                          ? AppColors.primary
                                          : AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isBioEnabled,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryLight,
                            onChanged: (val) async {
                              final ok = await ref
                                  .read(authStateProvider.notifier)
                                  .toggleBiometric(val);
                              if (ctx.mounted) {
                                if (ok) {
                                  UiFeedback.showSuccess(
                                    context,
                                    val
                                        ? 'Sensor sidik jari berhasil diaktifkan!'
                                        : 'Sensor sidik jari dinonaktifkan',
                                  );
                                } else {
                                  final err = ref
                                          .read(authStateProvider)
                                          .errorMessage ??
                                      'Gagal mengubah status biometrik';
                                  UiFeedback.showError(context, err);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tombol Uji Sensor Sidik Jari
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(PhosphorIconsBold.fingerprint,
                          color: AppColors.primary, size: 20),
                      label: const Text(
                        'Uji Sensor Sidik Jari Sekarang',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      onPressed: () async {
                        try {
                          final localAuth = LocalAuthentication();
                          final didAuth = await localAuth.authenticate(
                            localizedReason:
                                'Pindai sensor sidik jari Anda untuk uji fungsi',
                            options: const AuthenticationOptions(
                                biometricOnly: false, stickyAuth: true),
                          );
                          if (context.mounted) {
                            if (didAuth) {
                              UiFeedback.showSuccess(context,
                                  'Sensor sidik jari berfungsi normal!');
                            } else {
                              UiFeedback.showError(context,
                                  'Verifikasi sidik jari dibatalkan/gagal');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            UiFeedback.showError(
                                context, 'Sensor tidak dapat dipindai: $e');
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // Tombol Ubah PIN
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(PhosphorIconsBold.key,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Ganti PIN 6-Digit',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push(AppRoutes.pinSetup);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
