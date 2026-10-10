import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/auth_session.dart';
import 'package:propertydilado_mobile/core/auth_session_storage.dart';
import 'package:propertydilado_mobile/core/providers.dart';
import 'package:propertydilado_mobile/core/token_storage.dart';
import 'package:propertydilado_mobile/features/auth/auth_repository.dart';
import 'package:propertydilado_mobile/features/notifications/device_registration_service.dart';
import 'package:propertydilado_mobile/features/notifications/device_token_provider.dart';
import 'package:propertydilado_mobile/ui/widgets/lead_inquiry_modal.dart';

class FakeTokenStorage extends TokenStorage {
  String? token = 'mock-access-token';
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    token = accessToken;
  }
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
  group('SCR-10: Lead Generation & Email OTP Verification Modal Tests', () {
    late FakeTokenStorage fakeTokens;
    late FakeSessionStorage fakeSession;
    late Dio fakeDio;
    late AuthRepository testAuthRepo;

    setUp(() {
      fakeTokens = FakeTokenStorage();
      fakeSession = FakeSessionStorage();
      fakeDio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

      fakeDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Mock send OTP
            if (options.path.contains('/auth/send-otp') && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'message': 'OTP sent successfully'},
                ),
              );
            }
            // Mock verify OTP
            if (options.path.contains('/auth/verify-otp') && options.method == 'POST') {
              final body = options.data is Map ? options.data as Map : {};
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'user': {
                        'id': 'usr-123',
                        'email': body['email'] ?? 'test@example.com',
                        'name': body['name'] ?? 'Test Buyer',
                        'role': 'USER',
                      },
                      'accessToken': 'jwt-access-token-123',
                      'refreshToken': 'jwt-refresh-token-123',
                    },
                  },
                ),
              );
            }
            // Mock lead submission
            if (options.path.contains('/leads') && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {'success': true, 'data': {'id': 'lead-999'}},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      testAuthRepo = AuthRepository(
        fakeDio,
        fakeTokens,
        fakeSession,
        DeviceRegistrationService(fakeDio, const StubDeviceTokenProvider()),
      );
    });

    Widget buildTestApp() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(testAuthRepo),
          authSessionStorageProvider.overrideWithValue(fakeSession),
          tokenStorageProvider.overrideWithValue(fakeTokens),
          dioProvider.overrideWithValue(fakeDio),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    LeadInquiryModal.show(
                      ctx,
                      listingId: 'listing-456',
                      title: 'Luxury 3 BHK Heights',
                      price: '₹ 1.25 Cr',
                      locality: 'Sector 62',
                      city: 'Noida',
                      ownerName: 'Mr. Rajesh Verma',
                      ownerPhone: '+91 98765 43210',
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    void setPhoneScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5; // 432 x 960 logical viewport
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('Renders inquiry form with reduced height and listing details', (tester) async {
      setPhoneScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Property header pill
      expect(find.text('Luxury 3 BHK Heights'), findsOneWidget);
      expect(find.text('₹ 1.25 Cr'), findsOneWidget);
      expect(find.textContaining('Sector 62, Noida'), findsOneWidget);

      // Modal titles & intent chips
      expect(find.text('Contact Advertiser'), findsOneWidget);
      expect(find.text('Schedule a Site Visit'), findsOneWidget);
      expect(find.text('Get Best Price Quote'), findsOneWidget);
      expect(find.text('Floor Plan & Brochure'), findsOneWidget);

      // Action button
      final btnFinder = find.text('Verify Email & Contact Advertiser →');
      await tester.ensureVisible(btnFinder);
      expect(btnFinder, findsOneWidget);
    });

    testWidgets('Shows error message if email is invalid', (tester) async {
      setPhoneScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Clear email and type invalid email in the email TextField (the second TextField)
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // Name and Email
      await tester.enterText(textFields.at(1), 'invalid-email');
      await tester.pumpAndSettle();

      final btnFinder = find.text('Verify Email & Contact Advertiser →');
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Submits email, displays OTP screen, enters 6 digits and verifies', (tester) async {
      setPhoneScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap Proceed
      final btnFinder = find.text('Verify Email & Contact Advertiser →');
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Verify OTP screen appears
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.textContaining('ashishtayal2022@gmail.com'), findsWidgets);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Resend OTP via Email'), findsOneWidget);

      // Enter 6 digit OTP: '1', '2', '3', '4', '5', '6'
      final otpFields = find.byType(TextFormField);
      expect(otpFields, findsNWidgets(6));
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
      }
      await tester.pump();
      await tester.pumpAndSettle();

      // Success view checks
      expect(find.text('Thank You! Enquiry Dispatched'), findsOneWidget);
      expect(find.text('Mr. Rajesh Verma'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Explore Similar Verified Properties'), findsOneWidget);
      expect(find.text('DLF The Crest Luxury Residence'), findsOneWidget);
      expect(find.text('Godrej Woods Sky Sanctuary'), findsOneWidget);
    });

    testWidgets('Allows editing email in OTP screen to return to form', (tester) async {
      setPhoneScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      final btnFinder = find.text('Verify Email & Contact Advertiser →');
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsOneWidget);

      // Tap 'Edit' pill button
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Back at inquiry form
      expect(find.text('Contact Advertiser'), findsOneWidget);
      final returnBtnFinder = find.text('Verify Email & Contact Advertiser →');
      await tester.ensureVisible(returnBtnFinder);
      expect(returnBtnFinder, findsOneWidget);
    });
  });
}
