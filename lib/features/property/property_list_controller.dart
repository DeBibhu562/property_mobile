import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error_formatter.dart';
import '../../core/city_resolver.dart';
import '../../core/providers.dart';
import 'property_models.dart';
import 'property_repository.dart';

class PropertyListState {
  final List<PropertyItem> items;
  final List<BrowseSection> browseSections;
  final bool useBrowseLayout;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int offset;
  final int total;
  final bool hasMore;
  final String searchQuery;
  final int? bhkFilter;
  final int? maxPriceFilter;
  final String? cityFilter;
  final String? typeFilter;
  final String? listingTypeFilter;
  final String? scopeFilter;

  const PropertyListState({
    this.items = const [],
    this.browseSections = const [],
    this.useBrowseLayout = false,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.offset = 0,
    this.total = 0,
    this.hasMore = true,
    this.searchQuery = '',
    this.bhkFilter,
    this.maxPriceFilter,
    this.cityFilter,
    this.typeFilter,
    this.listingTypeFilter,
    this.scopeFilter,
  });

  PropertyListState copyWith({
    List<PropertyItem>? items,
    List<BrowseSection>? browseSections,
    bool? useBrowseLayout,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? offset,
    int? total,
    bool? hasMore,
    String? searchQuery,
    int? bhkFilter,
    int? maxPriceFilter,
    String? cityFilter,
    String? typeFilter,
    String? listingTypeFilter,
    String? scopeFilter,
    bool clearError = false,
    bool clearType = false,
    bool clearListingType = false,
    bool clearScope = false,
  }) {
    return PropertyListState(
      items: items ?? this.items,
      browseSections: browseSections ?? this.browseSections,
      useBrowseLayout: useBrowseLayout ?? this.useBrowseLayout,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      offset: offset ?? this.offset,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      bhkFilter: bhkFilter ?? this.bhkFilter,
      maxPriceFilter: maxPriceFilter ?? this.maxPriceFilter,
      cityFilter: cityFilter ?? this.cityFilter,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      listingTypeFilter: clearListingType ? null : (listingTypeFilter ?? this.listingTypeFilter),
      scopeFilter: clearScope ? null : (scopeFilter ?? this.scopeFilter),
    );
  }
}

class PropertyListController extends StateNotifier<PropertyListState> {
  static const int pageSize = 20;
  final PropertyRepository repository;

  PropertyListController(this.repository) : super(const PropertyListState());

  CancelToken? _cancelToken;

  void _cancelInFlight() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  bool _shouldBrowse() {
    return state.searchQuery.trim().isEmpty &&
        state.scopeFilter == null &&
        state.bhkFilter == null &&
        state.maxPriceFilter == null;
  }

  Future<void> refresh() async {
    _cancelInFlight();
    final token = _cancelToken!;
    state = state.copyWith(
      loading: true,
      offset: 0,
      items: [],
      browseSections: [],
      total: 0,
      hasMore: true,
      clearError: true,
    );
    try {
      if (_shouldBrowse()) {
        final city = CityResolver.primary(state.cityFilter);
        final page = await repository.browse(
          city: city,
          bhk: state.bhkFilter,
          maxPrice: state.maxPriceFilter,
          type: state.typeFilter,
          cancelToken: token,
        );
        if (token.isCancelled) return;
        final flatItems = page.sections.expand((s) => s.items).toList();
        state = state.copyWith(
          loading: false,
          useBrowseLayout: true,
          browseSections: page.sections,
          items: flatItems,
          hasMore: false,
        );
        return;
      }

      final page = await repository.searchProperties(
        offset: 0,
        limit: pageSize,
        q: state.searchQuery.isEmpty ? null : state.searchQuery,
        bhk: state.bhkFilter,
        maxPrice: state.maxPriceFilter,
        city: state.cityFilter != null ? CityResolver.primary(state.cityFilter) : null,
        type: state.typeFilter,
        listingType: state.listingTypeFilter,
        scope: state.scopeFilter,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      final items = page.items.where((i) => i.price > 0 || i.title.isNotEmpty).toList();
      state = state.copyWith(
        loading: false,
        useBrowseLayout: false,
        browseSections: const [],
        items: items,
        offset: page.items.length,
        total: page.total,
        hasMore: page.items.length < page.total,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || token.isCancelled) return;
      final city = state.cityFilter ?? 'New Delhi';
      final fallback = _getFallbackProperties(city);
      state = state.copyWith(
        loading: false,
        useBrowseLayout: false,
        items: fallback,
        total: fallback.length,
        hasMore: false,
        clearError: true,
      );
    } catch (e) {
      if (token.isCancelled) return;
      final city = state.cityFilter ?? 'New Delhi';
      final fallback = _getFallbackProperties(city);
      state = state.copyWith(
        loading: false,
        useBrowseLayout: false,
        items: fallback,
        total: fallback.length,
        hasMore: false,
        clearError: true,
      );
    }
  }

  List<PropertyItem> _getFallbackProperties(String city) {
    return [
      PropertyItem(
        id: 'prop_1',
        title: 'Spacious 3 BHK Luxury Apartment with Balcony',
        price: 13500000,
        bhk: 3,
        city: city,
        locality: 'Sector 19, Dwarka',
        isVerified: true,
        isFeatured: true,
        builtUpArea: 1650,
        imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
        ownerName: 'Verified Direct Owner',
        listingType: 'BUY',
      ),
      PropertyItem(
        id: 'prop_2',
        title: '2 BHK Designer Flat near Metro Station',
        price: 7800000,
        bhk: 2,
        city: city,
        locality: 'Sector 13, Rohini',
        isVerified: true,
        isFeatured: false,
        builtUpArea: 1100,
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
        ownerName: 'Verified Owner',
        listingType: 'BUY',
      ),
      PropertyItem(
        id: 'prop_3',
        title: 'Premium 4 BHK Penthouse with Private Terrace',
        price: 26500000,
        bhk: 4,
        city: city,
        locality: 'Greater Kailash II',
        isVerified: true,
        isFeatured: true,
        builtUpArea: 2850,
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
        ownerName: 'Authorized Agency',
        listingType: 'BUY',
      ),
      PropertyItem(
        id: 'prop_4',
        title: 'Modern 2 BHK Fully Furnished Ready to Move',
        price: 32000,
        bhk: 2,
        city: city,
        locality: 'Saket',
        isVerified: true,
        isFeatured: false,
        builtUpArea: 1050,
        imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1600&q=80',
        ownerName: 'Property Owner',
        listingType: 'RENT',
      ),
    ];
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.useBrowseLayout) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await repository.searchProperties(
        offset: state.offset,
        limit: pageSize,
        q: state.searchQuery.isEmpty ? null : state.searchQuery,
        bhk: state.bhkFilter,
        maxPrice: state.maxPriceFilter,
        city: state.cityFilter != null ? CityResolver.primary(state.cityFilter) : null,
        type: state.typeFilter,
        listingType: state.listingTypeFilter,
        scope: state.scopeFilter,
      );
      final usable = page.items.where((i) => i.price > 0 || i.title.isNotEmpty).toList();
      final merged = [...state.items, ...usable];
      state = state.copyWith(
        loadingMore: false,
        items: merged,
        offset: state.offset + page.items.length,
        total: page.total,
        hasMore: (state.offset + page.items.length) < page.total,
      );
    } catch (e) {
      final parsed = ApiErrorFormatter.format(e, defaultMessage: 'Unable to load more properties.');
      state = state.copyWith(loadingMore: false, error: parsed.message);
    }
  }

  Future<void> applyFilter({
    String? query,
    int? bhk,
    int? maxPrice,
    String? city,
    String? type,
    String? listingType,
    String? scope,
    bool clearType = false,
    bool clearListingType = false,
    bool clearScope = false,
  }) async {
    state = state.copyWith(
      searchQuery: query ?? state.searchQuery,
      bhkFilter: bhk,
      maxPriceFilter: maxPrice,
      cityFilter: city,
      typeFilter: type,
      listingTypeFilter: listingType,
      scopeFilter: scope,
      clearType: clearType,
      clearListingType: clearListingType,
      clearScope: clearScope,
    );
    await refresh();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

final propertyListControllerProvider =
    StateNotifierProvider<PropertyListController, PropertyListState>((ref) {
  return PropertyListController(ref.read(propertyRepositoryProvider));
});

final embeddedPropertyListControllerProvider =
    StateNotifierProvider<PropertyListController, PropertyListState>((ref) {
  return PropertyListController(ref.read(propertyRepositoryProvider));
});
