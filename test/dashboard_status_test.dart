import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:zoom_monitor_mobile/features/dashboard/data/models/dashboard_account.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/account_detail_sheet.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/stats_overview_bar.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/screens/search_screen.dart';

class _DashboardRepository implements DashboardRepository {
  _DashboardRepository(this.status);

  final Map<String, dynamic> status;

  @override
  Future<List<DashboardAccount>> getDashboard(
          {bool forceRefresh = false}) async =>
      [];

  @override
  Future<Map<String, dynamic>> getAccountStatus(int id,
          {bool forceRefresh = false}) async =>
      status;

  @override
  Future<Map<String, dynamic>> getAccountSpecs(int id,
          {bool forceRefresh = false}) async =>
      {'meeting_capacity': 100, 'plan_type': 'Basic'};
}

void main() {
  testWidgets('meeting time form fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const SearchScreen(),
      ),
    ));

    expect(find.text('Tanggal rapat'), findsOneWidget);
    expect(find.text('Durasi rapat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all dashboard statuses fit on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: const Scaffold(
        body: SingleChildScrollView(
          child: StatsOverviewBar(
            totalAccounts: 4,
            availableAccounts: 1,
            busyAccounts: 1,
            scheduledAccounts: 1,
            errorAccounts: 1,
          ),
        ),
      ),
    ));

    expect(find.text('Terjadwal'), findsOneWidget);
    expect(find.text('Perlu diperiksa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final status in ['scheduled', 'error']) {
    testWidgets('$status account detail stays readable on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final account = DashboardAccount(
        id: 1,
        accountName: 'Akun Zoom',
        status: status,
        currentTopic: status == 'scheduled' ? 'Rapat koordinasi' : null,
        meetingCapacity: 100,
        planType: 'Basic',
        lastUpdated: now,
        serverTime: status == 'scheduled' ? null : now,
      );
      final repository = _DashboardRepository({
        'status': status,
        'topic': status == 'scheduled' ? 'Rapat koordinasi' : null,
        'start_time': status == 'scheduled' ? '09:00' : null,
        'end_time': status == 'scheduled' ? '10:00' : null,
        'observed_at': now.toIso8601String(),
        'server_time': now.toIso8601String(),
      });

      await tester.pumpWidget(ProviderScope(
        overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AccountDetailSheet(
                      account: account,
                      onViewSchedule: () {},
                    ),
                  ),
                  child: const Text('Buka detail'),
                ),
              );
            }),
          ),
        ),
      ));
      await tester.tap(find.text('Buka detail'));
      await tester.pumpAndSettle();

      expect(find.text(status == 'scheduled' ? 'Terjadwal' : 'Perlu diperiksa'),
          findsOneWidget);
      if (status == 'scheduled') {
        expect(find.text('09:00 – 10:00 WIB'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
