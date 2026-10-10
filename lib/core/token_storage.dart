import 'package:shared_preferences/shared_preferences.dart';

const _kAccess = 'propertydilado_access_token';
const _kRefresh = 'propertydilado_refresh_token';

class TokenStorage {
  Future<String?> readAccessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  Future<String?> readRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await p.setString(_kRefresh, refreshToken);
    }
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }
}
