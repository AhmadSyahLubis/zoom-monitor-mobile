class InviteFormatter {
  static String formatInvite({
    required String topic,
    required String startTimeWib,
    required String endTimeWib,
    required String accountName,
    required String meetingId,
    required String passcode,
    String? hostKey,
    required String joinUrl,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📋 UNDANGAN RAPAT VIRTUAL');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('📌 Topik: $topic');
    buffer.writeln('🕒 Waktu: $startTimeWib - $endTimeWib WIB');
    buffer.writeln('🏢 Ruang/Akun: $accountName');
    buffer.writeln('');
    buffer.writeln('🔗 Link Zoom Meeting:');
    buffer.writeln(joinUrl);
    buffer.writeln('');
    buffer.writeln('🆔 Meeting ID: $meetingId');
    buffer.writeln('🔑 Passcode: $passcode');
    if (hostKey != null && hostKey.isNotEmpty) {
      buffer.writeln('🛡️ Host Key: $hostKey (Gunakan untuk klaim host)');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('Mohon hadir 5 menit sebelum rapat dimulai. Terima kasih.');
    return buffer.toString();
  }
}
