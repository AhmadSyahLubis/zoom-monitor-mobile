class BookMeetingRequest {
  final int accountId;
  final String topic;
  final String startTime;
  final int duration;
  final String timezone;
  final bool isRecurring;
  final int? recurringType; // 1 = Daily, 2 = Weekly, 3 = Monthly
  final int? repeatInterval;
  final int? endTimes;
  final String? endDateTime;
  final bool ignoreConflict;

  BookMeetingRequest({
    required this.accountId,
    required this.topic,
    required this.startTime,
    required this.duration,
    this.timezone = 'Asia/Jakarta',
    this.isRecurring = false,
    this.recurringType,
    this.repeatInterval,
    this.endTimes,
    this.endDateTime,
    this.ignoreConflict = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'account_id': accountId,
      'topic': topic,
      'start_time': startTime,
      'duration': duration,
      'timezone': timezone,
      'is_recurring': isRecurring,
      'ignore_conflict': ignoreConflict,
    };

    if (isRecurring) {
      if (recurringType != null) {
        map['recurring_type'] = recurringType;
        map['recurrence_type'] = recurringType;
      }
      if (repeatInterval != null) map['repeat_interval'] = repeatInterval;
      if (endTimes != null) map['end_times'] = endTimes;
      if (endDateTime != null && endDateTime!.isNotEmpty) {
        map['end_date_time'] = endDateTime;
      }
    }

    return map;
  }
}

class UpdateMeetingRequest {
  final int accountId;
  final String topic;
  final String startTime; // "YYYY-MM-DD HH:MM" WIB
  final int duration;
  final bool isRecurring;
  final int? recurrenceType; // 1 = Daily, 2 = Weekly, 3 = Monthly
  final int? repeatInterval;
  final String? weeklyDays;
  final String? endDateTime;

  UpdateMeetingRequest({
    required this.accountId,
    required this.topic,
    required this.startTime,
    required this.duration,
    this.isRecurring = false,
    this.recurrenceType,
    this.repeatInterval,
    this.weeklyDays,
    this.endDateTime,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'account_id': accountId,
      'topic': topic,
      'start_time': startTime,
      'duration': duration,
      'is_recurring': isRecurring,
    };

    if (isRecurring) {
      if (recurrenceType != null) {
        map['recurrence_type'] = recurrenceType;
        map['recurring_type'] = recurrenceType;
      }
      if (repeatInterval != null) map['repeat_interval'] = repeatInterval;
      if (weeklyDays != null) map['weekly_days'] = weeklyDays;
      if (endDateTime != null && endDateTime!.isNotEmpty) {
        map['end_date_time'] = endDateTime;
      }
    }

    return map;
  }
}

class BookMeetingResponse {
  final int id;
  final int meetingId;
  final int accountId;
  final String accountName;
  final String topic;
  final String startTime;
  final int duration;
  final String password;
  final String joinUrl;
  final String? hostKey;

  BookMeetingResponse({
    required this.id,
    required this.meetingId,
    required this.accountId,
    required this.accountName,
    required this.topic,
    required this.startTime,
    required this.duration,
    required this.password,
    required this.joinUrl,
    this.hostKey,
  });

  factory BookMeetingResponse.fromJson(Map<String, dynamic> json) {
    return BookMeetingResponse(
      id: json['id'] as int? ?? 0,
      meetingId: (json['meeting_id'] is num)
          ? (json['meeting_id'] as num).toInt()
          : int.tryParse(json['meeting_id']?.toString() ?? '') ?? 0,
      accountId: json['account_id'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? 'Akun Zoom',
      topic: json['topic'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      duration: json['duration'] as int? ?? 60,
      password: json['password'] as String? ?? '',
      joinUrl: json['join_url'] as String? ?? '',
      hostKey: json['host_key'] as String?,
    );
  }
}
