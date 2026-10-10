import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_repository.dart';
import 'auth_session.dart';
import 'auth_session_storage.dart';
import 'providers.dart';

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AsyncValue<AuthSession?>>((ref) {
  return AuthSessionNotifier(
    ref.read(authSessionStorageProvider),
    ref.read(authRepositoryProvider),
  );
});

class AuthSessionNotifier extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthSessionNotifier(this._storage, this._auth) : super(const AsyncValue.loading());

  final AuthSessionStorage _storage;
  final AuthRepository _auth;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final session = await _storage.read();
    final token = await _auth.readAccessToken();
    if (token == null || token.isEmpty) {
      await _storage.clear();
      state = const AsyncValue.data(null);
      return;
    }
    state = AsyncValue.data(session);
  }

  Future<void> setSession(AuthSession session) async {
    await _storage.save(session);
    state = AsyncValue.data(session);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _storage.clear();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount(String confirmation) async {
    await _auth.deleteAccount(confirmation: confirmation);
    await _storage.clear();
    state = const AsyncValue.data(null);
  }
}
