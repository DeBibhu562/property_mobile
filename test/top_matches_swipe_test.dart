import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/features/property/property_models.dart';
import 'package:propertydilado_mobile/ui/top_matches_screen.dart';
import 'package:propertydilado_mobile/ui/widgets/tinder_swipe_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProperty = PropertyItem(
    id: 'prop-test-1',
    title: '3 BHK Ultra Luxury Apartment in DLF Phase 5',
    price: 33600000,
    city: 'Gurugram',
    locality: 'DLF Phase 5',
    listingType: 'RESIDENTIAL',
    bhk: 3,
    builtUpArea: 2150,
    isVerified: true,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
  );

  group('SCR-07 TinderSwipeCard Unit & Widget Tests', () {
    testWidgets('renders property card details, price, and badges correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TinderSwipeCard(
              property: testProperty,
              dragDx: 0.0,
              isTopCard: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₹3.36 Cr'), findsOneWidget);
      expect(find.text('3 BHK • 2150 sqft'), findsOneWidget);
      expect(find.text('3 BHK Ultra Luxury Apartment in DLF Phase 5'), findsOneWidget);
      expect(find.text('DLF Phase 5, Gurugram'), findsOneWidget);
      expect(find.text('Transaction: New Property'), findsOneWidget);
      expect(find.text('Verified Property'), findsOneWidget);
      expect(find.text('98% Match'), findsOneWidget);
      expect(find.text('Posted Recently'), findsOneWidget);
      expect(find.text('1/3 Photos'), findsOneWidget);
    });

    testWidgets('shows CONNECT stamp on positive horizontal drag (Right Swipe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TinderSwipeCard(
              property: testProperty,
              dragDx: 120.0,
              isTopCard: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONNECT'), findsOneWidget);
      expect(find.text('NOT DECIDED YET'), findsNothing);
    });

    testWidgets('shows NOT DECIDED YET stamp on negative horizontal drag (Left Swipe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TinderSwipeCard(
              property: testProperty,
              dragDx: -120.0,
              isTopCard: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOT DECIDED YET'), findsOneWidget);
      expect(find.text('CONNECT'), findsNothing);
    });

    testWidgets('advances photo carousel on right half tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: TinderSwipeCard(
                property: testProperty,
                dragDx: 0.0,
                isTopCard: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/3 Photos'), findsOneWidget);

      // Tap right side of image area (X: 300, Y: 150)
      await tester.tapAt(const Offset(300, 150));
      await tester.pumpAndSettle();

      expect(find.text('2/3 Photos'), findsOneWidget);

      // Tap left side of image area (X: 100, Y: 150)
      await tester.tapAt(const Offset(100, 150));
      await tester.pumpAndSettle();

      expect(find.text('1/3 Photos'), findsOneWidget);
    });
  });

  group('SCR-07 TopMatchesScreen Swipe Deck & Interaction Tests', () {
    testWidgets('renders screen title, initial deck, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TopMatchesScreen(
              onNavigate: (_, [__]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Hand-picked Properties for You!'), findsOneWidget);
      expect(find.text('4 Left'), findsOneWidget);
      expect(find.text('No, Decide Later'), findsOneWidget);
      expect(find.text('Yes, Connect me'), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    });

    testWidgets('triggers programmatic Decide Later swipe on button tap and enables Undo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TopMatchesScreen(
              onNavigate: (_, [__]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 BHK Ultra Luxury Apartment in DLF Phase 5'), findsOneWidget);
      expect(find.text('4 Left'), findsOneWidget);

      // Tap 'No, Decide Later'
      await tester.tap(find.text('No, Decide Later'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.text('Saved to Decide Later (Not Decided Yet)'), findsOneWidget);

      // Counter should decrement to 3 Left
      expect(find.text('3 Left'), findsOneWidget);

      // Top card is now next property
      expect(find.text('2 BHK Premium High-Rise with Pool View'), findsOneWidget);

      // Undo button badge should now show 1
      expect(find.text('1'), findsOneWidget);

      // Tap Undo to revert
      final undoButtonFinder = find.byIcon(Icons.undo_rounded).first;
      await tester.tap(undoButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Card 1 should be restored!
      expect(find.text('3 BHK Ultra Luxury Apartment in DLF Phase 5'), findsOneWidget);
      expect(find.text('4 Left'), findsOneWidget);
    });

    testWidgets('triggers programmatic Connect swipe on button tap and calls onNavigate', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var navigatedRoute = '';
      Object? navigatedArg;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TopMatchesScreen(
              onNavigate: (route, [arg]) {
                navigatedRoute = route;
                navigatedArg = arg;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Yes, Connect me'
      await tester.tap(find.text('Yes, Connect me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Connected with 3 BHK Ultra Luxury Apartment in DLF Phase 5!'), findsOneWidget);

      // Tap View on snackbar to verify onNavigate
      await tester.tap(find.text('View'));
      expect(navigatedRoute, '/property-detail');
      expect(navigatedArg, 'top-match-1');
    });

    testWidgets('gesture swipe right navigates to connect and advances card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TopMatchesScreen(
              onNavigate: (_, [__]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag top card to the right by 250 pixels
      final cardFinder = find.text('3 BHK Ultra Luxury Apartment in DLF Phase 5');
      await tester.drag(cardFinder, const Offset(250, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should advance to next card
      expect(find.text('2 BHK Premium High-Rise with Pool View'), findsOneWidget);
      expect(find.text('3 Left'), findsOneWidget);
    });

    testWidgets('swiping all cards renders All Caught Up view and Review Again resets deck', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TopMatchesScreen(
              onNavigate: (_, [__]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe all 4 cards
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Yes, Connect me'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Verify All Caught Up screen
      expect(find.text('You\'re all caught up!'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('4'), findsWidgets); // 4 reviewed, 4 connected
      expect(find.text('Review Matches Again'), findsOneWidget);

      // Tap Review Matches Again
      await tester.tap(find.text('Review Matches Again'));
      await tester.pumpAndSettle();

      // Deck should be reset to card 1
      expect(find.text('3 BHK Ultra Luxury Apartment in DLF Phase 5'), findsOneWidget);
      expect(find.text('4 Left'), findsOneWidget);
    });
  });
}
