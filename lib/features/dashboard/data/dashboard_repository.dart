import 'package:dio/dio.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import 'models/dashboard_account.dart';

class DashboardRepository {
  final Dio _dio;
  final ApiCacheManager _cacheManager;

  DashboardRepository(this._dio, [ApiCacheManager? cacheManager])
      : _cacheManager = cacheManager ?? ApiCacheManager();

  Future<List<DashboardAccount>> getDashboard({bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<List<DashboardAccount>>(
      key: 'dashboard:accounts',
      ttl: const Duration(seconds: 30),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.dashboard);
          final apiRes = ApiResponse<List<dynamic>>.fromJson(
            response.data as Map<String, dynamic>,
            (data) => data as List<dynamic>,
          );

          if (apiRes.success && apiRes.data != null) {
            return apiRes.data!
                .map((item) => DashboardAccount.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mengambil data dashboard')
              : (e.message ?? 'Gagal mengambil data dashboard');
          throw Exception(msg);
        }
      },
    );
  }

  Future<Map<String, dynamic>> getAccountStatus(int id, {bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<Map<String, dynamic>>(
      key: 'account:status:$id',
      ttl: const Duration(seconds: 20),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.accountStatus(id));
          return (response.data['data'] as Map<String, dynamic>?) ?? {};
        } catch (_) {
          return {};
        }
      },
    );
  }

  Future<Map<String, dynamic>> getAccountSpecs(int id, {bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<Map<String, dynamic>>(
      key: 'account:specs:$id',
      ttl: const Duration(seconds: 30),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.accountSpecs(id));
          return (response.data['data'] as Map<String, dynamic>?) ?? {};
        } catch (_) {
          return {};
        }
      },
    );
  }
}
