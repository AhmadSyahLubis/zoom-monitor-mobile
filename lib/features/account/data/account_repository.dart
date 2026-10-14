import 'package:dio/dio.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import 'models/zoom_account.dart';

class AccountRepository {
  final Dio _dio;
  final ApiCacheManager _cacheManager;

  AccountRepository(this._dio, [ApiCacheManager? cacheManager])
      : _cacheManager = cacheManager ?? ApiCacheManager();

  Future<List<ZoomAccount>> listAccounts({bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<List<ZoomAccount>>(
      key: 'accounts:list',
      ttl: const Duration(seconds: 60),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.accounts);
          final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
          if (apiRes.success && apiRes.data != null) {
            if (apiRes.data is List) {
              return (apiRes.data as List)
                  .map((e) => ZoomAccount.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
          return [];
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mengambil akun Zoom')
              : (e.message ?? 'Gagal mengambil akun Zoom');
          throw Exception(msg);
        }
      },
    );
  }

  Future<ZoomAccount> getAccount(int id, {bool forceRefresh = false}) async {
    return _cacheManager.getOrFetch<ZoomAccount>(
      key: 'accounts:detail:$id',
      ttl: const Duration(seconds: 60),
      forceRefresh: forceRefresh,
      fetcher: () async {
        try {
          final response = await _dio.get(ApiEndpoints.accountById(id));
          final apiRes = ApiResponse<ZoomAccount>.fromJson(
            response.data as Map<String, dynamic>,
            (data) => ZoomAccount.fromJson(data as Map<String, dynamic>),
          );
          if (apiRes.success && apiRes.data != null) {
            return apiRes.data!;
          }
          throw Exception(apiRes.message.isNotEmpty ? apiRes.message : 'Akun tidak ditemukan');
        } on DioException catch (e) {
          final msg = e.response?.data is Map<String, dynamic>
              ? (e.response!.data['message'] as String? ?? 'Gagal mengambil detail akun')
              : (e.message ?? 'Gagal mengambil detail akun');
          throw Exception(msg);
        }
      },
    );
  }

  Future<bool> createAccount(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.accounts, data: data);
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('accounts');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal menambahkan akun Zoom')
          : (e.message ?? 'Gagal menambahkan akun Zoom');
      throw Exception(msg);
    }
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.accountById(id), data: data);
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('accounts');
        _cacheManager.invalidate('account:status:$id');
        _cacheManager.invalidate('account:specs:$id');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal memperbarui akun Zoom')
          : (e.message ?? 'Gagal memperbarui akun Zoom');
      throw Exception(msg);
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.accountById(id));
      final apiRes = ApiResponse<dynamic>.fromJson(response.data as Map<String, dynamic>);
      if (apiRes.success) {
        _cacheManager.invalidate('accounts');
        _cacheManager.invalidate('account:status:$id');
        _cacheManager.invalidate('account:specs:$id');
        _cacheManager.invalidate('dashboard');
      }
      return apiRes.success;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal menghapus akun Zoom')
          : (e.message ?? 'Gagal menghapus akun Zoom');
      throw Exception(msg);
    }
  }

  Future<CheckConnectionResponse> checkConnection(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.checkAccount(id));
      final root = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final inner = (root['data'] is Map<String, dynamic>)
          ? root['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final merged = <String, dynamic>{
        ...root,
        ...inner,
        if ((inner['message'] == null || inner['message'].toString().isEmpty) &&
            root['message'] != null)
          'message': root['message'],
        if (inner['success'] == null && root['success'] != null)
          'success': root['success'],
      };

      return CheckConnectionResponse.fromJson(merged);
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] as String? ?? 'Gagal menguji koneksi akun')
          : (e.message ?? 'Gagal menguji koneksi akun');
      return CheckConnectionResponse(
        isConnected: false,
        accountName: '',
        message: msg,
      );
    }
  }
}
