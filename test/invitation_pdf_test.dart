import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/booking_request.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/invitation_data.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/invitation_pdf.dart';
import 'package:zoom_monitor_mobile/features/booking/presentation/widgets/booking_success_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final detail = <String, dynamic>{
    'id': 98765432101,
    'type': 2,
    'topic': 'Rapat Koordinasi Pemerintah Provinsi Sumatera Utara',
    'start_time': '2026-11-04T09:00:00+07:00',
    'duration': 60,
    'password': 'Rapat-2026',
    'join_url': 'https://zoom.us/j/98765432101?pwd=peserta',
  };

  test('invitation uses current Zoom detail and a participant link', () {
    final invitation =
        InvitationData.fromDetail(detail, meetingId: 98765432101);
    expect(invitation.filename, 'Undangan-98765432101-2026-11-04.pdf');
    expect(invitation.endTime.difference(invitation.startTime),
        const Duration(hours: 1));
    expect(
      () => InvitationData.fromDetail(
        {...detail, 'join_url': 'https://zoom.us/s/98765432101?zak=host'},
        meetingId: 98765432101,
      ),
      throwsA(isA<InvitationDataException>()),
    );
  });

  test('recurring invitation selects only the requested occurrence', () {
    final recurring = {
      ...detail,
      'type': 8,
      'occurrences': [
        {
          'occurrence_id': 'first',
          'start_time': '2026-11-04T09:00:00+07:00',
          'duration': 60,
          'status': 'available',
        },
        {
          'occurrence_id': 'second',
          'start_time': '2026-11-11T09:00:00+07:00',
          'duration': 90,
          'status': 'available',
        },
      ],
    };
    final invitation = InvitationData.fromDetail(
      recurring,
      meetingId: 98765432101,
      occurrenceId: 'second',
    );
    expect(invitation.filename, 'Undangan-98765432101-2026-11-11.pdf');
    expect(invitation.endTime.difference(invitation.startTime),
        const Duration(minutes: 90));
    final fromBooking = InvitationData.fromDetail(
      recurring,
      meetingId: 98765432101,
      requestedStart: DateTime.parse('2026-11-11T09:00:00+07:00'),
    );
    expect(fromBooking.filename, invitation.filename);
    expect(
      () => InvitationData.fromDetail(
        recurring,
        meetingId: 98765432101,
        occurrenceId: 'removed',
      ),
      throwsA(isA<InvitationDataException>()),
    );
  });

  test('PDF contains an A4 invitation with a QR and link', () async {
    final invitation =
        InvitationData.fromDetail(detail, meetingId: 98765432101);
    final bytes = await buildInvitationPdf(invitation);
    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    const output = String.fromEnvironment('INVITATION_PDF_OUTPUT');
    if (output.isNotEmpty) await File(output).writeAsBytes(bytes);
  });

  test('long topic fits the invitation page', () async {
    final invitation = InvitationData.fromDetail(
      {...detail, 'topic': List.filled(20, 'Koordinasi').join(' ')},
      meetingId: 98765432101,
    );
    expect(await buildInvitationPdf(invitation), isNotEmpty);
  });

  testWidgets('PDF action remains reachable after booking on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final meeting = BookMeetingResponse(
      id: 98765432101,
      meetingId: 98765432101,
      accountId: 1,
      accountName: 'Akun Zoom',
      topic: 'Rapat Koordinasi',
      startTime: '2026-11-04T09:00:00+07:00',
      duration: 60,
      password: 'Rapat-2026',
      joinUrl: 'https://zoom.us/j/98765432101?pwd=peserta',
    );
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(body: BookingSuccessDialog(meeting: meeting)),
    ));

    expect(find.text('Simpan PDF undangan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
