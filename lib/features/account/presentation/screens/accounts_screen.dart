import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/config/app_routes.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/load_error_state.dart';
import '../../data/models/zoom_account.dart';
import '../controllers/account_controller.dart';
import '../widgets/test_connection_dialog.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _handleTestConnection(
      BuildContext context, WidgetRef ref, ZoomAccount account) async {
    final rawResult = await ref
        .read(accountControllerProvider.notifier)
        .checkConnection(account.id);
    final result = rawResult.accountName.isEmpty
        ? CheckConnectionResponse(
            isConnected: rawResult.isConnected,
            accountName: account.accountName,
            userCount: rawResult.userCount,
            planType: rawResult.planType,
            message: rawResult.message,
          )
        : rawResult;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => TestConnectionDialog(result: result),
      );
    }
  }

  Future<void> _handleDelete(
      BuildContext context, WidgetRef ref, ZoomAccount account) async {
    final confirm = await UiFeedback.showConfirmDialog(
      context: context,
      title: 'Hapus Akun Zoom?',
      message:
          'Apakah Anda yakin ingin menghapus "${account.accountName}"? Seluruh konfigurasi OAuth akan dihapus.',
      confirmLabel: 'Ya, Hapus',
      confirmColor: AppColors.statusMeeting,
    );

    if (confirm) {
      final success = await ref
          .read(accountControllerProvider.notifier)
          .deleteAccount(account.id);
      if (context.mounted) {
        if (success) {
          UiFeedback.showSuccess(context, 'Akun Zoom berhasil dihapus');
        } else {
          UiFeedback.showError(context, 'Gagal menghapus akun');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const AppGlassNavBar(currentIndex: 4),
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: const Text('Akun perusahaan'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ApiCacheManager().invalidate('accounts');
          ref.invalidate(accountsListProvider);
          await ref.read(accountsListProvider.future);
        },
        child: accountsAsync.when(
          data: (accounts) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: accounts.isEmpty ? 2 : accounts.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _buildAccountsHeader(accounts.length),
                  );
                }

                if (accounts.isEmpty) {
                  return const ContentSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Belum ada akun terhubung',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 7),
                        Text(
                            'Tambahkan akun Zoom Premium perusahaan untuk mulai mengelola jadwal, akses, dan rekaman dari satu tempat.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.5)),
                      ],
                    ),
                  );
                }

                final account = accounts[idx - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RepaintBoundary(
                    child: _buildAccountItem(context, ref, account),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => LoadErrorState(
            title: 'Akun belum dapat dimuat',
            onRetry: () => ref.invalidate(accountsListProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.accountForm),
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Tambah Akun',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAccountsHeader(int count) {
    return ContentSurface(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count akun terhubung',
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Kelola koneksi dan akses Zoom Premium dari satu tempat.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(
      BuildContext context, WidgetRef ref, ZoomAccount account) {
    return ContentSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIconsRegular.usersThree,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.accountName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain),
                      ),
                      if (account.email != null && account.email!.isNotEmpty)
                        Text(
                          account.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Akun',
                  icon: const Icon(PhosphorIconsRegular.pencilSimple,
                      size: 20, color: AppColors.textMuted),
                  onPressed: () =>
                      context.push(AppRoutes.accountForm, extra: account),
                ),
                IconButton(
                  tooltip: 'Hapus Akun',
                  icon: const Icon(PhosphorIconsRegular.trash,
                      size: 20, color: AppColors.statusMeeting),
                  onPressed: () => _handleDelete(context, ref, account),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: account.isActive
                        ? AppColors.statusAvailable
                        : AppColors.statusError,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  account.isActive ? 'Aktif' : 'Nonaktif',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ID ${account.zoomAccountId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Tombol Uji Koneksi S2S
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () => _handleTestConnection(context, ref, account),
              icon: const Icon(PhosphorIconsRegular.plugsConnected,
                  size: 18, color: AppColors.primary),
              label: const Text('Uji Koneksi Zoom S2S',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
