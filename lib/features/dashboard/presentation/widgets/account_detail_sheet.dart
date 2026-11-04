import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meeting_monitoring.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/widgets/monitoring_labels.dart';
import '../../data/models/dashboard_account.dart';
import '../controllers/dashboard_controller.dart';
import 'status_badge.dart';

class AccountDetailSheet extends ConsumerStatefulWidget {
  const AccountDetailSheet({
    super.key,
    required this.account,
    required this.onViewSchedule,
  });

  final DashboardAccount account;
  final VoidCallback onViewSchedule;

  @override
  ConsumerState<AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends ConsumerState<AccountDetailSheet> {
  late Future<List<Map<String, dynamic>>> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<List<Map<String, dynamic>>> _loadDetails() {
    final repository = ref.read(dashboardRepositoryProvider);
    return Future.wait([
      repository.getAccountStatus(widget.account.id, forceRefresh: true),
      repository.getAccountSpecs(widget.account.id, forceRefresh: true),
    ]);
  }

  void _retry() => setState(() => _details = _loadDetails());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scaffoldLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neoEdge,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.account.accountName,
                            style: const TextStyle(
                                color: AppColors.textMain,
                                fontSize: 19,
                                fontWeight: FontWeight.w700)),
                        if (widget.account.email?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(widget.account.email!,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup detail akun',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _details,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final status = snapshot.data?.first ?? <String, dynamic>{};
                  final specs = snapshot.data?.last ?? <String, dynamic>{};
                  final hasStatus = status.isNotEmpty;
                  final hasSpecs = specs.isNotEmpty;
                  final observedAt =
                      DateTime.tryParse(status['observed_at'] as String? ?? '');
                  final serverTime =
                      DateTime.tryParse(status['server_time'] as String? ?? '');
                  final statusStale = hasStatus &&
                      monitoringIsStale(observedAt, serverTime, DateTime.now());
                  final isStale =
                      hasStatus ? statusStale : widget.account.isStale;
                  final displayStatus = isStale
                      ? 'error'
                      : (status['status'] as String? ?? widget.account.status);
                  final monitoring =
                      status['monitoring'] is Map<String, dynamic>
                          ? MeetingMonitoring.fromJson(
                              status['monitoring'] as Map<String, dynamic>)
                          : widget.account.monitoring;
                  final topic =
                      status['topic'] as String? ?? widget.account.currentTopic;
                  final host = status['host_name'] as String?;
                  final start = status['start_time'] as String?;
                  final end = status['end_time'] as String?;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!hasStatus || !hasSpecs || snapshot.hasError) ...[
                        ContentSurface(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Detail terbaru belum dapat dimuat. Status terakhir tetap ditampilkan.',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 12),
                                ),
                              ),
                              TextButton(
                                  onPressed: _retry,
                                  child: const Text('Coba lagi')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ContentSurface(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status akun',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 8),
                            StatusBadge(status: displayStatus),
                            const SizedBox(height: 12),
                            MonitoringLabels(
                              monitoring: monitoring,
                              stale: isStale,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ContentSurface(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayStatus == 'scheduled'
                                  ? 'Agenda berikutnya'
                                  : displayStatus == 'meeting'
                                      ? 'Rapat berlangsung'
                                      : 'Aktivitas akun',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              topic?.isNotEmpty == true
                                  ? topic!
                                  : displayStatus == 'error'
                                      ? 'Koneksi akun perlu diperiksa'
                                      : 'Belum ada topik rapat',
                              style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (host?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text('Host: $host',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                            if (start?.isNotEmpty == true ||
                                end?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text('${start ?? '–'} – ${end ?? '–'} WIB',
                                  style: const TextStyle(
                                      color: AppColors.textMain, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ContentSurface(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Spec(
                                  label: 'Kapasitas',
                                  value:
                                      '${specs['meeting_capacity'] ?? widget.account.meetingCapacity} peserta'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Spec(
                                  label: 'Lisensi',
                                  value: specs['plan_type'] as String? ??
                                      widget.account.planType),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: widget.onViewSchedule,
                        child: const Text('Lihat jadwal'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      );
}
