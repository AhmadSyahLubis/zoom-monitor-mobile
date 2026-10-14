class ScheduleItem {
  final int id;
  final int meetingId;
  final int accountId;
  final String accountName;
  final String? hostKey;
  final String host;
  final String topic;
  final String password;
  final String startTime;
  final String endTime;
  final int duration;
  final String joinUrl;
  final int type;
  final String? occurrenceId;

  ScheduleItem({
    required this.id,
    required this.meetingId,
    required this.accountId,
    required this.accountName,
    this.hostKey,
    required this.host,
    required this.topic,
    required this.password,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.joinUrl,
    required this.type,
    this.occurrenceId,
  });

  bool get isRecurring => type == 8 || (occurrenceId != null && occurrenceId!.isNotEmpty);

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as int? ?? 0,
      meetingId: (json['meeting_id'] is num)
          ? (json['meeting_id'] as num).toInt()
          : int.tryParse(json['meeting_id']?.toString() ?? '') ?? 0,
      accountId: json['account_id'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? 'Akun Zoom',
      hostKey: json['host_key'] as String?,
      host: json['host'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      password: json['password'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      duration: json['duration'] as int? ?? 60,
      joinUrl: json['join_url'] as String? ?? '',
      type: json['type'] as int? ?? 2,
      occurrenceId: json['occurrence_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'account_id': accountId,
      'account_name': accountName,
      'host_key': hostKey,
      'host': host,
      'topic': topic,
      'password': password,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'join_url': joinUrl,
      'type': type,
      'occurrence_id': occurrenceId,
    };
  }
}

class SchedulesData {
  final List<ScheduleItem> liveMeetings;
  final List<ScheduleItem> upcomingMeetings;
  final List<ScheduleItem> pastMeetings;

  SchedulesData({
    required this.liveMeetings,
    required this.upcomingMeetings,
    required this.pastMeetings,
  });

  factory SchedulesData.fromJson(Map<String, dynamic> json) {
    return SchedulesData(
      liveMeetings: (json['live_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingMeetings: (json['upcoming_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pastMeetings: (json['past_meetings'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
