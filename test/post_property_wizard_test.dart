import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertydilado_mobile/core/theme.dart';
import 'package:propertydilado_mobile/ui/add_listing_screen.dart';

void main() {
  group('SCR-14: 8-Step Post Property Free Wizard Tests', () {
    Widget buildWizard() {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AddListingScreen(),
        ),
      );
    }

    testWidgets('Renders Step 1 (Intent) with 100% FREE badge and progress indicator', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      // Top Header & Free Badge
      expect(find.text('Post Property'), findsOneWidget);
      expect(find.text('100% FREE'), findsOneWidget);
      expect(find.text('Step 1 of 8 • Property Intent'), findsOneWidget);

      // Intent Options
      expect(find.text('Sell Property'), findsOneWidget);
      expect(find.text('Rent / Lease Out'), findsOneWidget);
      expect(find.text('PG / Co-Living'), findsOneWidget);

      // Bottom Continue Button
      expect(find.text('Continue to Step 2 →'), findsOneWidget);
    });

    testWidgets('Navigates from Step 1 to Step 2 and allows selecting property type', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      // Tap Continue to Step 2
      await tester.tap(find.text('Continue to Step 2 →'));
      await tester.pumpAndSettle();

      // Step 2 Header & Grid
      expect(find.text('Step 2 of 8 • Property Type'), findsOneWidget);
      expect(find.text('Flat / Apartment'), findsOneWidget);
      expect(find.text('Independent House / Villa'), findsOneWidget);
      expect(find.text('Builder Floor'), findsOneWidget);
      expect(find.text('Plot / Land'), findsOneWidget);

      // Select Villa
      await tester.tap(find.text('Independent House / Villa'));
      await tester.pumpAndSettle();

      // Tap Continue to Step 3
      await tester.tap(find.text('Continue to Step 3 →'));
      await tester.pumpAndSettle();

      // Step 3 Header & Location
      expect(find.text('Step 3 of 8 • Location Details'), findsOneWidget);
      expect(find.text('Popular Cities'), findsOneWidget);
      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Locality *'), findsOneWidget);
    });

    testWidgets('Live Indian currency words parser renders dynamically on price entry', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      // Navigate to Step 5 (Pricing)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Step 5 of 8 • Price & Financials'), findsOneWidget);

      // Enter price: 50,00,000 (Fifty Lakh)
      final priceField = find.widgetWithText(TextField, 'Expected Selling Price (₹) *');
      expect(priceField, findsOneWidget);

      await tester.enterText(priceField, '5000000');
      await tester.pumpAndSettle();

      // Should display real-time Indian Words below input
      expect(find.text('Fifty Lakh Rupees'), findsOneWidget);

      // Change to 1,20,00,000 (One Crore Twenty Lakh)
      await tester.enterText(priceField, '12000000');
      await tester.pumpAndSettle();

      expect(find.text('One Crore Twenty Lakh Rupees'), findsOneWidget);
    });

    testWidgets('Step 8 renders monetization package comparison with Free and Diamond tiers', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      // Navigate to Step 8
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Step 8 of 8 • Package & Publish'), findsOneWidget);

      // Monetization Packages
      expect(find.text('Free Listing'), findsOneWidget);
      expect(find.text('Diamond Package'), findsOneWidget);
      expect(find.text('MOST POPULAR'), findsOneWidget);
      expect(find.text('Continue with DIAMOND →'), findsOneWidget);

      // Select Free Listing
      await tester.tap(find.text('Free Listing'));
      await tester.pumpAndSettle();
      expect(find.text('Post Property for FREE →'), findsOneWidget);

      // Select Diamond
      await tester.tap(find.text('Diamond Package'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with DIAMOND →'), findsOneWidget);

      // Scroll to reveal Titanium Package
      await tester.drag(find.byType(ListView).last, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.text('Titanium VIP Package'), findsOneWidget);
    });

    testWidgets('Back button navigates to previous step smoothly', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.pumpAndSettle();

      // Go to Step 2
      await tester.tap(find.text('Continue to Step 2 →'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 8 • Property Type'), findsOneWidget);

      // Tap Back button in bottom bar
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 8 • Property Intent'), findsOneWidget);
    });
  });
}
