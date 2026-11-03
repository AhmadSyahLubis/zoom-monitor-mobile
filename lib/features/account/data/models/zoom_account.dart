class ZoomAccount {
  final int id;
  final String accountName;
  final String? email;
  final String? hostKey;
  final bool hasToken;

  ZoomAccount({
    required this.id,
    required this.accountName,
    this.email,
    this.hostKey,
    required this.hasToken,
  });

  factory ZoomAccount.fromJson(Map<String, dynamic> json) {
    return ZoomAccount(
      id: json['id'] as int? ?? 0,
      accountName: json['account_name'] as String? ?? 'Akun Zoom',
      email: json['email'] as String?,
      hostKey: json['host_key'] as String?,
      hasToken: json['has_token'] as bool? ?? false,
    );
  }
}

class CheckConnectionResponse {
  final bool isConnected;
  final String accountName;
  final int userCount;
  final String planType;
  final String message;

  CheckConnectionResponse({
    required this.isConnected,
    required this.accountName,
    this.userCount = 1,
    this.planType = 'Licensed',
    required this.message,
  });

  factory CheckConnectionResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase();
    final bool? isConnectedField = json['is_connected'] as bool?;
    final bool? successField = json['success'] as bool?;
    final msg = json['message']?.toString() ?? '';

    // Check if status string indicates connected/success
    final bool isStatusConnected = statusStr == 'connected' ||
        statusStr == 'ok' ||
        statusStr == 'active' ||
        statusStr == 'success';

    // Fallback: check if message text indicates success
    final bool isMessageSuccess = msg.toLowerCase().contains('berhasil') ||
        msg.toLowerCase().contains('success');

    final bool connected = isConnectedField ??
        successField ??
        (isStatusConnected ? true : (msg.isNotEmpty && isMessageSuccess));

    final userCountVal = json['active_users_count'] as int? ??
        json['user_count'] as int? ??
        json['users_count'] as int? ??
        (int.tryParse(json['active_users_count']?.toString() ?? '') ??
            int.tryParse(json['user_count']?.toString() ?? '') ??
            1);

    return CheckConnectionResponse(
      isConnected: connected,
      accountName:
          json['account_name'] as String? ?? json['name'] as String? ?? '',
      userCount: userCountVal,
      planType:
          json['plan_type'] as String? ?? json['type'] as String? ?? 'Licensed',
      message: msg.isNotEmpty
          ? msg
          : (connected
              ? 'Koneksi ke Zoom berhasil diverifikasi'
              : 'Gagal terhubung ke Zoom'),
    );
  }
}
