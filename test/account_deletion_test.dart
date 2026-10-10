import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/auth_session.dart';
import 'package:propertydilado_mobile/core/auth_session_storage.dart';
import 'package:propertydilado_mobile/core/providers.dart';
import 'package:propertydilado_mobile/core/token_storage.dart';
import 'package:propertydilado_mobile/features/auth/account_deletion_models.dart';
import 'package:propertydilado_mobile/features/auth/auth_repository.dart';
import 'package:propertydilado_mobile/features/entitlement/entitlement_repository.dart';
import 'package:propertydilado_mobile/features/notifications/device_registration_service.dart';
import 'package:propertydilado_mobile/features/notifications/device_token_provider.dart';
import 'package:propertydilado_mobile/ui/delete_account_screen.dart';
import 'package:propertydilado_mobile/ui/profile_screen.dart';

class FakeTokenStorage extends TokenStorage {
  String? token = 'test-token';
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> clear() async {
    token = null;
  }
}

class FakeSessionStorage extends AuthSessionStorage {
  AuthSession? session;
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> save(AuthSession s) async {
    session = s;
  }
  @override
  Future<void> clear() async {
    session = null;
  }
}

void main() {
  group('AccountDeletionPolicy Model Tests', () {
    test('parses complete policy JSON', () {
      final json = {
        'confirmation': 'DELETE',
        'deletesImmediately': true,
        'webUrl': 'https://propertydilado.com/account/delete',
        'supportEmail': 'support@propertydilado.com',
        'api': 'DELETE /me',
        'removes': ['Listings', 'Favorites', 'Profile data'],
        'retains': ['Tax invoices required by law'],
      };

      final policy = AccountDeletionPolicy.fromJson(json);
      expect(policy.confirmation, 'DELETE');
      expect(policy.deletesImmediately, true);
      expect(policy.webUrl, 'https://propertydilado.com/account/delete');
      expect(policy.supportEmail, 'support@propertydilado.com');
      expect(policy.removes.length, 3);
      expect(policy.retains.length, 1);
    });

    test('handles fallback defaults gracefully when fields are missing', () {
      final policy = AccountDeletionPolicy.fromJson({});
      expect(policy.confirmation, 'DELETE');
      expect(policy.deletesImmediately, true);
      expect(policy.supportEmail, 'support@propertydilado.com');
      expect(policy.removes, isEmpty);
      expect(policy.retains, isEmpty);
    });

    test('parses AccountDeletionResult correctly', () {
      final res = AccountDeletionResult.fromJson({
        'deleted': true,
        'deletedAt': '2026-08-23T12:00:00Z',
        'listingsWithdrawn': 4,
      });
      expect(res.deleted, true);
      expect(res.deletedAt, '2026-08-23T12:00:00Z');
      expect(res.listingsWithdrawn, 4);
    });
  });

  group('DeleteAccountScreen Widget Tests', () {
    late FakeTokenStorage fakeTokens;
    late FakeSessionStorage fakeSession;
    late Dio dio;
    late AuthRepository authRepo;

    const dummyPolicy = AccountDeletionPolicy(
      confirmation: 'DELETE',
      deletesImmediately: true,
      webUrl: 'https://propertydilado.com/account/delete',
      supportEmail: 'help@propertydilado.com',
      removes: [
        'Profile information',
        'Active property listings',
      ],
      retains: [
        'Payment receipts for tax compliance',
      ],
    );

    setUp(() {
      fakeTokens = FakeTokenStorage();
      fakeSession = FakeSessionStorage();
      fakeSession.session = const AuthSession(
        user: AuthUser(
          id: 'user-1',
          name: 'Test Buyer',
          phone: '+919876543210',
          role: 'USER',
        ),
      );

      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/legal/account-deletion')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: dummyPolicy.toJson(),
                ),
              );
            }
            if (options.path.contains('/me') && options.method == 'DELETE') {
              final confirmation = (options.data as Map?)?['confirmation'];
              if (confirmation == 'DELETE') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'success': true,
                      'data': {
                        'deleted': true,
                        'deletedAt': '2026-08-23T12:00:00Z',
                        'listingsWithdrawn': 2,
                      },
                    },
                  ),
                );
              }
            }
            return handler.next(options);
          },
        ),
      );

      authRepo = AuthRepository(
        dio,
        fakeTokens,
        fakeSession,
        DeviceRegistrationService(dio, const StubDeviceTokenProvider()),
      );
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          authSessionStorageProvider.overrideWithValue(fakeSession),
          tokenStorageProvider.overrideWithValue(fakeTokens),
        ],
        child: MaterialApp(
          routes: {
            '/auth': (_) => const Scaffold(body: Text('Auth Screen')),
          },
          home: const DeleteAccountScreen(),
        ),
      );
    }

    testWidgets('renders dynamic policy data and handles confirmation validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify title and dynamic policy elements
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.text('Profile information'), findsOneWidget);
      expect(find.text('Active property listings'), findsOneWidget);
      expect(find.text('Payment receipts for tax compliance'), findsOneWidget);
      expect(find.text('https://propertydilado.com/account/delete'), findsOneWidget);

      final deleteButtonFinder = find.widgetWithText(FilledButton, 'Permanently delete account');
      expect(deleteButtonFinder, findsOneWidget);

      // Initially disabled
      final FilledButton buttonBefore = tester.widget(deleteButtonFinder);
      expect(buttonBefore.onPressed, isNull);

      // Check checkbox only -> still disabled
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final FilledButton buttonAfterCheckbox = tester.widget(deleteButtonFinder);
      expect(buttonAfterCheckbox.onPressed, isNull);

      // Enter incorrect phrase -> still disabled
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'INCORRECT');
      await tester.pumpAndSettle();

      final FilledButton buttonAfterWrongPhrase = tester.widget(deleteButtonFinder);
      expect(buttonAfterWrongPhrase.onPressed, isNull);

      // Enter exact matching phrase -> button becomes enabled
      await tester.enterText(textFieldFinder, 'DELETE');
      await tester.pumpAndSettle();

      final FilledButton buttonAfterCorrectPhrase = tester.widget(deleteButtonFinder);
      expect(buttonAfterCorrectPhrase.onPressed, isNotNull);

      // Scroll into view and tap delete button -> triggers double confirmation dialog
      await tester.ensureVisible(deleteButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Final Confirmation'), findsOneWidget);
      expect(find.text('Yes, Permanently Delete'), findsOneWidget);

      // Confirm deletion in dialog
      await tester.tap(find.text('Yes, Permanently Delete'));
      await tester.pumpAndSettle();

      // Verifies navigation to /auth
      expect(find.text('Auth Screen'), findsOneWidget);
    });

    testWidgets('shows admin forbidden dialog if 403 occurs', (WidgetTester tester) async {
      // Re-configure Dio to return 403 for DELETE /me
      final errorDio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      errorDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/legal/account-deletion')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: dummyPolicy.toJson(),
                ),
              );
            }
            if (options.path.contains('/me') && options.method == 'DELETE') {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 403,
                    data: {'error': 'Admin accounts cannot self-delete.'},
                  ),
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final errorAuthRepo = AuthRepository(
        errorDio,
        fakeTokens,
        fakeSession,
        DeviceRegistrationService(errorDio, const StubDeviceTokenProvider()),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(errorAuthRepo),
            authSessionStorageProvider.overrideWithValue(fakeSession),
            tokenStorageProvider.overrideWithValue(fakeTokens),
          ],
          child: const MaterialApp(home: DeleteAccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check checkbox & enter DELETE
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();

      // Tap delete
      final deleteBtnFinder = find.widgetWithText(FilledButton, 'Permanently delete account');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.text('Yes, Permanently Delete'));
      await tester.pumpAndSettle();

      // Expect Admin Notice with support email
      expect(find.text('Admin Account Notice'), findsOneWidget);
      expect(find.text('help@propertydilado.com'), findsOneWidget);
      expect(find.text('Copy Email'), findsOneWidget);
    });
  });

  group('AuthRepository Account Deletion Methods', () {
    test('getAccountDeletionPolicy calls /legal/account-deletion', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'confirmation': 'DELETE',
                  'deletesImmediately': true,
                  'webUrl': 'https://propertydilado.com/account/delete',
                  'supportEmail': 'support@propertydilado.com',
                  'removes': ['Item 1'],
                  'retains': ['Item 2'],
                },
              ),
            );
          },
        ),
      );

      final tokens = FakeTokenStorage();
      final session = FakeSessionStorage();
      final repo = AuthRepository(
        dio,
        tokens,
        session,
        DeviceRegistrationService(dio, const StubDeviceTokenProvider()),
      );

      final policy = await repo.getAccountDeletionPolicy();
      expect(policy.confirmation, 'DELETE');
      expect(policy.removes, ['Item 1']);
      expect(policy.retains, ['Item 2']);
    });

    test('deleteAccount calls DELETE /me and clears session and tokens', () async {
      var deleteCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/me' && options.method == 'DELETE') {
              deleteCalled = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'deleted': true,
                      'deletedAt': '2026-08-23T12:00:00Z',
                      'listingsWithdrawn': 1,
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final tokens = FakeTokenStorage();
      final session = FakeSessionStorage();
      session.session = const AuthSession(
        user: AuthUser(
          id: 'user-1',
          name: 'Test',
          phone: '+919876543210',
          role: 'USER',
        ),
      );

      final repo = AuthRepository(
        dio,
        tokens,
        session,
        DeviceRegistrationService(dio, const StubDeviceTokenProvider()),
      );

      final result = await repo.deleteAccount(confirmation: 'DELETE');
      expect(deleteCalled, isTrue);
      expect(result.deleted, isTrue);
      expect(await tokens.readAccessToken(), isNull);
      expect(await session.read(), isNull);
    });
  });

  group('ProfileScreen Account Deletion Link', () {
    testWidgets('displays Danger Zone and Delete account button navigating to /delete-account',
        (WidgetTester tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/me/entitlements')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'tier': 'FREE',
                      'isFree': true,
                      'source': 'test',
                      'usage': {'activeListings': 0},
                      'limits': {},
                      'features': {},
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final tokens = FakeTokenStorage();
      final session = FakeSessionStorage();
      session.session = const AuthSession(
        user: AuthUser(
          id: 'user-1',
          name: 'Jane Doe',
          phone: '+919876543210',
          role: 'USER',
        ),
      );

      final entitlementRepo = EntitlementRepository(dio);
      final authRepo = AuthRepository(
        dio,
        tokens,
        session,
        DeviceRegistrationService(dio, const StubDeviceTokenProvider()),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            authSessionStorageProvider.overrideWithValue(session),
            tokenStorageProvider.overrideWithValue(tokens),
            entitlementRepositoryProvider.overrideWithValue(entitlementRepo),
          ],
          child: MaterialApp(
            routes: {
              '/delete-account': (_) =>
                  const Scaffold(body: Text('Delete Account Screen Destination')),
            },
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danger zone'), findsOneWidget);
      final deleteTileFinder = find.text('Delete account');
      expect(deleteTileFinder, findsOneWidget);

      await tester.ensureVisible(deleteTileFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteTileFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete Account Screen Destination'), findsOneWidget);
    });
  });
}
