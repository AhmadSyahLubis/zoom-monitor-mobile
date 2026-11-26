import '../../auth/data/models/user_profile.dart';

Map<String, dynamic> asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
int asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String asText(dynamic value) => value?.toString() ?? '';
List<T> asList<T>(dynamic value, T Function(dynamic) parse) =>
    value is List ? value.map(parse).toList() : <T>[];

class MeetingRequest {
  final String id,
      opdName,
      topic,
      cluster,
      startTime,
      endTime,
      picName,
      picPhone,
      priority,
      status,
      reviewReason;
  final int opdId, capacity, revision, zoomMeetingId;
  final bool recordCloud, hasLetter, createAttempted;
  final List<int> participantOpdIds;
  final List<String> participantOthers;

  MeetingRequest.fromJson(Map<String, dynamic> json)
      : id = asText(json['id']),
        opdId = asInt(json['opd_id']),
        opdName = asText(json['opd_name']),
        topic = asText(json['topic']),
        cluster = asText(json['cluster']),
        startTime = asText(json['start_time']),
        endTime = asText(json['end_time']),
        picName = asText(json['pic_name']),
        picPhone = asText(json['pic_phone']),
        priority = asText(json['priority']),
        status = asText(json['status']),
        reviewReason = asText(json['review_reason']),
        capacity = asInt(json['capacity']),
        revision = asInt(json['revision']),
        zoomMeetingId = asInt(json['zoom_meeting_id']),
        recordCloud = json['record_cloud'] == true,
        hasLetter = json['has_request_letter'] == true,
        createAttempted = json['create_attempted'] == true,
        participantOpdIds = asList(json['participant_opd_ids'], asInt),
        participantOthers =
            asList(json['participant_others'], asText).isNotEmpty
                ? asList(json['participant_others'], asText)
                : (asText(json['participant_other']).isEmpty
                    ? <String>[]
                    : <String>[asText(json['participant_other'])]);

  bool get canEdit =>
      status == 'pending' || status == 'rejected' || status == 'expired';
}

class ApprovalOption {
  final int accountId, capacity;
  final int? joinBeforeHostMinutes;
  final String accountName, hostId, hostName, reason;
  final bool eligible, cloudRecording;
  final bool? joinBeforeHost, waitingRoom;
  final List<MeetingRequest> replaceRequests;

  ApprovalOption.fromJson(Map<String, dynamic> json)
      : accountId = asInt(json['account_id']),
        capacity = asInt(json['capacity']),
        joinBeforeHostMinutes = json['join_before_host_minutes'] is num
            ? asInt(json['join_before_host_minutes'])
            : null,
        accountName = asText(json['account_name']),
        hostId = asText(json['host_id']),
        hostName = asText(json['host_name']),
        reason = asText(json['reason']),
        eligible = json['eligible'] == true,
        cloudRecording = json['cloud_recording'] == true,
        joinBeforeHost = json['join_before_host'] as bool?,
        waitingRoom = json['waiting_room'] as bool?,
        replaceRequests = asList(
            json['replace_requests'], (v) => MeetingRequest.fromJson(asMap(v)));
}

class OpdAccount {
  final int id;
  final String name, username;
  final OpdProfile? opd;
  final bool isActive, canManage;
  OpdAccount.fromJson(Map<String, dynamic> json)
      : id = asInt(json['id']),
        name = asText(json['name']),
        username = asText(json['username']),
        opd = json['opd'] is Map<String, dynamic>
            ? OpdProfile.fromJson(asMap(json['opd']))
            : null,
        isActive = json['is_active'] == true,
        canManage = json['can_manage'] == true;
}
