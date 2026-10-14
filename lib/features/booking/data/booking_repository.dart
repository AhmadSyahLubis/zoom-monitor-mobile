import 'package:dio/dio.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import 'models/availability_result.dart';
import 'models/booking_request.dart';
import 'models/schedule_item.dart';

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

          final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
          if (apiRes.success && apiRes.data != null) {
            if (apiRes.data is List) {
              return (apiRes.data as List)
                  .map((e) => AvailabilityResult.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
          return [];
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mencari ketersediaan')
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
        (data) => BookMeetingResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiRes.success && apiRes.data != null) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
        return apiRes.data!;
      }
      throw Exception(apiRes.message.isNotEmpty ? apiRes.message : 'Gagal membuat rapat');
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal membuat rapat')
              : (e.message ?? 'Gagal membuat rapat');
      throw Exception(msg);
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
          return SchedulesData(liveMeetings: [], upcomingMeetings: [], pastMeetings: []);
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mengambil jadwal')
              : (e.message ?? 'Gagal mengambil jadwal');
          throw Exception(msg);
        }
      },
    );
  }

  Future<bool> endMeeting(dynamic meetingId) async {
    try {
      final response = await _dio.post(ApiEndpoints.endMeeting(meetingId));
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
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

  Future<bool> updateMeeting(dynamic meetingId, UpdateMeetingRequest request) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.meetingById(meetingId),
        data: request.toJson(),
      );
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal memperbarui rapat')
          : (e.message ?? 'Gagal memperbarui rapat');
      throw Exception(msg);
    }
  }

  Future<bool> deleteMeeting(dynamic meetingId, {String deleteOption = 'occurrence'}) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.meetingById(meetingId),
        queryParameters: {'delete_option': deleteOption},
      );
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('bookings');
        _cacheManager.invalidate('availability');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal membatalkan rapat')
          : (e.message ?? 'Gagal membatalkan rapat');
      throw Exception(msg);
    }
  }
}
