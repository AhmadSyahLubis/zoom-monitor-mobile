import 'package:intl/intl.dart';

class DateTimeUtil {
  static final DateFormat dateWibFormat = DateFormat('dd MMM yyyy');
  static final DateFormat timeWibFormat = DateFormat('HH:mm');
  static final DateFormat fullWibFormat = DateFormat('dd MMM yyyy, HH:mm');

  /// Parse ISO 8601 string dan konversi ke WIB (UTC+7)
  static DateTime parseToWib(String isoString) {
    if (isoString.isEmpty) return DateTime.now();
    try {
      final parsed = DateTime.parse(isoString);
      final utc = parsed.toUtc();
      final wib = utc.add(const Duration(hours: 7));
      return DateTime(wib.year, wib.month, wib.day, wib.hour, wib.minute, wib.second);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Format lengkap tanggal dan jam WIB: "13 Okt 2026, 14:00 WIB"
  static String formatWib(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final wib = parseToWib(isoString);
      return '${fullWibFormat.format(wib)} WIB';
    } catch (_) {
      return isoString;
    }
  }

  /// Format hanya jam WIB: "14:00 WIB"
  static String formatTimeOnlyWib(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final wib = parseToWib(isoString);
      return '${timeWibFormat.format(wib)} WIB';
    } catch (_) {
      return isoString;
    }
  }

  /// Format hanya tanggal WIB: "13 Okt 2026"
  static String formatDateOnlyWib(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final wib = parseToWib(isoString);
      return dateWibFormat.format(wib);
    } catch (_) {
      return isoString;
    }
  }

  /// Format range waktu WIB: "14:00 - 15:30 WIB"
  static String formatTimeRangeWib(String startIso, String endIso) {
    try {
      final start = parseToWib(startIso);
      final end = parseToWib(endIso);
      return '${timeWibFormat.format(start)} - ${timeWibFormat.format(end)} WIB';
    } catch (_) {
      return '$startIso - $endIso';
    }
  }

  /// Greeting berdasarkan jam WIB
  static String getGreeting() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final hour = now.hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }
}
