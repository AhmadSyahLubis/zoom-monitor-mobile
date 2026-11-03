class LoginRequest {
  final String username;
  final String password;
  final String deviceId;
  final String deviceName;

  LoginRequest({
    required this.username,
    required this.password,
    required this.deviceId,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'device_id': deviceId,
      'device_name': deviceName,
    };
  }
}

class BiometricLoginRequest {
  final String username;
  final String deviceId;
  final String challengeId;
  final String signature;

  BiometricLoginRequest({
    required this.username,
    required this.deviceId,
    required this.challengeId,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'device_id': deviceId,
      'challenge_id': challengeId,
      'signature': signature,
    };
  }
}
