import 'package:dio/dio.dart';

import 'device_token_provider.dart';

/// Talks to `POST /me/devices` (and `DELETE /me/devices/:token`) to keep the
/// server's device-token registry in sync with the user's session. Wired into
/// the auth flow so:
///
///  - Right after a successful OTP verify → `registerOnLogin()`.
///  - Right before clearing access tokens on sign out → `unregisterOnLogout()`.
///
/// Both calls are BEST-EFFORT: any error (network, 4xx, no Firebase) is
/// swallowed with a debug print rather than thrown. Push registration MUST
/// NOT block login — a user without working push is still a fully functional
/// user.
class DeviceRegistrationService {
  DeviceRegistrationService(this._dio, this._provider);

  final Dio _dio;
  final DeviceTokenProvider _provider;

  Future<void> registerOnLogin() async {
    DeviceTokenInfo? info;
    try {
      info = await _provider.currentToken();
    } catch (e) {
      _logFail('token lookup', e);
      return;
    }
    if (info == null) return;

    try {
      await _dio.post<Map<String, dynamic>>(
        '/me/devices',
        data: <String, dynamic>{
          'token': info.token,
          'platform': info.platform.wireName,
          if (info.appVersion != null) 'appVersion': info.appVersion,
        },
      );
    } on DioException catch (e) {
      _logFail('register', e);
    } catch (e) {
      _logFail('register', e);
    }
  }

  Future<void> unregisterOnLogout() async {
    DeviceTokenInfo? info;
    try {
      info = await _provider.currentToken();
    } catch (e) {
      _logFail('token lookup', e);
      return;
    }
    if (info == null) return;

    final encoded = Uri.encodeComponent(info.token);
    try {
      await _dio.delete<Map<String, dynamic>>('/me/devices/$encoded');
    } on DioException catch (e) {
      // 404 is expected if the server already pruned the token (e.g. after
      // FCM disabled it); not worth surfacing.
      if (e.response?.statusCode == 404) return;
      _logFail('unregister', e);
    } catch (e) {
      _logFail('unregister', e);
    }
  }

  void _logFail(String stage, Object error) {
    // Plain print rather than logger to avoid pulling in a logging dep here;
    // the underlying request's interceptors already emit Dio-level logs.
    // ignore: avoid_print
    print('[device-registration] $stage failed: $error');
  }
}
