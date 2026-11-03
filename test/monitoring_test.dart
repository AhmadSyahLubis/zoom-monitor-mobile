import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/core/models/meeting_monitoring.dart';
import 'package:zoom_monitor_mobile/core/widgets/monitoring_labels.dart';
import 'package:zoom_monitor_mobile/core/widgets/monitoring_refresh.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/schedule_item.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/widgets/meeting_card.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/controllers/schedules_controller.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/screens/schedules_screen.dart';

const overtime = MeetingMonitoring(state: 'live', scheduleKnown: true, labels: [
  MonitoringLabel('overtime', 'Overtime +17 menit'),
  MonitoringLabel('next_meeting_risk',
      'Rapat masih live; jadwal lain pada host ini sudah dekat atau dimulai'),
]);

void main() {
  testWidgets('schedule refresh retains visible cards while the API is pending',
      (tester) async {
    final pending = Completer<SchedulesData>();
    var fetches = 0;
    final meeting = ScheduleItem(
      id: 1,
      meetingId: 9,
      accountId: 2,
      accountName: 'Akun rapat',
      host: 'Host',
      topic: 'Rapat simulasi',
      password: '',
      startTime: '2026-11-03T09:00:00+07:00',
      endTime: '2026-11-03T10:00:00+07:00',
      duration: 60,
      joinUrl: '',
      type: 2,
    );
    final data = SchedulesData(
      liveMeetings: [meeting],
      upcomingMeetings: [],
      pastMeetings: [],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        schedulesProvider.overrideWith((ref) {
          fetches++;
          return fetches == 1 ? Future.value(data) : pending.future;
        }),
      ],
      child: const MaterialApp(home: SchedulesScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Rapat simulasi'), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(SchedulesScreen)));
    container.invalidate(schedulesProvider);
    await tester.pump();
    expect(find.text('Rapat simulasi'), findsOneWidget);
    pending.complete(data);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('polling does not rebuild the page or interrupt active scrolling',
      (tester) async {
    var builds = 0;
    var calls = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
      home: MonitoringRefresh(
        refresh: () async {
          calls++;
        },
        builder: (_) {
          builds++;
          return Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, index) => SizedBox(
                height: 70,
                child: Text('Row $index'),
              ),
            ),
          );
        },
      ),
    ));
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    expect(builds, 1);
    final gesture = await tester.startGesture(const Offset(100, 350));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    expect(builds, 1);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 2);
  });

  testWidgets('automatic refresh waits for the previous request to finish',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
        home: MonitoringRefresh(
            refresh: () {
              calls++;
              return pending.future;
            },
            builder: (_) => const Text('monitor'))));
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 90));
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
  test(
      'freshness uses server observation rather than the device timezone or clock offset',
      () {
    final observed = DateTime.parse('2026-11-02T10:00:00+07:00');
    final server = observed.add(const Duration(seconds: 30));
    final received = DateTime(2030);
    expect(
        monitoringIsStale(observed, server, received,
            now: received.add(const Duration(seconds: 59))),
        isFalse);
    expect(
        monitoringIsStale(observed, server, received,
            now: received.add(const Duration(seconds: 60))),
        isTrue);
    expect(monitoringIsStale(null, server, received, now: received), isTrue);
  });

  test('API schedule and labels are retained without inferring completion', () {
    final data = SchedulesData.fromJson({
      'live_meetings': [
        {
          'meeting_id': 1,
          'start_time': '2026-11-02T09:00:00+07:00',
          'end_time': '2026-11-02T10:00:00+07:00',
          'monitoring': {
            'state': 'live',
            'schedule_known': true,
            'labels': [
              {'code': 'overtime', 'text': 'Overtime +17 menit'}
            ]
          }
        }
      ],
      'past_meetings': [],
      'upcoming_meetings': [],
    });
    expect(data.liveMeetings.single.monitoring?.labels.single.text,
        'Overtime +17 menit');
    expect(data.liveMeetings.single.endTime, '2026-11-02T10:00:00+07:00');
    expect(data.isStale, isTrue);
  });

  testWidgets(
      'meeting labels wrap on a narrow screen with enlarged text and stale labels replace overtime',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget content() => const MaterialApp(
        home: Scaffold(
            body: MediaQuery(
                data: MediaQueryData(
                    size: Size(320, 900), textScaler: TextScaler.linear(2)),
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: MonitoringLabels(monitoring: overtime)))));
    await tester.pumpWidget(content());
    expect(find.text('Overtime +17 menit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: MonitoringLabels(monitoring: overtime, stale: true))));
    expect(find.text('Overtime +17 menit'), findsNothing);
    expect(find.textContaining('Status belum terverifikasi'), findsOneWidget);
  });

  testWidgets('past schedule card does not claim the meeting completed',
      (tester) async {
    final meeting = ScheduleItem(
        id: 1,
        meetingId: 1,
        accountId: 1,
        accountName: 'Akun simulasi',
        host: 'Host simulasi',
        topic: 'Jadwal simulasi',
        password: '',
        startTime: '2026-11-02T09:00:00+07:00',
        endTime: '2026-11-02T10:00:00+07:00',
        duration: 60,
        joinUrl: '',
        type: 2);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(children: [
      MeetingCard(meeting: meeting, type: MeetingCardType.past)
    ]))));
    expect(find.text('JADWAL TERLEWATI'), findsOneWidget);
    expect(find.text('SELESAI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'polling pauses in the background and resumes without overlapping requests',
      (tester) async {
    var calls = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
        home: MonitoringRefresh(
            refresh: () async {
              calls++;
            },
            builder: (_) => const Text('monitor'))));
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 60));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
    expect(calls, 2);
  });
}
