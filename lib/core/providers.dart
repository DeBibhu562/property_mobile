import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/admin_repository.dart';
import '../features/auth/auth_repository.dart';
import 'auth_session_storage.dart';
import '../features/entitlement/entitlement_repository.dart';
import '../features/lead/lead_repository.dart';
import '../features/listing/listing_repository.dart';
import '../features/notifications/device_registration_service.dart';
import '../features/notifications/device_token_provider.dart';
import '../features/property/property_repository.dart';
import '../features/project/project_repository.dart';
import '../services/app_dio.dart';
import 'app_nav.dart';
import 'flavor_config.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) => AuthSessionStorage());

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.read(tokenStorageProvider);
  return createAppDio(
    baseUrl: FlavorConfig.apiBaseUrl,
    tokenStorage: tokens,
    onUnauthorized: () {
      ref.read(authSessionStorageProvider).clear();
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    },
  );
});

/// Default binding is the no-op stub. Operators replace this with a
/// `FirebaseDeviceTokenProvider` (using `firebase_messaging`) once the
/// native config (google-services.json / GoogleService-Info.plist) is
/// in place — see `device_token_provider.dart` for the migration steps.
final deviceTokenProviderProvider = Provider<DeviceTokenProvider>((ref) {
  return const StubDeviceTokenProvider();
});

final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((ref) {
  return DeviceRegistrationService(
    ref.read(dioProvider),
    ref.read(deviceTokenProviderProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(tokenStorageProvider),
    ref.read(authSessionStorageProvider),
    ref.read(deviceRegistrationServiceProvider),
  );
});

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepository(ref.read(dioProvider));
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.read(dioProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.read(dioProvider));
});

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(ref.read(dioProvider));
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(ref.read(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioProvider));
});

final favoritesProvider = StateProvider<Set<String>>((ref) => <String>{});

class SearchSelectionState {
  final String? intent; // 'BUY' | 'RENT'
  final String? city;
  /// Portal top-bar category: buy | projects | rent | commercial | pg
  final String category;

  SearchSelectionState({
    this.intent,
    this.city,
    this.category = 'buy',
  });

  SearchSelectionState copyWith({
    String? intent,
    String? city,
    String? category,
    bool clearIntent = false,
    bool clearCity = false,
  }) {
    return SearchSelectionState(
      intent: clearIntent ? null : (intent ?? this.intent),
      city: clearCity ? null : (city ?? this.city),
      category: category ?? this.category,
    );
  }
}

class SearchSelectionNotifier extends StateNotifier<SearchSelectionState> {
  SearchSelectionNotifier() : super(SearchSelectionState());

  void setIntent(String? intent) {
    final category = intent == 'RENT'
        ? 'rent'
        : intent == 'BUY'
            ? 'buy'
            : state.category;
    state = state.copyWith(intent: intent, category: category);
  }

  void setCategory(String category) {
    final intent = switch (category) {
      'rent' => 'RENT',
      'buy' => 'BUY',
      _ => state.intent,
    };
    state = state.copyWith(category: category, intent: intent);
  }

  void setCity(String? city) {
    state = state.copyWith(city: city);
  }

  void resetCity() {
    state = state.copyWith(clearCity: true);
  }

  void clear() {
    state = SearchSelectionState();
  }
}

final searchSelectionProvider = StateNotifierProvider<SearchSelectionNotifier, SearchSelectionState>((ref) {
  return SearchSelectionNotifier();
});

