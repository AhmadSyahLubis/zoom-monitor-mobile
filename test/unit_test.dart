import 'package:flutter_test/flutter_test.dart';
import 'package:zoom_monitor_mobile/core/network/api_cache_manager.dart';
import 'package:zoom_monitor_mobile/core/utils/date_time_util.dart';
import 'package:zoom_monitor_mobile/core/utils/invite_formatter.dart';
import 'package:zoom_monitor_mobile/features/auth/data/models/user_profile.dart';
import 'package:zoom_monitor_mobile/features/dashboard/data/models/dashboard_account.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/booking_request.dart';
import 'package:zoom_monitor_mobile/features/booking/data/models/schedule_item.dart';
import 'package:zoom_monitor_mobile/features/recording/data/models/recording_item.dart';
import 'package:zoom_monitor_mobile/features/account/data/models/zoom_account.dart';

void main() {
  group('DateTimeUtil WIB Tests', () {
    test('Converts UTC ISO string to WIB (+7 hours)', () {
      const utcIso = '2026-10-13T07:00:00Z';
      final wib = DateTimeUtil.parseToWib(utcIso);
      expect(wib.hour, 14); // 07 + 7 = 14
    });

    test('Formats time range WIB', () {
      const start = '2026-10-13T07:00:00Z';
      const end = '2026-10-13T08:30:00Z';
      final formatted = DateTimeUtil.formatTimeRangeWib(start, end);
      expect(formatted.contains('14:00'), isTrue);
      expect(formatted.contains('15:30'), isTrue);
      expect(formatted.contains('WIB'), isTrue);
    });
  });

  group('InviteFormatter Tests', () {
    test('Formats invitation text standard', () {
      final invite = InviteFormatter.formatInvite(
        topic: 'Rapat Koordinasi Wilayah',
        startTimeWib: '14:00',
        endTimeWib: '15:30',
        accountName: 'Ruang Rapat Direksi',
        meetingId: '89012345678',
        passcode: 'meetingpass',
        hostKey: '654321',
        joinUrl: 'https://zoom.us/j/89012345678',
      );

      expect(invite.contains('UNDANGAN RAPAT VIRTUAL'), isTrue);
      expect(invite.contains('Rapat Koordinasi Wilayah'), isTrue);
      expect(invite.contains('Host Key: 654321'), isTrue);
      expect(invite.contains('https://zoom.us/j/89012345678'), isTrue);
    });
  });

  group('Model Serialization Tests', () {
    test('UserProfile json parsing', () {
      final json = {
        'id': 1,
        'name': 'Administrator',
        'username': 'admin',
        'email': 'admin@company.com',
        'has_pin': true,
        'biometric_enabled': false,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 1);
      expect(profile.username, 'admin');
      expect(profile.hasPin, isTrue);
    });

    test('DashboardAccount json parsing', () {
      final json = {
        'id': 10,
        'account_name': 'Akun Zoom Ops 1',
        'status': 'AVAILABLE',
        'meeting_capacity': 500,
        'plan_type': 'Enterprise',
        'last_updated': '2026-10-13T10:00:00Z',
      };

      final account = DashboardAccount.fromJson(json);
      expect(account.id, 10);
      expect(account.status, 'available');
      expect(account.meetingCapacity, 500);
    });

    test('ScheduleItem recurring check', () {
      final item = ScheduleItem(
        id: 1,
        meetingId: 100,
        accountId: 1,
        accountName: 'Akun 1',
        host: 'Host',
        topic: 'Topik',
        password: 'pass',
        startTime: '2026-10-13T10:00:00Z',
        endTime: '2026-10-13T11:00:00Z',
        duration: 60,
        joinUrl: 'https://zoom.us',
        type: 8,
      );

      expect(item.isRecurring, isTrue);
    });

    test('RecordingItem formatted total size', () {
      final item = RecordingItem(
        meetingId: 1,
        uuid: 'uuid-1',
        topic: 'Topik Rekaman',
        startTime: '2026-10-13T10:00:00Z',
        duration: 45,
        totalSize: 52428800, // 50 MB
        shareUrl: 'https://zoom.us/rec',
        recordingCount: 2,
        recordingFiles: [],
        accountName: 'Akun Zoom',
        accountId: 1,
        hostName: 'Host',
        hostEmail: 'host@zoom.us',
      );

      expect(item.formattedTotalSize, '50.0 MB');
    });

    test('CheckConnectionResponse json parsing with success:true and active_users_count', () {
      final json = {
        'success': true,
        'message': 'Koneksi berhasil! Terdeteksi 1 user aktif',
        'account_id': 1,
        'account_name': 'Akun 1',
        'active_users_count': 1,
      };

      final response = CheckConnectionResponse.fromJson(json);
      expect(response.isConnected, isTrue);
      expect(response.accountName, 'Akun 1');
      expect(response.userCount, 1);
      expect(response.message, 'Koneksi berhasil! Terdeteksi 1 user aktif');
    });

    test('BookMeetingRequest with recurring end_date_time serialization', () {
      final req = BookMeetingRequest(
        accountId: 1,
        topic: 'Rapat Mingguan',
        startTime: '2026-10-14T07:00:00Z',
        duration: 60,
        isRecurring: true,
        recurringType: 2,
        repeatInterval: 1,
        endDateTime: '2026-10-28T23:59:59Z',
      );

      final json = req.toJson();
      expect(json['account_id'], 1);
      expect(json['is_recurring'], isTrue);
      expect(json['recurrence_type'], 2);
      expect(json['recurring_type'], 2);
      expect(json['end_date_time'], '2026-10-28T23:59:59Z');
    });

    test('UpdateMeetingRequest serialization matches API spec', () {
      final req = UpdateMeetingRequest(
        accountId: 2,
        topic: 'Rapat Terupdate',
        startTime: '2026-10-15 14:00',
        duration: 90,
        isRecurring: true,
        recurrenceType: 1,
        endDateTime: '2026-10-30T23:59:59Z',
      );

      final json = req.toJson();
      expect(json['account_id'], 2);
      expect(json['topic'], 'Rapat Terupdate');
      expect(json['start_time'], '2026-10-15 14:00');
      expect(json['duration'], 90);
      expect(json['is_recurring'], isTrue);
      expect(json['recurrence_type'], 1);
      expect(json['end_date_time'], '2026-10-30T23:59:59Z');
    });
  });

  group('ApiCacheManager Senior Tests', () {
    late ApiCacheManager cache;

    setUp(() {
      cache = ApiCacheManager();
      cache.clear();
    });

    test('getOrFetch caches data and avoids second fetcher execution within TTL', () async {
      int callCount = 0;
      Future<String> fetchData() async {
        callCount++;
        return 'Data-$callCount';
      }

      final res1 = await cache.getOrFetch<String>(
        key: 'test:item',
        fetcher: fetchData,
        ttl: const Duration(seconds: 10),
      );
      final res2 = await cache.getOrFetch<String>(
        key: 'test:item',
        fetcher: fetchData,
        ttl: const Duration(seconds: 10),
      );

      expect(res1, 'Data-1');
      expect(res2, 'Data-1');
      expect(callCount, 1);
    });

    test('getOrFetch with forceRefresh: true bypasses cached data', () async {
      int callCount = 0;
      Future<String> fetchData() async {
        callCount++;
        return 'Data-$callCount';
      }

      await cache.getOrFetch<String>(
        key: 'test:item',
        fetcher: fetchData,
        ttl: const Duration(seconds: 10),
      );
      final res2 = await cache.getOrFetch<String>(
        key: 'test:item',
        fetcher: fetchData,
        ttl: const Duration(seconds: 10),
        forceRefresh: true,
      );

      expect(res2, 'Data-2');
      expect(callCount, 2);
    });

    test('Singleflight deduplicates simultaneous in-flight requests', () async {
      int callCount = 0;
      Future<String> fetchData() async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'ConcurrentResult';
      }

      // Execute 3 simultaneous requests for the exact same key
      final futures = await Future.wait([
        cache.getOrFetch<String>(key: 'test:singleflight', fetcher: fetchData),
        cache.getOrFetch<String>(key: 'test:singleflight', fetcher: fetchData),
        cache.getOrFetch<String>(key: 'test:singleflight', fetcher: fetchData),
      ]);

      expect(futures[0], 'ConcurrentResult');
      expect(futures[1], 'ConcurrentResult');
      expect(futures[2], 'ConcurrentResult');
      expect(callCount, 1); // Only 1 network call occurred!
    });

    test('invalidate removes keys matching prefix', () async {
      cache.set('dashboard:main', 1);
      cache.set('dashboard:sub', 2);
      cache.set('accounts:list', 3);

      cache.invalidate('dashboard');

      expect(cache.get('dashboard:main'), isNull);
      expect(cache.get('dashboard:sub'), isNull);
      expect(cache.get('accounts:list'), 3);
    });

    test('clear removes all entries', () async {
      cache.set('key1', 1);
      cache.set('key2', 2);

      cache.clear();

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });
  });
}
