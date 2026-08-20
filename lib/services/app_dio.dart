import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/app_nav.dart';
import '../core/flavor_config.dart';
import '../core/token_storage.dart';

String? _readApiErrorMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final err = data['error'];
    if (err is String && err.isNotEmpty) return err;
    if (err is List && err.isNotEmpty && err.first is String) return err.join(', ');
  }
  return null;
}

Dio createAppDio({
  required String baseUrl,
  required TokenStorage tokenStorage,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Public auth endpoints must NOT send a Bearer token — an expired
        // stored token causes a 401 loop on the login screen.
        const publicPaths = [
          '/auth/send-otp',
          '/auth/verify-otp',
          '/auth/admin/login',
          '/auth/refresh',
        ];
        final isPublic = publicPaths.any((p) => options.path.contains(p));

        if (!isPublic) {
          final t = await tokenStorage.readAccessToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final res = err.response;
        final code = res?.statusCode;
        final data = res?.data;

        if (code == 401) {
          await tokenStorage.clear();
          // Avoid redirect loop if already on the auth screen
          final ctx = appNavigatorKey.currentContext;
          final routeName = ctx != null ? ModalRoute.of(ctx)?.settings.name : null;
          if (routeName != '/auth') {
            onUnauthorized();
          }
        }

        if (code == 403 || code == 429) {
          final msg = _readApiErrorMessage(data) ??
              (code == 403
                  ? 'You do not have permission for this action.'
                  : 'Too many requests. Please wait and try again.');
          final retry = data is Map<String, dynamic> ? data['retryAfterSeconds'] : null;
          final suffix = retry is int ? ' Retry in ~$retry s.' : '';
          appMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('$msg$suffix'), behavior: SnackBarBehavior.floating),
          );
        }

        handler.next(err);
      },
    ),
  );


  if (FlavorConfig.isDev) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  }

  return dio;
}
