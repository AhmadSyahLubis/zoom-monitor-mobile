import '../../../../core/models/meeting_monitoring.dart';

class DashboardAccount {
  final MeetingMonitoring? monitoring;
  final DateTime? serverTime;
  final DateTime receivedAt;
  final int liveCount;
  bool get isStale => monitoringIsStale(lastUpdated, serverTime, receivedAt);
  final int id;
  final String accountName;
  final String? email;
  final String? hostKey;
  final String status; // 'available', 'meeting', 'scheduled', 'error'
  final String? currentTopic;
  final int meetingCapacity;
  final String planType;
  final DateTime lastUpdated;

  DashboardAccount({
    this.monitoring,
    this.serverTime,
    DateTime? receivedAt,
    this.liveCount = 0,
    required this.id,
    required this.accountName,
    this.email,
    this.hostKey,
    required this.status,
    this.currentTopic,
    required this.meetingCapacity,
    required this.planType,
    required this.lastUpdated,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory DashboardAccount.fromJson(Map<String, dynamic> json) {
    return DashboardAccount(
      monitoring: json['monitoring'] is Map<String, dynamic>
          ? MeetingMonitoring.fromJson(
              json['monitoring'] as Map<String, dynamic>)
          : null,
      serverTime: DateTime.tryParse(json['server_time'] as String? ?? ''),
      liveCount: json['live_count'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? 'Akun Zoom',
      email: json['email'] as String?,
      hostKey: json['host_key'] as String?,
      status: (json['status'] as String? ?? 'error').toLowerCase(),
      currentTopic: json['current_topic'] as String?,
      meetingCapacity: json['meeting_capacity'] as int? ?? 300,
      planType: json['plan_type'] as String? ?? 'Licensed',
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_name': accountName,
      'email': email,
      'host_key': hostKey,
      'status': status,
      'current_topic': currentTopic,
      'meeting_capacity': meetingCapacity,
      'plan_type': planType,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
