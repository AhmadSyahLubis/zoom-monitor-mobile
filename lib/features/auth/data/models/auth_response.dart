import 'user_profile.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile user;
  final bool hasPin;
  final bool biometricEnabled;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.hasPin,
    required this.biometricEnabled,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 900,
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : UserProfile(id: 0, name: '', username: '', hasPin: false, biometricEnabled: false),
      hasPin: json['has_pin'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }
}
