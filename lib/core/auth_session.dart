import 'app_persona.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? email;

  AppPersona get persona => AppPersona.fromApiRole(role);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        if (email != null) 'email': email,
      };
}

class AuthSession {
  const AuthSession({required this.user});

  final AuthUser user;

  AppPersona get persona => user.persona;
}
