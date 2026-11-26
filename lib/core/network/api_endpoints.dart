class ApiEndpoints {
  static const String opds = '/opds';
  static const String opdAccounts = '/opd-accounts';
  static const String adminHealth = '/admin/health';
  static String opdAccount(int id) => '/opd-accounts/$id';
  static const String requestLetters = '/meeting-request-letters';
  static const String meetingRequests = '/meeting-requests';
  static const String meetingHistory = '/meeting-requests/history';
  static String meetingRequest(String id) => '/meeting-requests/$id';
  static String requestOptions(String id) => '/meeting-requests/$id/options';
  static String requestApprove(String id) => '/meeting-requests/$id/approve';
  static String requestReject(String id) => '/meeting-requests/$id/reject';
  static String requestReconcile(String id) =>
      '/meeting-requests/$id/reconcile';
  static String requestInvitation(String id) =>
      '/meeting-requests/$id/invitation';
  static String requestHostAccess(String id) =>
      '/meeting-requests/$id/host-access';
  static String requestRecording(String id) =>
      '/meeting-requests/$id/recording';
  static String requestLetter(String id) => '/meeting-requests/$id/letter';
  static String requestLetterContent(String id) =>
      '/meeting-requests/$id/letter/content';
  // Health
  static const String health = '/health';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String biometricEnable = '/auth/biometric/enable';
  static const String biometricDisable = '/auth/biometric/disable';
  static const String biometricLogin = '/auth/biometric/login';
  static const String biometricChallenge = '/auth/biometric/challenge';
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
  static String meetingDetails(int accountId, int meetingId) =>
      '/bookings/$accountId/$meetingId/details';
  static String meetingById(dynamic meetingId) => '/bookings/$meetingId';
  static String endMeeting(dynamic meetingId) => '/bookings/$meetingId/end';

  // Cloud Recordings
  static const String recordings = '/recordings';

  // Zoom Accounts Management
  static const String accounts = '/accounts';
  static String accountById(int id) => '/accounts/$id';
  static String checkAccount(int id) => '/accounts/$id/check';
}
