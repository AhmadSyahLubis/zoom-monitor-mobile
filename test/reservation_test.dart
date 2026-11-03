import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/availability_result.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/booking_request.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/widgets/reserved_schedule_notice.dart';

void main() {
  test(
      'API confirmation requirement and fallback history label preserve reservation',
      () {
    final result = AvailabilityResult.fromJson(
        {'requires_reservation_confirmation': true, 'status': 'BUSY'});
    expect(result.needsReservationConfirmation, isTrue);
    expect(result.isAvailable, isFalse);
    final fallback = AvailabilityResult.fromJson({
      'status': 'BUSY',
      'conflicting_meeting': {
        'monitoring': {
          'state': 'scheduled',
          'schedule_known': true,
          'labels': [
            {'code': 'previously_live_reserved', 'text': 'Pernah live'}
          ]
        }
      }
    });
    expect(fallback.needsReservationConfirmation, isTrue);
  });

  test(
      'mobile booking sends backend date, time, selected host, and explicit confirmation',
      () {
    final request = BookMeetingRequest(
        accountId: 1,
        bookingUserId: 'offline-host',
        topic: 'Simulasi',
        startTime: '2026-11-03T03:30:00Z',
        duration: 30,
        ignoreConflict: true,
        confirmReservedSchedule: true);
    final json = request.toJson();
    expect(json['date'], '2026-11-03');
    expect(json['time'], '10:30');
    expect(json['booking_user_id'], 'offline-host');
    expect(json['confirm_reserved_schedule'], isTrue);
    final ordinary = BookMeetingRequest(
            accountId: 1,
            topic: 'Simulasi',
            startTime: '2026-11-03T17:15:00Z',
            duration: 30)
        .toJson();
    expect(ordinary['date'], '2026-11-04');
    expect(ordinary['time'], '00:15');
    expect(ordinary['confirm_reserved_schedule'], isFalse);
  });

  testWidgets(
      'reservation notice wraps at narrow width and confirmation requires an action',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var confirmed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
                data: const MediaQueryData(
                    size: Size(320, 900), textScaler: TextScaler.linear(2)),
                child: ListView(children: [
                  ReservedScheduleNotice(
                      onChanged: (value) => confirmed = value)
                ])))));
    expect(confirmed, isFalse);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(Checkbox));
    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
