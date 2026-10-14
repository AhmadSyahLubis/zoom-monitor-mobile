import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/features/dashboard/data/models/dashboard_account.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/account_card.dart';
import 'package:zoom_monitor_mobile/features/dashboard/presentation/widgets/stats_overview_bar.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/schedule_item.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/widgets/meeting_card.dart';

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

  testWidgets('meeting card actions and time fit narrow screen without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final meeting = ScheduleItem(
      id: 1,
      meetingId: 98765432101,
      accountId: 1,
      accountName: 'Zoom Account Enterprise VIP Room 01',
      host: 'Admin',
      topic: 'Rapat Koordinasi Operasional Nasional dan Evaluasi Bulanan',
      startTime: '2026-10-14T07:00:00Z',
      endTime: '2026-10-14T15:00:00Z',
      duration: 480,
      password: 'password123',
      joinUrl: 'https://zoom.us/j/98765432101',
      type: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MeetingCard(
                meeting: meeting,
                type: MeetingCardType.upcoming,
                onEditMeeting: () {},
                onDeleteMeeting: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Gabung Zoom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
