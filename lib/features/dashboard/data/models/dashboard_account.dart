class DashboardAccount {
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
    required this.id,
    required this.accountName,
    this.email,
    this.hostKey,
    required this.status,
    this.currentTopic,
    required this.meetingCapacity,
    required this.planType,
    required this.lastUpdated,
  });

  factory DashboardAccount.fromJson(Map<String, dynamic> json) {
    return DashboardAccount(
      id: json['id'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? 'Akun Zoom',
      email: json['email'] as String?,
      hostKey: json['host_key'] as String?,
      status: (json['status'] as String? ?? 'available').toLowerCase(),
      currentTopic: json['current_topic'] as String?,
      meetingCapacity: json['meeting_capacity'] as int? ?? 300,
      planType: json['plan_type'] as String? ?? 'Licensed',
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
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
