import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/api_error_formatter.dart';
import 'package:propertydilado_mobile/core/network_exceptions.dart';
import 'package:propertydilado_mobile/ui/widgets/app_error_state.dart';

void main() {
  group('ApiErrorFormatter Tests', () {
    test('formats SocketException connection refused into user-friendly exception', () {
      const socketException = SocketException('OS Error: Connection refused, errno = 111', port: 50868);
      final formatted = ApiErrorFormatter.format(socketException);

      expect(formatted.category, NetworkErrorCategory.serverUnreachable);
      expect(formatted.title, 'Connection Refused');
      expect(formatted.message, contains('Unable to reach the backend server'));
      expect(formatted.isConnectionIssue, isTrue);
      expect(formatted.technicalDetails, contains('50868'));
      // toString() returns user-facing message, not raw stack
      expect(formatted.toString(), formatted.message);
    });

    test('formats DioException connectionError into user-friendly exception', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/search/browse'),
        type: DioExceptionType.connectionError,
        message: 'The connection errored: Connection refused',
      );
      final formatted = ApiErrorFormatter.format(dioException);

      expect(formatted.category, NetworkErrorCategory.serverUnreachable);
      expect(formatted.title, 'Cannot Reach Server');
      expect(formatted.message, contains('Unable to connect to the backend server'));
      expect(formatted.isConnectionIssue, isTrue);
    });

    test('formats DioException timeout into Request Timed Out', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/properties'),
        type: DioExceptionType.connectionTimeout,
      );
      final formatted = ApiErrorFormatter.format(dioException);

      expect(formatted.category, NetworkErrorCategory.timeout);
      expect(formatted.title, 'Request Timed Out');
      expect(formatted.message, contains('longer than usual'));
    });

    test('formats HTTP 401 into Session Expired', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/me/entitlements'),
        response: Response(
          requestOptions: RequestOptions(path: '/me/entitlements'),
          statusCode: 401,
          data: {'error': 'Token expired'},
        ),
      );
      final formatted = ApiErrorFormatter.format(dioException);

      expect(formatted.category, NetworkErrorCategory.unauthorized);
      expect(formatted.title, 'Session Expired');
      expect(formatted.message, 'Token expired');
    });

    test('formats HTTP 403 into Access Restricted', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/admin/moderation'),
        response: Response(
          requestOptions: RequestOptions(path: '/admin/moderation'),
          statusCode: 403,
          data: {'error': 'Admin privileges required'},
        ),
      );
      final formatted = ApiErrorFormatter.format(dioException);

      expect(formatted.category, NetworkErrorCategory.forbidden);
      expect(formatted.title, 'Access Restricted');
      expect(formatted.message, 'Admin privileges required');
    });

    test('formats HTTP 500 into Server Error with graceful fallback', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/search/suggestions'),
        response: Response(
          requestOptions: RequestOptions(path: '/search/suggestions'),
          statusCode: 500,
        ),
      );
      final formatted = ApiErrorFormatter.format(dioException);

      expect(formatted.category, NetworkErrorCategory.serverError);
      expect(formatted.title, 'Server Error');
      expect(formatted.message, contains('Please try again shortly'));
    });

    test('handles raw string error gracefully', () {
      final formatted = ApiErrorFormatter.format('SocketException: Connection refused (OS Error: Connection refused)');

      expect(formatted.category, NetworkErrorCategory.serverUnreachable);
      expect(formatted.title, 'Server Unreachable');
      expect(formatted.message, contains('Unable to connect'));
    });
  });

  group('AppErrorState Widget Tests', () {
    testWidgets('renders user friendly title, message, and retry button', (tester) async {
      var retried = false;
      const socketException = SocketException('Connection refused', port: 3000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              error: socketException,
              onRetry: () async {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Connection Refused'), findsOneWidget);
      expect(find.textContaining('Unable to reach the backend server'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('renders compact mode with secondary action', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              error: 'Something went wrong',
              compact: true,
              secondaryLabel: 'Close',
              onSecondaryAction: () {
                closed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('renders in dark mode cleanly without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AppErrorState(
              error: 'Test dark mode',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
    });
  });
}
