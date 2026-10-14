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

class PinSetupRequest {
  final String pin;
  final String currentPassword;

  PinSetupRequest({
    required this.pin,
    required this.currentPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
      'current_password': currentPassword,
    };
  }
}

class PinLoginRequest {
  final String username;
  final String pin;
  final String deviceId;

  PinLoginRequest({
    required this.username,
    required this.pin,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'pin': pin,
      'device_id': deviceId,
    };
  }
}

class BiometricLoginRequest {
  final String username;
  final String deviceId;
  final String biometricToken;

  BiometricLoginRequest({
    required this.username,
    required this.deviceId,
    required this.biometricToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'device_id': deviceId,
      'biometric_token': biometricToken,
    };
  }
}
