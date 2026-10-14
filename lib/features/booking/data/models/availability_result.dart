class AccountRef {
  final int id;
  final String name;

  AccountRef({required this.id, required this.name});

  factory AccountRef.fromJson(Map<String, dynamic> json) {
    return AccountRef(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Akun Zoom',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class MeetingSummary {
  final String topic;
  final String startTime;
  final String endTime;

  MeetingSummary({
    required this.topic,
    required this.startTime,
    required this.endTime,
  });

  factory MeetingSummary.fromJson(Map<String, dynamic> json) {
    return MeetingSummary(
      topic: json['topic'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'start_time': startTime,
        'end_time': endTime,
      };
}

class AvailabilityResult {
  final String id;
  final AccountRef account;
  final String userName;
  final String email;
  final String bookingUserId; // 'me' atau user ID Zoom
  final String status; // 'AVAILABLE', 'BUSY', 'ERROR'
  final String details;
  final MeetingSummary? conflictingMeeting;
  final MeetingSummary? liveMeeting;
  final MeetingSummary? scheduledNow;

  AvailabilityResult({
    required this.id,
    required this.account,
    required this.userName,
    required this.email,
    required this.bookingUserId,
    required this.status,
    required this.details,
    this.conflictingMeeting,
    this.liveMeeting,
    this.scheduledNow,
  });

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    return AvailabilityResult(
      id: (json['id'] ?? '').toString(),
      account: json['account'] != null
          ? AccountRef.fromJson(json['account'] as Map<String, dynamic>)
          : AccountRef(id: json['account_id'] as int? ?? 0, name: json['account_name'] as String? ?? ''),
      userName: json['user_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bookingUserId: json['booking_user_id'] as String? ?? 'me',
      status: (json['status'] as String? ?? 'AVAILABLE').toUpperCase(),
      details: json['details'] as String? ?? '',
      conflictingMeeting: json['conflicting_meeting'] != null
          ? MeetingSummary.fromJson(json['conflicting_meeting'] as Map<String, dynamic>)
          : null,
      liveMeeting: json['live_meeting'] != null
          ? MeetingSummary.fromJson(json['live_meeting'] as Map<String, dynamic>)
          : null,
      scheduledNow: json['scheduled_now'] != null
          ? MeetingSummary.fromJson(json['scheduled_now'] as Map<String, dynamic>)
          : null,
    );
  }
}
