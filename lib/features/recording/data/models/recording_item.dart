class RecordingFile {
  final String fileType;
  final String fileExtension;
  final int fileSize;
  final String downloadUrl;
  final String playUrl;
  final String recordingType;
  final String status;

  RecordingFile({
    required this.fileType,
    required this.fileExtension,
    required this.fileSize,
    required this.downloadUrl,
    required this.playUrl,
    required this.recordingType,
    required this.status,
  });

  factory RecordingFile.fromJson(Map<String, dynamic> json) {
    return RecordingFile(
      fileType: json['file_type'] as String? ?? '',
      fileExtension: json['file_extension'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
      playUrl: json['play_url'] as String? ?? '',
      recordingType: json['recording_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'file_type': fileType,
        'file_extension': fileExtension,
        'file_size': fileSize,
        'download_url': downloadUrl,
        'play_url': playUrl,
        'recording_type': recordingType,
        'status': status,
      };
}

class RecordingItem {
  final int meetingId;
  final String uuid;
  final String topic;
  final String startTime;
  final int duration;
  final int totalSize;
  final String shareUrl;
  final int recordingCount;
  final List<RecordingFile> recordingFiles;
  final String accountName;
  final int accountId;
  final String hostName;
  final String hostEmail;

  RecordingItem({
    required this.meetingId,
    required this.uuid,
    required this.topic,
    required this.startTime,
    required this.duration,
    required this.totalSize,
    required this.shareUrl,
    required this.recordingCount,
    required this.recordingFiles,
    required this.accountName,
    required this.accountId,
    required this.hostName,
    required this.hostEmail,
  });

  String get formattedTotalSize {
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory RecordingItem.fromJson(Map<String, dynamic> json) {
    return RecordingItem(
      meetingId: (json['meeting_id'] is num)
          ? (json['meeting_id'] as num).toInt()
          : int.tryParse(json['meeting_id']?.toString() ?? '') ?? 0,
      uuid: json['uuid'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? 0,
      shareUrl: json['share_url'] as String? ?? '',
      recordingCount: json['recording_count'] as int? ?? 0,
      recordingFiles: (json['recording_files'] as List? ?? [])
          .map((e) => RecordingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountName: json['account_name'] as String? ?? '',
      accountId: json['account_id'] as int? ?? 0,
      hostName: json['host_name'] as String? ?? '',
      hostEmail: json['host_email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'meeting_id': meetingId,
        'uuid': uuid,
        'topic': topic,
        'start_time': startTime,
        'duration': duration,
        'total_size': totalSize,
        'share_url': shareUrl,
        'recording_count': recordingCount,
        'recording_files': recordingFiles.map((e) => e.toJson()).toList(),
        'account_name': accountName,
        'account_id': accountId,
        'host_name': hostName,
        'host_email': hostEmail,
      };
}
