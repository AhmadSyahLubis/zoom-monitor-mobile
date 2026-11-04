import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/core/config/app_config.dart';
import 'package:zoom_monitor_mobile/features/account/data/models/zoom_account.dart';
import 'package:zoom_monitor_mobile/features/booking/data/booking_repository.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/booking_request.dart';

void main() {
  test('default API uses the HTTPS Zoom Monitor endpoint', () {
    expect(AppConfig.defaultBaseUrl,
        'https://zoom-api.sumutcerdas.web.id/api/v1');
    expect(AppConfig.baseUrl, AppConfig.defaultBaseUrl);
  });

  test('account response reflects token state without exposed OAuth secrets',
      () {
    final account = ZoomAccount.fromJson({
      'id': 7,
      'account_name': 'Ruang utama',
      'has_token': false,
    });
    expect(account.id, 7);
    expect(account.hasToken, isFalse);
  });

  test('created meeting uses the Zoom id when meeting_id is absent', () {
    final meeting = BookMeetingResponse.fromJson({
      'id': 987654321,
      'topic': 'Rapat',
      'start_time': '2026-11-04T03:00:00Z',
      'duration': 30,
      'join_url': 'https://example.com/j/987654321',
    }, accountId: 7);
    expect(meeting.meetingId, 987654321);
    expect(meeting.accountId, 7);
  });

  test('end and delete requests follow backend account and occurrence contract',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: AppConfig.defaultBaseUrl));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(
        requestOptions: options,
        data: {'success': true, 'message': 'OK', 'data': null},
      ));
    }));
    final repository = BookingRepository(dio);

    expect(await repository.endMeeting(123, accountId: 7), isTrue);
    expect(requests.last.method, 'POST');
    expect(requests.last.path, '/bookings/123/end');
    expect(requests.last.data, {'account_id': 7});

    expect(
        await repository.deleteMeeting(123,
            accountId: 7,
            deleteOption: 'occurrence',
            occurrenceId: 'session-1'),
        isTrue);
    expect(requests.last.method, 'DELETE');
    expect(requests.last.data, {
      'account_id': 7,
      'delete_option': 'occurrence',
      'occurrence_id': 'session-1',
    });

    expect(
        await repository.deleteMeeting(123, accountId: 7, deleteOption: 'all'),
        isTrue);
    expect(requests.last.data, {'account_id': 7, 'delete_option': 'all'});
    await expectLater(
        repository.deleteMeeting(123, accountId: 7, deleteOption: 'occurrence'),
        throwsArgumentError);
  });
}
