import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propertydilado_mobile/features/lead/lead_models.dart';
import 'package:propertydilado_mobile/ui/widgets/buyer_activity_stream.dart';
import 'package:propertydilado_mobile/ui/widgets/recommendations_ring_card.dart';
import 'package:propertydilado_mobile/ui/widgets/user_dashboard_services_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SCR-11 UserDashboardServicesGrid Widget Tests', () {
    testWidgets('renders all 8 quick service tiles with icons and badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var contactedTapped = false;
      var siteVisitTapped = false;
      var suggestionsTapped = false;
      var loansTapped = false;
      var interiorsTapped = false;
      var legalTapped = false;
      var valuationTapped = false;
      var vastuTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UserDashboardServicesGrid(
                contactedCount: 42,
                onContactedTap: () => contactedTapped = true,
                onSiteVisitTap: () => siteVisitTapped = true,
                onSuggestionsTap: () => suggestionsTapped = true,
                onLoansTap: () => loansTapped = true,
                onInteriorsTap: () => interiorsTapped = true,
                onLegalTap: () => legalTapped = true,
                onValuationTap: () => valuationTapped = true,
                onVastuTap: () => vastuTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify grid header
      expect(find.text('Quick Real Estate Services'), findsOneWidget);

      // Verify all 8 tiles
      expect(find.text('Contacted Properties'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      expect(find.text('Site Visit'), findsOneWidget);
      expect(find.text('Free Cab'), findsOneWidget);

      expect(find.text('Property Suggestions'), findsOneWidget);
      expect(find.text('AI Match'), findsOneWidget);

      expect(find.text('Home Loans'), findsOneWidget);
      expect(find.text('8.35%*'), findsOneWidget);

      expect(find.text('Home Interiors'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);

      expect(find.text('Legal Title Check'), findsOneWidget);
      expect(find.text('Lawyers'), findsOneWidget);

      expect(find.text('Property Valuation'), findsOneWidget);
      expect(find.text('PropWorth'), findsOneWidget);

      expect(find.text('Vastu Consultation'), findsOneWidget);
      expect(find.text('Vastu'), findsOneWidget);

      // Verify locked icons exist on the locked services
      expect(find.byIcon(Icons.lock), findsNWidgets(3));

      // Tap tiles and verify callbacks
      await tester.tap(find.text('Contacted Properties'));
      expect(contactedTapped, isTrue);

      await tester.tap(find.text('Site Visit'));
      expect(siteVisitTapped, isTrue);

      await tester.tap(find.text('Property Suggestions'));
      expect(suggestionsTapped, isTrue);

      await tester.tap(find.text('Home Loans'));
      expect(loansTapped, isTrue);

      await tester.tap(find.text('Home Interiors'));
      expect(interiorsTapped, isTrue);

      await tester.tap(find.text('Legal Title Check'));
      expect(legalTapped, isTrue);

      await tester.tap(find.text('Property Valuation'));
      expect(valuationTapped, isTrue);

      await tester.tap(find.text('Vastu Consultation'));
      expect(vastuTapped, isTrue);
    });
  });

  group('SCR-11 RecommendationsRingCard & PreferenceSurveyCard Tests', () {
    testWidgets('renders countdown ring card and triggers CTA', (tester) async {
      var exploreTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationsRingCard(
              remainingCount: 30,
              city: 'Delhi NCR',
              onExploreTap: () => exploreTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30'), findsOneWidget);
      expect(find.text('LEFT'), findsOneWidget);
      expect(find.text('30 Properties left to explore'), findsOneWidget);
      expect(find.text('Explore Recommendations →'), findsOneWidget);

      await tester.tap(find.text('Explore Recommendations →'));
      expect(exploreTapped, isTrue);
    });

    testWidgets('renders commute survey chips and updates selection', (tester) async {
      List<String>? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PreferenceSurveyCard(
              onSelectionChanged: (list) => selected = list,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tailor your search by preferred commute'), findsOneWidget);
      expect(find.text('My Office'), findsOneWidget);
      expect(find.text('Kids School'), findsOneWidget);
      expect(find.text('Parents Home'), findsOneWidget);
      expect(find.text('Metro Station'), findsOneWidget);

      // Select Kids School chip
      await tester.tap(find.text('Kids School'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.contains('Kids School'), isTrue);
    });
  });

  group('SCR-11 BuyerActivityStream Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'user_note_lead-1': 'Spoke with broker; quoted 1.35 Cr.',
      });
    });

    final testLeads = <BuyerLead>[
      const BuyerLead(
        id: 'lead-1',
        listingId: 'prop-1',
        listingTitle: 'DLF The Arbour Ultra Luxury Floors',
        price: '₹ 1.45 Cr',
        locality: 'Sector 63',
        city: 'Gurugram',
        status: 'ACCEPTED',
        message: 'Interested in site visit',
        createdAt: '2026-10-09T10:00:00Z',
        advertiserName: 'DLF Realty Partner',
        advertiserPhone: '+919811002233',
        marketValueEstimate: '₹ 1.40 - 1.50 Cr',
      ),
      const BuyerLead(
        id: 'lead-2',
        listingId: 'prop-2',
        listingTitle: 'Godrej Woods Green View Residence',
        price: '₹ 85 Lac',
        locality: 'Sector 43',
        city: 'Noida',
        status: 'REJECTED',
        message: 'Request price details',
        createdAt: '2026-10-08T10:00:00Z',
        advertiserName: 'Noida Premier Homes',
        advertiserPhone: '+919811445566',
        marketValueEstimate: '₹ 80 - 90 Lac',
      ),
    ];

    testWidgets('renders Contacted tab with status pills REQUEST ACCEPTED and REQUEST REJECTED', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerActivityStream(
                contactedLeads: testLeads,
                onViewSimilar: (_) {},
                onContactAgain: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Contacted (2)'), findsOneWidget);
      expect(find.text('Viewed (8)'), findsOneWidget);

      // Check lead titles
      expect(find.text('DLF The Arbour Ultra Luxury Floors'), findsOneWidget);
      expect(find.text('Godrej Woods Green View Residence'), findsOneWidget);

      // Check status pills
      expect(find.text('REQUEST ACCEPTED'), findsOneWidget);
      expect(find.text('REQUEST REJECTED'), findsOneWidget);

      // Check saved note loaded from SharedPreferences
      expect(find.text('Spoke with broker; quoted 1.35 Cr.'), findsOneWidget);
    });

    testWidgets('opens PropWorth Market Valuation dialog on Check Market Value tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerActivityStream(
                contactedLeads: testLeads,
                onViewSimilar: (_) {},
                onContactAgain: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkMarketValueFinder = find.text('Check Market Value').first;
      await tester.tap(checkMarketValueFinder);
      await tester.pumpAndSettle();

      expect(find.text('PropWorth Market Valuation'), findsOneWidget);
      expect(find.text('Fair Market Value Range'), findsOneWidget);
      expect(find.text('₹ 1.40 - 1.50 Cr'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('PropWorth Market Valuation'), findsNothing);
    });

    testWidgets('switches to Viewed tab and renders viewed properties list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerActivityStream(
                contactedLeads: testLeads,
                onViewSimilar: (_) {},
                onContactAgain: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Viewed tab
      await tester.tap(find.text('Viewed (8)'));
      await tester.pumpAndSettle();

      expect(find.text('ATS Pristine Phase 2 Luxury Floors'), findsOneWidget);
      expect(find.text('₹ 1.65 Cr'), findsOneWidget);
      expect(find.textContaining('Sector 150, Noida'), findsOneWidget);
      expect(find.text('Mahagun Mezzaria Golf View Residences'), findsOneWidget);
    });

    testWidgets('opens notes bottom sheet modal and edits note', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerActivityStream(
                contactedLeads: testLeads,
                onViewSimilar: (_) {},
                onContactAgain: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Edit Notes for lead-1
      final editNotesFinder = find.text('Edit Notes');
      expect(editNotesFinder, findsOneWidget);
      await tester.tap(editNotesFinder);
      await tester.pumpAndSettle();

      expect(find.text('Personal Notes for DLF The Arbour Ultra Luxury Floors'), findsOneWidget);
      expect(find.text('Save Note'), findsOneWidget);

      // Enter new text and save
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Site visit confirmed for Saturday morning.');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      // Verify bottom sheet closed and new note is visible
      expect(find.text('Personal Notes for DLF The Arbour Ultra Luxury Floors'), findsNothing);
      expect(find.text('Site visit confirmed for Saturday morning.'), findsOneWidget);
    });
  });
}
