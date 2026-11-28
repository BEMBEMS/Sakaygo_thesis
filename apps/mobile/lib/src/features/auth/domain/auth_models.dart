enum AppRole {
  passenger('passenger', 'Passenger'),
  driver('driver', 'Driver'),
  admin('admin', 'Administrator'),
  lgu('lgu', 'LGU'),
  toda('toda', 'TODA');

  const AppRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  bool get isAdministrative =>
      this == AppRole.admin || this == AppRole.lgu || this == AppRole.toda;

  static AppRole fromWireValue(String value) {
    return AppRole.values.firstWhere(
      (role) => role.wireValue == value,
      orElse: () => throw FormatException('Unknown role: $value'),
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    this.email,
    this.phoneNumber,
    this.verificationStatus,
    this.driverId,
    this.operatingZoneId,
  });

  final String userId;
  final String username;
  final AppRole role;
  final String firstName;
  final String lastName;
  final bool isActive;
  final String? email;
  final String? phoneNumber;
  final String? verificationStatus;
  final String? driverId;
  final String? operatingZoneId;

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: AppRole.fromWireValue(json['role'] as String? ?? 'passenger'),
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      email: json['email'] as String?,
      phoneNumber:
          json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      verificationStatus: json['verification_status'] as String? ??
          json['verificationStatus'] as String?,
      driverId: json['driver_id'] as String? ?? json['driverId'] as String?,
      operatingZoneId: json['operating_zone_id'] as String? ??
          json['operatingZoneId'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    final user = json['user'];

    if (token == null || token.isEmpty || user is! Map<String, dynamic>) {
      throw const FormatException('Invalid auth session payload');
    }

    return AuthSession(token: token, user: AuthUser.fromJson(user));
  }
}
