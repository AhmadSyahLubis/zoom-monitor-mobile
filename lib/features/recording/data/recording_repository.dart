import 'package:dio/dio.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import 'models/recording_item.dart';

class RecordingRepository {
  final Dio _dio;
  final ApiCacheManager _cacheManager;

  RecordingRepository(this._dio, [ApiCacheManager? cacheManager])
      : _cacheManager = cacheManager ?? ApiCacheManager();

  Future<List<RecordingItem>> listRecordings({
    String? from,
    String? to,
    String? search,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'recordings:${from ?? ''}:${to ?? ''}:${search ?? ''}';
    return _cacheManager.getOrFetch<List<RecordingItem>>(
      key: cacheKey,
      ttl: const Duration(seconds: 60),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final query = <String, dynamic>{};
          if (from != null && from.isNotEmpty) query['from'] = from;
          if (to != null && to.isNotEmpty) query['to'] = to;
          if (search != null && search.isNotEmpty) query['search'] = search;

          final response = await _dio.get(
            ApiEndpoints.recordings,
            queryParameters: query,
          );

          final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
          if (apiRes.success && apiRes.data != null) {
            if (apiRes.data is List) {
              return (apiRes.data as List)
                  .map((e) => RecordingItem.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
          return [];
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mengambil data rekaman')
              : (e.message ?? 'Gagal mengambil data rekaman');
          throw Exception(msg);
        }
      },
    );
  }
}
