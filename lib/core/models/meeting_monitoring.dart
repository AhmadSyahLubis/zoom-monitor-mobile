class MonitoringLabel {
  final String code;
  final String text;
  const MonitoringLabel(this.code, this.text);
}

class MeetingMonitoring {
  final String state;
  final bool scheduleKnown;
  final DateTime? observedAt;
  final List<MonitoringLabel> labels;

  const MeetingMonitoring(
      {required this.state,
      required this.scheduleKnown,
      this.observedAt,
      this.labels = const []});

  factory MeetingMonitoring.fromJson(Map<String, dynamic> json) =>
      MeetingMonitoring(
        state: json['state'] as String? ?? 'unknown',
        scheduleKnown: json['schedule_known'] == true,
        observedAt: DateTime.tryParse(json['observed_at'] as String? ?? ''),
        labels: (json['labels'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((label) => MonitoringLabel(
                label['code'] as String? ?? '', label['text'] as String? ?? ''))
            .toList(),
      );
}

bool monitoringIsStale(
    DateTime? observedAt, DateTime? serverTime, DateTime receivedAt,
    {DateTime? now}) {
  if (observedAt == null ||
      serverTime == null ||
      observedAt.isAfter(serverTime)) {
    return true;
  }
  final elapsed = (now ?? DateTime.now()).difference(receivedAt);
  return serverTime.difference(observedAt) +
          (elapsed.isNegative ? Duration.zero : elapsed) >=
      const Duration(seconds: 90);
}
