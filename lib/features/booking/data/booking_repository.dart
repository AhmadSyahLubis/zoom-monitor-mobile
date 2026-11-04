import 'package:dio/dio.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import 'models/availability_result.dart';
import 'models/booking_request.dart';
import 'models/schedule_item.dart';

class BookingFailure implements Exception {
  final String message;
  final String? code;
  const BookingFailure(this.message, this.code);
  @override
  String toString() => message;
}

class BookingRepository {
  final Dio _dio;
  final ApiCacheManager _cacheManager;

  BookingRepository(this._dio, [ApiCacheManager? cacheManager])
      : _cacheManager = cacheManager ?? ApiCacheManager();

  Future<List<AvailabilityResult>> searchAvailability({
    required String date,
    required String startTime,
    required int duration,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'availability:$date:$startTime:$duration';
    return _cacheManager.getOrFetch<List<AvailabilityResult>>(
      key: cacheKey,
      ttl: const Duration(seconds: 15),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(
            ApiEndpoints.searchAvailability,
            queryParameters: {
              'date': date,
              'start_time': startTime,
              'duration': duration,
            },
          );

          final apiRes = ApiResponse<dynamic>.fromJson(
              response.data as Map<String, dynamic>);
          if (apiRes.success && apiRes.data != null) {
            if (apiRes.data is List) {
              return (apiRes.data as List)
                  .map((e) =>
                      AvailabilityResult.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
          return [];
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ??
                  'Gagal mencari ketersediaan')
              : (e.message ?? 'Gagal mencari ketersediaan');
          throw Exception(msg);
        }
      },
    );
  }

  Future<BookMeetingResponse> bookMeeting(BookMeetingRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.bookings,
        data: request.toJson(),
      );

      final apiRes = ApiResponse<BookMeetingResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => BookMeetingResponse.fromJson(
          data as Map<String, dynamic>,
          accountId: request.accountId,
        ),
      );

      if (apiRes.success && apiRes.data != null) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
        return apiRes.data!;
      }
      throw Exception(
          apiRes.message.isNotEmpty ? apiRes.message : 'Gagal membuat rapat');
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal membuat rapat')
          : (e.message ?? 'Gagal membuat rapat');
      throw BookingFailure(
          msg,
          e.response?.data is Map<String, dynamic>
              ? e.response!.data['error_code'] as String?
              : null);
    }
  }

  Future<Map<String, dynamic>> getMeetingDetail(
      int accountId, int meetingId) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.meetingDetails(accountId, meetingId));
      final apiRes = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
      if (apiRes.success && apiRes.data != null) return apiRes.data!;
      throw const BookingFailure(
          'Detail rapat tidak tersedia dari Zoom.', null);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw const BookingFailure(
            'Detail rapat tidak tersedia dari Zoom. Muat ulang jadwal rapat.',
            null);
      }
      if (status == 401 || status == 403) {
        throw const BookingFailure(
            'Akses detail rapat tidak diizinkan. Masuk kembali lalu coba lagi.',
            null);
      }
      throw const BookingFailure(
          'Detail rapat gagal dimuat. Periksa koneksi lalu coba lagi.', null);
    }
  }

  Future<SchedulesData> listSchedules({bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<SchedulesData>(
      key: 'bookings:schedules',
      ttl: const Duration(seconds: 30),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.bookings);
          final apiRes = ApiResponse<SchedulesData>.fromJson(
            response.data as Map<String, dynamic>,
            (data) => SchedulesData.fromJson(data as Map<String, dynamic>),
          );

          if (apiRes.success && apiRes.data != null) {
            return apiRes.data!;
          }
          return SchedulesData(
              liveMeetings: [], upcomingMeetings: [], pastMeetings: []);
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ??
                  'Gagal mengambil jadwal')
              : (e.message ?? 'Gagal mengambil jadwal');
          throw Exception(msg);
        }
      },
    );
  }

  Future<bool> endMeeting(dynamic meetingId, {required int accountId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.endMeeting(meetingId),
        data: {'account_id': accountId},
      );
      final apiRes =
          ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal mengakhiri rapat')
          : (e.message ?? 'Gagal mengakhiri rapat');
      throw Exception(msg);
    }
  }

  Future<bool> updateMeeting(
      dynamic meetingId, UpdateMeetingRequest request) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.meetingById(meetingId),
        data: request.toJson(),
      );
      final apiRes =
          ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ??
              'Gagal memperbarui rapat')
          : (e.message ?? 'Gagal memperbarui rapat');
      throw Exception(msg);
    }
  }

  Future<bool> deleteMeeting(dynamic meetingId,
      {required int accountId,
      required String deleteOption,
      String? occurrenceId}) async {
    if (deleteOption != 'all' && deleteOption != 'occurrence') {
      throw ArgumentError('Pilihan penghapusan rapat tidak valid');
    }
    if (deleteOption == 'occurrence' &&
        (occurrenceId == null || occurrenceId.isEmpty)) {
      throw ArgumentError(
          'ID kejadian rapat wajib diisi untuk penghapusan sesi');
    }
    try {
      final response = await _dio.delete(
        ApiEndpoints.meetingById(meetingId),
        data: {
          'account_id': accountId,
          'delete_option': deleteOption,
          if (deleteOption == 'occurrence') 'occurrence_id': occurrenceId,
        },
      );
      final apiRes =
          ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ??
              'Gagal membatalkan rapat')
          : (e.message ?? 'Gagal membatalkan rapat');
      throw Exception(msg);
    }
  }
}
