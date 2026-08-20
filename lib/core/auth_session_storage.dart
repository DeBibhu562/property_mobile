import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';

const _kSession = 'propertydilado_auth_session';

class AuthSessionStorage {
  Future<AuthSession?> read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = AuthUser.fromJson(map);
      if (user.id.isEmpty) return null;
      return AuthSession(user: user);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSession, jsonEncode(session.user.toJson()));
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSession);
  }
}
