import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/core/network/api_endpoints.dart';
import 'package:zoom_monitor_mobile/features/auth/data/models/user_profile.dart';
import 'package:zoom_monitor_mobile/features/requests/data/meeting_request.dart';
import 'package:zoom_monitor_mobile/features/requests/data/meeting_request_repository.dart';

void main() {
  test('role and OPD identity drive admin access', () {
    final opd = UserProfile.fromJson({
      'id': 2,
      'name': 'OPD',
      'username': 'opd',
      'role': 'user',
      'opd': {'id': 9, 'code': 'bappeda', 'name': 'Bappeda', 'is_active': true}
    });
    final admin = UserProfile.fromJson({
      'id': 1,
      'name': 'Admin',
      'username': 'admin',
      'role': 'admin',
      'opd': {
        'id': 1,
        'code': 'diskominfo',
        'name': 'Diskominfo',
        'is_active': true
      }
    });
    expect(opd.isAdmin, isFalse);
    expect(opd.opd?.id, 9);
    expect(admin.isAdmin, isTrue);
    expect(UserProfile.fromJson(admin.toJson()).isAdmin, isTrue);
  });

  test('request response reads revision, letter, participants, and expiry', () {
    final row = MeetingRequest.fromJson({
      'id': 'req-1',
      'opd_id': 9,
      'topic': 'Rapat',
      'cluster': '2',
      'status': 'expired',
      'revision': 4,
      'participant_opd_ids': [3, 5],
      'participant_others': ['Vendor'],
      'has_request_letter': true,
      'create_attempted': false
    });
    expect(row.canEdit, isTrue);
    expect(row.revision, 4);
    expect(row.participantOpdIds, [3, 5]);
    expect(row.participantOthers, ['Vendor']);
    expect(row.hasLetter, isTrue);
  });

  test('submit and edit use workflow endpoints with stable idempotency key',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://offline.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, data: {
        'success': true,
        'data': {'id': 'req-1', 'status': 'pending', 'revision': 2}
      }));
    }));
    final repo = MeetingRequestRepository(dio);
    final body = {
      'topic': 'Rapat',
      'date': '2026-11-27',
      'cluster': '1',
      'pic_name': 'PIC',
      'pic_phone': '081234567890',
      'capacity': 100,
      'record_cloud': false,
      'participant_opd_ids': [9],
      'participant_others': <String>[],
      'priority': 'normal',
      'request_letter_id': 'letter-1'
    };
    await repo.submit(body, 'same-key');
    expect(requests.last.path, ApiEndpoints.meetingRequests);
    expect(requests.last.method, 'POST');
    expect(requests.last.headers['Idempotency-Key'], 'same-key');
    expect(requests.last.data['request_letter_id'], 'letter-1');
    await repo.edit('req-1', {...body, 'revision': 2}, 'same-key');
    expect(requests.last.path, ApiEndpoints.meetingRequest('req-1'));
    expect(requests.last.method, 'PUT');
    expect(requests.last.headers['Idempotency-Key'], 'same-key');
    expect(requests.last.data['revision'], 2);
  });

  test('admin health uses authenticated diagnostic endpoint', () async {
    RequestOptions? sent;
    final dio = Dio(BaseOptions(baseUrl: 'https://offline.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      sent = options;
      handler.resolve(Response(requestOptions: options, data: {'success': true, 'data': {'status': 'healthy', 'ready': true, 'services': []}}));
    }));
    final result = await MeetingRequestRepository(dio).systemHealth();
    expect(sent?.path, ApiEndpoints.adminHealth);
    expect(result['ready'], isTrue);
  });
}
