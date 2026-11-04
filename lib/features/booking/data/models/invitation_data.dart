class InvitationDataException implements Exception {
  const InvitationDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvitationData {
  const InvitationData._({
    required this.topic,
    required this.meetingId,
    required this.passcode,
    required this.joinUrl,
    required this.startTime,
    required this.endTime,
  });

  final String topic;
  final int meetingId;
  final String passcode;
  final String joinUrl;
  final DateTime startTime;
  final DateTime endTime;

  String get filename {
    final wib = startTime.toUtc().add(const Duration(hours: 7));
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Undangan-$meetingId-${wib.year}-${two(wib.month)}-${two(wib.day)}.pdf';
  }

  factory InvitationData.fromDetail(
    Map<String, dynamic> detail, {
    required int meetingId,
    String? occurrenceId,
    DateTime? requestedStart,
  }) {
    final id = _number(detail['id']);
    if (id != meetingId ||
        !RegExp(r'^\d{9,11}$').hasMatch(meetingId.toString())) {
      throw const InvitationDataException(
          'Data meeting berubah. Muat ulang daftar jadwal.');
    }

    final type = _number(detail['type']);
    if (type == 3) {
      throw const InvitationDataException(
          'Meeting tanpa waktu tetap belum dapat dibuatkan undangan.');
    }

    Map<String, dynamic> schedule = detail;
    if (type == 8) {
      final occurrences = (detail['occurrences'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .where((item) => item['status'] != 'deleted');
      final requestedUtc = requestedStart?.toUtc();
      final matches = occurrences.where((item) {
        if (occurrenceId?.isNotEmpty == true) {
          return item['occurrence_id']?.toString() == occurrenceId;
        }
        final start = DateTime.tryParse(item['start_time'] as String? ?? '');
        return requestedUtc != null &&
            start != null &&
            start.toUtc().isAtSameMomentAs(requestedUtc);
      });
      if (matches.isEmpty) {
        throw const InvitationDataException(
            'Jadwal berulang ini sudah berubah. Muat ulang daftar jadwal lalu pilih tanggal rapat.');
      }
      schedule = matches.first;
    }

    final startRaw = schedule['start_time'] as String? ?? '';
    final start = DateTime.tryParse(startRaw);
    final duration = _number(schedule['duration']);
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(startRaw) ||
        start == null ||
        duration == null ||
        duration <= 0 ||
        duration > 10080) {
      throw const InvitationDataException(
          'Jadwal meeting belum lengkap. Pilih jadwal rapat yang memiliki waktu pasti.');
    }

    final topic = (detail['topic'] as String? ?? '').trim();
    if (topic.isEmpty || topic.length > 600) {
      throw const InvitationDataException(
          'Topik meeting tidak tersedia atau terlalu panjang untuk undangan.');
    }
    final passcode = detail['password'] as String? ?? '';
    if (passcode.length > 100) {
      throw const InvitationDataException('Passcode meeting tidak valid.');
    }

    final joinUrl = _participantUrl(
        detail['join_url'] as String? ?? '', meetingId.toString());
    return InvitationData._(
      topic: topic,
      meetingId: meetingId,
      passcode: passcode,
      joinUrl: joinUrl,
      startTime: start.toUtc(),
      endTime: start.toUtc().add(Duration(minutes: duration)),
    );
  }
}

int? _number(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

String _participantUrl(String raw, String meetingId) {
  final url = Uri.tryParse(raw);
  final host = url?.host.toLowerCase() ?? '';
  final allowedHost = ['zoom.us', 'zoom.com', 'zoomgov.com']
      .any((domain) => host == domain || host.endsWith('.$domain'));
  final pathId = RegExp(r'^/j/(\d+)/?$').firstMatch(url?.path ?? '')?.group(1);
  final personalLink =
      RegExp(r'^/my/[a-zA-Z0-9._-]+/?$').hasMatch(url?.path ?? '');
  if (raw.isEmpty ||
      raw.length > 2000 ||
      raw.trim() != raw ||
      raw.codeUnits.any((char) => char <= 32 || char == 127) ||
      url?.scheme != 'https' ||
      !allowedHost ||
      url!.userInfo.isNotEmpty ||
      url.hasPort ||
      url.fragment.isNotEmpty ||
      (pathId == null && !personalLink) ||
      (pathId != null && pathId != meetingId) ||
      url.queryParametersAll.keys.any((key) => key.toLowerCase() == 'zak')) {
    throw const InvitationDataException(
        'Undangan memerlukan tautan peserta Zoom yang sesuai dengan Meeting ID.');
  }
  return raw;
}
