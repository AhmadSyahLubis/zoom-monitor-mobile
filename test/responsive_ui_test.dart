import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/features/dashboard/data/models/dashboard_account.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/account_card.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/stats_overview_bar.dart';

void main() {
  testWidgets('dashboard data fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final account = DashboardAccount(
      id: 1,
      accountName: 'Ruang Konferensi Pusat',
      email: 'konferensi.pusat@perusahaan.example',
      status: 'meeting',
      currentTopic: 'Rapat koordinasi lintas divisi',
      meetingCapacity: 300,
      planType: 'Premium',
      lastUpdated: DateTime(2026, 10, 14, 9, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const StatsOverviewBar(
                totalAccounts: 3,
                availableAccounts: 2,
                busyAccounts: 1,
              ),
              const SizedBox(height: 12),
              AccountCard(account: account, onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ruang Konferensi Pusat'), findsOneWidget);
    expect(find.text('Siap dipakai'), findsOneWidget);
  });
}
