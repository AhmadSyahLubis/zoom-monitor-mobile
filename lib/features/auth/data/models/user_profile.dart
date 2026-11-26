class UserProfile {
  final int id;
  final String name;
  final String username;
  final String? email;
  final bool hasPin;
  final bool biometricEnabled;
  final String role;
  final OpdProfile? opd;
  bool get isAdmin =>
      role == 'admin' && opd?.code == 'diskominfo' && opd?.isActive == true;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    required this.hasPin,
    required this.biometricEnabled,
    this.role = 'user',
    this.opd,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      hasPin: json['has_pin'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
      opd: json['opd'] is Map<String, dynamic>
          ? OpdProfile.fromJson(json['opd'] as Map<String, dynamic>)
          : null,
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
      'role': role,
      'opd': opd?.toJson(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    bool? hasPin,
    bool? biometricEnabled,
    String? role,
    OpdProfile? opd,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      role: role ?? this.role,
      opd: opd ?? this.opd,
    );
  }
}

class OpdProfile {
  final int id;
  final String code;
  final String name;
  final bool isActive;

  const OpdProfile(
      {required this.id,
      required this.code,
      required this.name,
      required this.isActive});

  factory OpdProfile.fromJson(Map<String, dynamic> json) => OpdProfile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'code': code, 'name': name, 'is_active': isActive};
}
