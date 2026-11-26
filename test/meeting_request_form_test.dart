import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_monitor_mobile/core/providers/core_providers.dart';
import 'package:zoom_monitor_mobile/core/widgets/app_glass_nav_bar.dart';
import 'package:zoom_monitor_mobile/features/auth/data/models/user_profile.dart';
import 'package:zoom_monitor_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zoom_monitor_mobile/features/requests/data/meeting_request.dart';
import 'package:zoom_monitor_mobile/features/requests/data/meeting_request_repository.dart';
import 'package:zoom_monitor_mobile/features/requests/presentation/request_form_screen.dart';
import 'package:zoom_monitor_mobile/features/requests/presentation/request_detail_screen.dart';
import 'package:zoom_monitor_mobile/features/requests/presentation/requests_screen.dart';

class _AdminAuth extends AuthController {
  _AdminAuth(super.repo, super.storage, super.prefs, super.ref);
  @override
  Future<void> checkInitialAuth() async {
    state = AuthState(
        isInitialized: true,
        user: UserProfile.fromJson({
          'id': 1,
          'name': 'Admin',
          'username': 'admin',
          'role': 'admin',
          'opd': {
            'id': 1,
            'code': 'diskominfo',
            'name': 'Diskominfo',
            'is_active': true
          },
        }));
  }
}

class _OpdAuth extends AuthController {
  _OpdAuth(super.repo, super.storage, super.prefs, super.ref);
  @override
  Future<void> checkInitialAuth() async {
    state = AuthState(
        isInitialized: true,
        user: UserProfile.fromJson({
          'id': 2,
          'name': 'PIC',
          'username': 'bappeda',
          'role': 'user',
          'opd': {
            'id': 2,
            'code': 'bappeda',
            'name': 'Bappeda',
            'is_active': true
          },
        }));
  }
}

class _Requests extends MeetingRequestRepository {
  _Requests() : super(Dio());
  Map<String, dynamic>? sent;
  Map<String, dynamic>? approved;
  int hostAccessCalls = 0;
  int recordingCalls = 0;
  @override
  Future<List<OpdProfile>> opds() async => [
        const OpdProfile(
            id: 2, code: 'bappeda', name: 'Bappeda', isActive: true),
        for (var i = 3; i <= 43; i++)
          OpdProfile(
              id: i,
              code: 'dinas-$i',
              name: 'Dinas Pemerintahan Kabupaten dan Kota $i',
              isActive: true),
      ];
  @override
  Future<List<MeetingRequest>> list({int page = 1, String? status}) async => [
        MeetingRequest.fromJson({
          'id': 'approved-1',
          'opd_id': 2,
          'opd_name': 'Bappeda',
          'topic': 'Rapat koordinasi',
          'status': 'approved',
          'record_cloud': true,
          'zoom_meeting_id': 123456789,
          'start_time': '2026-11-27T01:00:00Z',
        })
      ];
  @override
  Future<List<MeetingRequest>> history(
          {int page = 1,
          String? search,
          String? startDate,
          String? endDate}) =>
      list();
  @override
  Future<Map<String, dynamic>> hostAccess(String id) async {
    hostAccessCalls++;
    return {
        'meeting_id': 123456789,
        'host_key_available': true,
        'host_key': '123456',
        'join_before_host': true,
        'waiting_room': false,
      };
  }
  @override
  Future<Map<String, dynamic>> recording(String id) async {
    recordingCalls++;
    return {
      'available': true,
      'share_url': 'https://example.zoom.us/rec/share/abc',
      'message': 'Rekaman cloud tersedia.',
    };
  }
  @override
  Future<MeetingRequest> submit(Map<String, dynamic> body, String key) async {
    sent = body;
    return MeetingRequest.fromJson({'id': 'one', 'status': 'pending'});
  }

  @override
  Future<MeetingRequest> get(String id) async => MeetingRequest.fromJson({
        'id': id,
        'opd_id': 2,
        'opd_name': 'Bappeda',
        'topic': 'Rapat',
        'status': 'pending',
        'cluster': '1',
        'revision': 4,
        'capacity': 100,
        'start_time': '2026-11-27T01:00:00Z',
        'end_time': '2026-11-27T05:00:00Z',
      });
  @override
  Future<List<ApprovalOption>> options(String id) async => [
        ApprovalOption.fromJson({
          'account_id': 7,
          'account_name': 'Akun pusat',
          'host_id': 'host-1',
          'host_name': 'Host utama',
          'capacity': 500,
          'cloud_recording': true,
          'eligible': true,
          'reason': 'Tersedia',
          'replace_requests': [
            {'id': 'old-1', 'opd_name': 'OPD lama', 'topic': 'Jadwal lama'},
          ],
        })
      ];
  @override
  Future<void> approve(String id, Map<String, dynamic> body) async {
    approved = body;
  }
}

void main() {
  testWidgets('OPD navigation exposes requests and history without admin pages',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: const Scaffold(
            bottomNavigationBar:
                AppGlassNavBar(currentIndex: 1, isAdmin: false))));
    expect(find.text('Pengajuan'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Rekaman'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'admin request form submits the workflow contract on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Requests();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      meetingRequestRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _AdminAuth(
          ref.read(authRepositoryProvider),
          ref.read(secureStorageServiceProvider),
          ref.read(preferencesServiceProvider),
          ref)),
    ], child: const MaterialApp(home: RequestFormScreen())));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Topik rapat'), 'Rapat koordinasi');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama PIC'), 'Sari');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Telepon PIC'), '081234567890');
    expect(find.text('Dinas Pemerintahan Kabupaten dan Kota 43'), findsNothing);
    await tester.scrollUntilVisible(find.text('Pilih OPD peserta'), 220, scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.text('Pilih OPD peserta')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih OPD peserta'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Cari nama atau kode OPD'), 'Bappeda');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Bappeda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan (1)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Kirim pengajuan'), 220, scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.text('Kirim pengajuan')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim pengajuan'));
    await tester.pumpAndSettle();
    expect(repo.sent?['participant_opd_ids'], [2]);
    expect(repo.sent?['cluster'], '1');
    expect(repo.sent?['priority'], 'normal');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'approved OPD card shows claim host steps and loads key on demand',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Requests();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      meetingRequestRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _OpdAuth(
          ref.read(authRepositoryProvider),
          ref.read(secureStorageServiceProvider),
          ref.read(preferencesServiceProvider),
          ref)),
    ], child: const MaterialApp(home: RequestsScreen())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cara claim host'));
    await tester.tap(find.text('Cara claim host'));
    await tester.pumpAndSettle();
    expect(find.textContaining('More → Enter Host Key to Claim Host'),
        findsOneWidget);
    expect(find.text('123456'), findsNothing);
    expect(repo.hostAccessCalls, 0);
    await tester.tap(find.text('Lihat host key'));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    expect(repo.hostAccessCalls, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('history checks cloud recording only when requested',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Requests();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      meetingRequestRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _OpdAuth(
          ref.read(authRepositoryProvider),
          ref.read(secureStorageServiceProvider),
          ref.read(preferencesServiceProvider),
          ref)),
    ], child: const MaterialApp(home: RequestsScreen(history: true))));
    await tester.pumpAndSettle();
    expect(repo.recordingCalls, 0);
    await Scrollable.ensureVisible(
        tester.element(find.text('Periksa rekaman cloud')),
        alignment: 0.2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Periksa rekaman cloud'));
    await tester.pumpAndSettle();
    expect(repo.recordingCalls, 1);
    expect(find.text('Rekaman cloud tersedia.'), findsOneWidget);
    expect(find.text('Buka rekaman di Zoom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('priority approval requires confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Requests();
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      meetingRequestRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _AdminAuth(
          ref.read(authRepositoryProvider),
          ref.read(secureStorageServiceProvider),
          ref.read(preferencesServiceProvider),
          ref)),
    ], child: const MaterialApp(home: RequestDetailScreen(id: 'new-1'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Periksa dan setujui'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akun pusat · Host utama'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal berikut akan dialihkan:'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Setujui dan buat meeting'))
            .onPressed,
        isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Alasan pengalihan'),
        'Kebutuhan prioritas');
    await tester.tap(find.textContaining('Saya mengonfirmasi pengalihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setujui dan buat meeting'));
    await tester.pumpAndSettle();
    expect(repo.approved?['account_id'], 7);
    expect(repo.approved?['host_id'], 'host-1');
    expect(repo.approved?['replace_request_ids'], ['old-1']);
    expect(repo.approved?['revision'], 4);
    expect(tester.takeException(), isNull);
  });
}
