import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'property_models.dart';
import 'property_repository.dart';

class PropertyListState {
  final List<PropertyItem> items;
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
  final String? typeFilter; // SALE | RENT
  final String? listingTypeFilter; // RESIDENTIAL | COMMERCIAL | PG | ...

  const PropertyListState({
    this.items = const [],
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
  });

  PropertyListState copyWith({
    List<PropertyItem>? items,
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
    bool clearError = false,
    bool clearType = false,
    bool clearListingType = false,
  }) {
    return PropertyListState(
      items: items ?? this.items,
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
    );
  }
}

class PropertyListController extends StateNotifier<PropertyListState> {
  static const int pageSize = 10;
  final PropertyRepository repository;

  PropertyListController(this.repository) : super(const PropertyListState());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, offset: 0, items: [], total: 0, hasMore: true, clearError: true);
    try {
      final page = await repository.searchProperties(
        offset: 0,
        limit: pageSize,
        q: state.searchQuery.isEmpty ? null : state.searchQuery,
        bhk: state.bhkFilter,
        maxPrice: state.maxPriceFilter,
        city: state.cityFilter,
        type: state.typeFilter,
        listingType: state.listingTypeFilter,
      );
      // Drop incomplete ES docs that lack core listing fields.
      final items = page.items.where((i) => i.price > 0 || i.title.isNotEmpty).toList();
      final loaded = items.length;
      state = state.copyWith(
        loading: false,
        items: items,
        offset: page.items.length,
        total: page.total,
        hasMore: page.items.length < page.total,
      );
      // silence unused if filter removed everything but keep pagination honest
      if (loaded == 0 && page.total > 0 && page.items.isNotEmpty) {
        // still ok — UI shows empty of usable cards
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load properties: $e');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final page = await repository.searchProperties(
        offset: state.offset,
        limit: pageSize,
        q: state.searchQuery.isEmpty ? null : state.searchQuery,
        bhk: state.bhkFilter,
        maxPrice: state.maxPriceFilter,
        city: state.cityFilter,
        type: state.typeFilter,
        listingType: state.listingTypeFilter,
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
      state = state.copyWith(loadingMore: false, error: 'Failed to load more: $e');
    }
  }

  Future<void> applyFilter({
    String? query,
    int? bhk,
    int? maxPrice,
    String? city,
    String? type,
    String? listingType,
    bool clearType = false,
    bool clearListingType = false,
  }) async {
    state = state.copyWith(
      searchQuery: query ?? state.searchQuery,
      bhkFilter: bhk,
      maxPriceFilter: maxPrice,
      cityFilter: city,
      typeFilter: type,
      listingTypeFilter: listingType,
      clearType: clearType,
      clearListingType: clearListingType,
    );
    await refresh();
  }
}

final propertyListControllerProvider =
    StateNotifierProvider<PropertyListController, PropertyListState>((ref) {
  return PropertyListController(ref.read(propertyRepositoryProvider));
});
