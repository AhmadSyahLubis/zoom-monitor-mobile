import 'package:flutter/material.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/utils/date_time_util.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemHealthScreen extends ConsumerStatefulWidget {
  const SystemHealthScreen({super.key});
  @override
  ConsumerState<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends ConsumerState<SystemHealthScreen> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => setState(
      () => future = ref.read(meetingRequestRepositoryProvider).systemHealth());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            flexibleSpace: const GlassAppBarBackground(),
            title: const Text('Status layanan')),
        body: RefreshIndicator(
            onRefresh: () async {
              reload();
              await future.then<void>((_) {}, onError: (Object _) {});
            },
            child: FutureBuilder<Map<String, dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final services = asList(data?['services'], asMap);
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    if (!snapshot.hasData)
                      snapshot.hasError
                          ? ContentSurface(
                              child: Column(children: [
                              Text(requestError(snapshot.error!)),
                              TextButton(
                                  onPressed: reload,
                                  child: const Text('Coba lagi'))
                            ]))
                          : const Center(child: CircularProgressIndicator())
                    else ...[
                      ContentSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                data!['status'] == 'healthy'
                                    ? 'Semua layanan terhubung'
                                    : data['status'] == 'degraded'
                                        ? 'Sebagian layanan perlu perhatian'
                                        : 'Layanan utama bermasalah',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                                'Diperiksa: ${DateTimeUtil.formatWib(asText(data['checked_at']))}\nUptime: ${Duration(seconds: asInt(data['uptime_seconds'])).inHours} jam'),
                          ])),
                      const SizedBox(height: 12),
                      for (final service in services) ...[
                        ContentSurface(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(asText(service['name']).toUpperCase(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                  '${_serviceStatus(asText(service['status']))} · ${asText(service['message'])}'),
                              if (service['status'] != 'not_configured')
                                Text(
                                    'Latensi: ${asInt(service['latency_ms'])} ms'),
                            ])),
                        const SizedBox(height: 10),
                      ],
                      const Text(
                          'Status koneksi tidak memverifikasi migrasi tabel dan izin penyimpanan surat. Periksa log server jika ada masalah.'),
                    ],
                  ]);
                })),
      );
}

String _serviceStatus(String value) => switch (value) {
      'healthy' => 'Terhubung',
      'unhealthy' => 'Bermasalah',
      'not_configured' => 'Belum dikonfigurasi',
      _ => value,
    };
