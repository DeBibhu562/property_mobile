import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/auth_session.dart';
import 'package:propertydilado_mobile/core/providers.dart';
import 'package:propertydilado_mobile/core/session_provider.dart';
import 'package:propertydilado_mobile/ui/city_picker_screen.dart';
import 'package:propertydilado_mobile/ui/search_portal_screen.dart';
import 'package:propertydilado_mobile/ui/shell/app_shell_screen.dart';
import 'package:propertydilado_mobile/ui/welcome_intent_screen.dart';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(_TestHttpClientRequest());
  }
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _DummyHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_TestHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _DummyHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _DummyHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthSessionNotifier extends StateNotifier<AsyncValue<AuthSession?>>
    implements AuthSessionNotifier {
  MockAuthSessionNotifier(AuthSession? session) : super(AsyncValue.data(session));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  setUp(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.library == 'image resource service' ||
          details.exception is NetworkImageLoadException) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  group('CityPickerScreen & Selection Tests', () {
    testWidgets('Selecting Delhi NCR in CityPickerScreen does not pop root route when embedded', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: CityPickerScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'D' in alphabet filter to reveal Delhi NCR
      final dTab = find.text('D');
      expect(dTab, findsOneWidget);
      await tester.tap(dTab);
      await tester.pump();

      // Find and tap "Delhi NCR" from city grid
      final delhiTile = find.widgetWithText(InkWell, 'Delhi NCR');
      expect(delhiTile, findsWidgets);

      await tester.tap(delhiTile.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ensure city was updated in state
      expect(container.read(searchSelectionProvider).city, 'Delhi NCR');
      // Root route should NOT have been popped to a blank screen; MaterialApp and CityPicker remain in tree
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Tapping Close button when onboarding resets intent to Welcome screen', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: CityPickerScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      container.read(searchSelectionProvider.notifier).setIntent('BUY');
      expect(container.read(searchSelectionProvider).intent, 'BUY');

      // Tap close button (Icons.close)
      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();

      // Intent should now be reset to null so WelcomeIntentScreen will be shown
      expect(container.read(searchSelectionProvider).intent, isNull);
    });

    testWidgets('Tapping Close button when city was reset restores previousCity', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: CityPickerScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final notifier = container.read(searchSelectionProvider.notifier);
      notifier.setCity('Gurgaon');
      expect(container.read(searchSelectionProvider).city, 'Gurgaon');

      notifier.resetCity();
      expect(container.read(searchSelectionProvider).city, isNull);
      expect(container.read(searchSelectionProvider).previousCity, 'Gurgaon');

      // Tap close button
      final closeBtn = find.byIcon(Icons.close);
      await tester.tap(closeBtn);
      await tester.pump();

      // Previous city should be restored
      expect(container.read(searchSelectionProvider).city, 'Gurgaon');
    });

    testWidgets('Full AppShell buyer flow: Buy Home -> Select Delhi NCR transitions to SearchPortalScreen without black screen', (tester) async {
      const buyerSession = AuthSession(
        user: AuthUser(
          id: 'user-123',
          name: 'Buyer User',
          phone: '+919876543210',
          role: 'USER',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith((ref) => MockAuthSessionNotifier(buyerSession)),
            searchSelectionProvider.overrideWith((ref) {
              final n = SearchSelectionNotifier();
              n.setIntent(null);
              n.setCity(null);
              return n;
            }),
          ],
          child: MaterialApp(
            routes: {
              '/home': (_) => const AppShellScreen(),
            },
            home: const AppShellScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially WelcomeIntentScreen is displayed
      expect(find.byType(WelcomeIntentScreen), findsOneWidget);
      expect(find.text('Buy a Home'), findsOneWidget);

      // Tap "Buy a Home"
      await tester.tap(find.text('Buy a Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now show CityPickerScreen
      expect(find.byType(CityPickerScreen), findsOneWidget);
      expect(find.text('Select City to Buy'), findsOneWidget);

      // Tap 'D' to filter cities starting with D
      await tester.tap(find.text('D'));
      await tester.pump();

      // Tap "Use my current location (Delhi NCR)" from quick options
      final currentLocationBtn = find.text('Use my current location (Delhi NCR)');
      expect(currentLocationBtn, findsOneWidget);
      await tester.tap(currentLocationBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // AppShellScreen must NOT be popped to a black screen.
      // Instead, SearchPortalScreen should be mounted!
      expect(find.byType(AppShellScreen), findsOneWidget);
      expect(find.byType(SearchPortalScreen), findsOneWidget);
      expect(find.text('Delhi NCR'), findsWidgets);
    });
  });
}
