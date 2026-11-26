import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/core_providers.dart';
import '../../../features/auth/data/models/user_profile.dart';
import 'meeting_request.dart';

final meetingRequestRepositoryProvider = Provider<MeetingRequestRepository>(
    (ref) => MeetingRequestRepository(ref.watch(dioClientProvider)));

class MeetingRequestRepository {
  final Dio dio;
  MeetingRequestRepository(this.dio);

  dynamic _data(Response response) {
    final root = asMap(response.data);
    if (root['success'] != true) throw StateError(asText(root['message']));
    return root['data'];
  }

  Future<List<OpdProfile>> opds() async => asList(
      _data(await dio.get(ApiEndpoints.opds)),
      (v) => OpdProfile.fromJson(asMap(v)));
  Future<List<MeetingRequest>> list({int page = 1, String? status}) async =>
      asList(
        _data(await dio.get(ApiEndpoints.meetingRequests, queryParameters: {
          'page': page,
          if (status != null && status != 'all') 'status': status
        })),
        (v) => MeetingRequest.fromJson(asMap(v)),
      );
  Future<Map<String, dynamic>> systemHealth() async =>
      asMap(_data(await dio.get(ApiEndpoints.adminHealth)));
  Future<List<MeetingRequest>> history(
          {int page = 1,
          String? search,
          String? startDate,
          String? endDate}) async =>
      asList(
        _data(await dio.get(ApiEndpoints.meetingHistory, queryParameters: {
          'page': page,
          if (search?.isNotEmpty == true) 'search': search,
          if (startDate?.isNotEmpty == true) 'start_date': startDate,
          if (endDate?.isNotEmpty == true) 'end_date': endDate
        })),
        (v) => MeetingRequest.fromJson(asMap(v)),
      );
  Future<MeetingRequest> get(String id) async => MeetingRequest.fromJson(
      asMap(_data(await dio.get(ApiEndpoints.meetingRequest(id)))));
  Future<String> uploadLetter(PlatformFile file) async {
    final multipart = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : await MultipartFile.fromFile(file.path!, filename: file.name);
    final data = _data(await dio.post(
      ApiEndpoints.requestLetters,
      data: FormData.fromMap({'file': multipart}),
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: (_, __) {},
    ));
    return asText(asMap(data)['id']);
  }

  Future<MeetingRequest> submit(Map<String, dynamic> body, String key) async =>
      MeetingRequest.fromJson(asMap(_data(await dio.post(
          ApiEndpoints.meetingRequests,
          data: body,
          options: Options(headers: {'Idempotency-Key': key})))));
  Future<MeetingRequest> edit(
          String id, Map<String, dynamic> body, String key) async =>
      MeetingRequest.fromJson(asMap(_data(await dio.put(
          ApiEndpoints.meetingRequest(id),
          data: body,
          options: Options(headers: {'Idempotency-Key': key})))));
  Future<List<ApprovalOption>> options(String id) async => asList(
      _data(await dio.get(ApiEndpoints.requestOptions(id),
          options: Options(receiveTimeout: const Duration(seconds: 60)))),
      (v) => ApprovalOption.fromJson(asMap(v)));
  Future<void> approve(String id, Map<String, dynamic> body) async {
    _data(await dio.post(ApiEndpoints.requestApprove(id),
        data: body,
        options: Options(receiveTimeout: const Duration(seconds: 65))));
  }

  Future<void> reject(String id, String reason, int revision) async {
    _data(await dio.post(ApiEndpoints.requestReject(id),
        data: {'reason': reason, 'revision': revision}));
  }

  Future<void> reconcile(String id, int meetingId) async {
    _data(await dio.post(ApiEndpoints.requestReconcile(id),
        data: {'meeting_id': meetingId},
        options: Options(receiveTimeout: const Duration(seconds: 65))));
  }

  Future<Map<String, dynamic>> invitation(String id) async =>
      asMap(_data(await dio.get(ApiEndpoints.requestInvitation(id))));
  Future<Map<String, dynamic>> hostAccess(String id) async =>
      asMap(_data(await dio.get(ApiEndpoints.requestHostAccess(id))));
  Future<Map<String, dynamic>> recording(String id) async =>
      asMap(_data(await dio.get(ApiEndpoints.requestRecording(id))));
  Future<List<int>> letterContent(String id) async {
    final response = await dio.get<List<int>>(
        ApiEndpoints.requestLetterContent(id),
        options: Options(responseType: ResponseType.bytes));
    return response.data ?? [];
  }

  Future<List<OpdAccount>> opdAccounts({String search = ''}) async => asList(
      _data(await dio.get(ApiEndpoints.opdAccounts,
          queryParameters: {if (search.isNotEmpty) 'search': search})),
      (v) => OpdAccount.fromJson(asMap(v)));
  Future<void> createOpdAccount(Map<String, dynamic> body) async {
    _data(await dio.post(ApiEndpoints.opdAccounts, data: body));
  }

  Future<void> updateOpdAccount(int id, Map<String, dynamic> body) async {
    _data(await dio.put(ApiEndpoints.opdAccount(id), data: body));
  }

  Future<void> deleteOpdAccount(int id) async {
    _data(await dio.delete(ApiEndpoints.opdAccount(id)));
  }
}

String requestError(Object error) {
  if (error is DioException) {
    final data = asMap(error.response?.data);
    return asText(data['message']).isNotEmpty
        ? asText(data['message'])
        : 'Koneksi ke server gagal. Coba lagi.';
  }
  return error is StateError
      ? error.message
      : 'Permintaan belum dapat diproses.';
}
