import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_envelope.dart';
import '../core/api_error_formatter.dart';
import '../core/app_nav.dart';
import '../core/flavor_config.dart';
import '../core/token_storage.dart';

/// Configures and returns the central Dio client for the mobile application.
/// Includes automatic auth header injection, idempotent request retries,
/// session expiration handling, and structured error formatting.
Dio createAppDio({
  required String baseUrl,
  required TokenStorage tokenStorage,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<bool> refreshAccessToken() async {
    final refresh = await tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final refreshClient = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      );
      final res = await refreshClient.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = tryUnwrapData(res.data);
      final access = data?['accessToken']?.toString();
      if (access == null || access.isEmpty) return false;
      final nextRefresh = data?['refreshToken']?.toString();
      await tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: nextRefresh ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // 1. Auth and Header Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        const publicPaths = [
          '/auth/send-otp',
          '/auth/verify-otp',
          '/auth/admin/login',
          '/auth/refresh',
          '/legal/account-deletion',
          '/legal/',
          '/health',
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
        final path = err.requestOptions.path;
        final alreadyRetriedAuth = err.requestOptions.extra['retriedAuth'] == true;

        if (code == 401 && !path.contains('/auth/refresh') && !alreadyRetriedAuth) {
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            err.requestOptions.extra['retriedAuth'] = true;
            final access = await tokenStorage.readAccessToken();
            if (access != null && access.isNotEmpty) {
              err.requestOptions.headers['Authorization'] = 'Bearer $access';
            }
            try {
              final retryResponse = await dio.fetch(err.requestOptions);
              return handler.resolve(retryResponse);
            } catch (retryErr) {
              if (retryErr is DioException) {
                return handler.next(retryErr);
              }
            }
          }
          await tokenStorage.clear();
          final ctx = appNavigatorKey.currentContext;
          final routeName =
              (ctx != null && ctx.mounted) ? ModalRoute.of(ctx)?.settings.name : null;
          if (routeName != '/auth') {
            onUnauthorized();
          }
        }

        if (code == 403 || code == 429) {
          final parsed = ApiErrorFormatter.format(err);
          final data = res?.data;
          final retry = data is Map<String, dynamic> ? data['retryAfterSeconds'] : null;
          final suffix = retry is int ? ' Retry in ~$retry s.' : '';
          appMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${parsed.message}$suffix'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
            ),
          );
        }

        handler.next(err);
      },
    ),
  );

  // 2. Retry Interceptor for idempotent GET requests
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onError: (err, handler) async {
        final req = err.requestOptions;
        final isGet = req.method.toUpperCase() == 'GET';
        final isConnectionOrTimeout = err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout;

        final hasRetried = req.extra['hasRetried'] == true;

        if (isGet && isConnectionOrTimeout && !hasRetried) {
          req.extra['hasRetried'] = true;
          try {
            await Future.delayed(const Duration(milliseconds: 750));
            final response = await dio.fetch(req);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(err);
          }
        }
        return handler.next(err);
      },
    ),
  );

  if (FlavorConfig.isDev) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  }

  return dio;
}
