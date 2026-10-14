class ApiEndpoints {
  // Health
  static const String health = '/health';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String pinSetup = '/auth/pin/setup';
  static const String pinLogin = '/auth/pin/login';
  static const String biometricEnable = '/auth/biometric/enable';
  static const String biometricDisable = '/auth/biometric/disable';
  static const String biometricLogin = '/auth/biometric/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Dashboard Monitoring
  static const String dashboard = '/dashboard';
  static String accountStatus(int id) => '/dashboard/$id/status';
  static String accountSpecs(int id) => '/dashboard/$id/specs';

  // Booking & Meetings
  static const String bookings = '/bookings';
  static const String searchAvailability = '/bookings/search';
  static String meetingDetails(int accountId, int meetingId) => '/bookings/$accountId/$meetingId/details';
  static String meetingById(dynamic meetingId) => '/bookings/$meetingId';
  static String endMeeting(dynamic meetingId) => '/bookings/$meetingId/end';

  // Cloud Recordings
  static const String recordings = '/recordings';

  // Zoom Accounts Management
  static const String accounts = '/accounts';
  static String accountById(int id) => '/accounts/$id';
  static String checkAccount(int id) => '/accounts/$id/check';
}
