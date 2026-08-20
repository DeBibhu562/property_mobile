import 'package:dio/dio.dart';

import '../../core/auth_session.dart';
import '../../core/auth_session_storage.dart';
import '../../core/token_storage.dart';
import '../notifications/device_registration_service.dart';

class AuthRepository {
  AuthRepository(
    this._dio,
    this._tokens,
    this._sessionStorage,
    this._deviceRegistration,
  );

  final Dio _dio;
  final TokenStorage _tokens;
  final AuthSessionStorage _sessionStorage;
  final DeviceRegistrationService _deviceRegistration;

  Future<String?> readAccessToken() => _tokens.readAccessToken();

  Future<void> sendOtp(String phone) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/send-otp',
      data: {'phone': phone},
    );
  }

  Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
    required String name,
    required String role,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {
        'phone': phone,
        'otp': otp,
        'name': name,
        'role': role,
      },
    );
    return _persistAuthResponse(res);
  }

  Future<AuthSession> adminLogin({
    required String identifier,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/admin/login',
      data: {
        'identifier': identifier,
        'password': password,
      },
    );
    return _persistAuthResponse(res);
  }

  Future<AuthSession> _persistAuthResponse(Response<Map<String, dynamic>> res) async {
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Authentication failed',
      );
    }
    final data = root['data'] as Map<String, dynamic>;
    final access = data['accessToken']?.toString();
    if (access == null || access.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'No access token',
      );
    }
    final refresh = data['refreshToken']?.toString();
    await _tokens.saveTokens(accessToken: access, refreshToken: refresh);

    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'No user profile in response',
      );
    }
    final session = AuthSession(user: AuthUser.fromJson(userJson));
    await _sessionStorage.save(session);
    await _deviceRegistration.registerOnLogin();
    return session;
  }

  Future<void> signOut() async {
    await _deviceRegistration.unregisterOnLogout();
    await _tokens.clear();
    await _sessionStorage.clear();
  }
}
