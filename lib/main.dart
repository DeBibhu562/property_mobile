import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_nav.dart';
import 'core/flavor_config.dart';
import 'core/theme.dart';
import 'ui/add_listing_screen.dart';
import 'ui/admin_moderation_screen.dart';
import 'ui/auth_screen.dart';
import 'ui/delete_account_screen.dart';
import 'ui/leads_screen.dart';
import 'ui/listing_visibility_screen.dart';
import 'ui/my_listings_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/project_detail_screen.dart';
import 'ui/projects_list_screen.dart';
import 'ui/property_detail_screen.dart';
import 'ui/property_list_screen.dart';
import 'ui/property_gallery_screen.dart';
import 'features/property/property_models.dart';
import 'ui/shell/app_shell_screen.dart';
import 'ui/smart_suggestions_screen.dart';
import 'ui/splash_screen.dart';
import 'ui/top_matches_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('PropertyDilaDo API_BASE_URL=${FlavorConfig.apiBaseUrl}');
  runApp(const ProviderScope(child: PropertyDilaDoApp()));
}

class PropertyDilaDoApp extends StatelessWidget {
  const PropertyDilaDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      title: 'PropertyDilaDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const AppShellScreen(),
        '/properties': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is Map) {
            return PropertyListScreen(
              initialQuery: args['query']?.toString(),
              initialType: args['type']?.toString(),
              initialListingType: args['listingType']?.toString(),
              screenTitle: args['title']?.toString(),
            );
          }
          return const PropertyListScreen();
        },
        '/add-property': (_) => const AddListingScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/delete-account': (_) => const DeleteAccountScreen(),
        '/my-listings': (_) => const MyListingsScreen(),
        '/leads': (_) => const LeadsScreen(),
        '/admin-moderation': (_) => const AdminModerationScreen(),
        '/property-detail': (ctx) {
          final id = ModalRoute.of(ctx)?.settings.arguments;
          return PropertyDetailScreen(propertyId: id is String ? id : '');
        },
        '/project-detail': (ctx) {
          final id = ModalRoute.of(ctx)?.settings.arguments;
          return ProjectDetailScreen(idOrSlug: id is String ? id : '');
        },
        '/projects': (ctx) {
          return ProjectsListScreen(
            onNavigate: (route, [arguments]) {
              Navigator.of(ctx).pushNamed(route, arguments: arguments);
            },
          );
        },
        '/smart-suggestions': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          String? city;
          var autoOpened = false;
          if (args is Map) {
            city = args['city']?.toString();
            autoOpened = args['autoOpened'] == true;
          } else if (args is String) {
            city = args;
          }
          return SmartSuggestionsScreen(
            city: city,
            autoOpened: autoOpened,
            embedded: false,
          );
        },
        '/property-gallery': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return PropertyGalleryScreen(images: args is List<PropertyImage> ? args : const []);
        },
        '/listing-visibility': (ctx) {
          final id = ModalRoute.of(ctx)?.settings.arguments;
          return ListingVisibilityScreen(listingId: id is String ? id : '');
        },
        '/top-matches': (ctx) {
          return TopMatchesScreen(
            onNavigate: (route, [arguments]) {
              Navigator.of(ctx).pushNamed(route, arguments: arguments);
            },
          );
        },
      },
    );
  }
}
