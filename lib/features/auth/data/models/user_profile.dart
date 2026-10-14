class UserProfile {
  final int id;
  final String name;
  final String username;
  final String? email;
  final bool hasPin;
  final bool biometricEnabled;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    required this.hasPin,
    required this.biometricEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      hasPin: json['has_pin'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'has_pin': hasPin,
      'biometric_enabled': biometricEnabled,
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    bool? hasPin,
    bool? biometricEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
