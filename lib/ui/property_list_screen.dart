import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session_provider.dart';
import '../../core/providers.dart';
import '../features/property/property_list_controller.dart';
import '../features/property/property_models.dart';

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({
    super.key,
    this.embedded = false,
    this.showAddFab = true,
    this.showOnlyFavorites = false,
    this.initialQuery,
    this.initialType,
    this.initialListingType,
    this.screenTitle,
  });

  final bool embedded;
  final bool showAddFab;
  final bool showOnlyFavorites;
  /// Optional seed query applied on first load.
  final String? initialQuery;
  /// SALE | RENT
  final String? initialType;
  /// RESIDENTIAL | COMMERCIAL | PG | ...
  final String? initialListingType;
  final String? screenTitle;

  @override
  ConsumerState<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _activeCategory = 'All'; // 'All', 'New launches', 'Owner', 'Top Picks', 'Ready to move'
  String _selectedSort = 'relevance';
  bool _filterBhk = false;
  bool _filterPrice = false;
  bool _filterReady = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final seed = widget.initialQuery?.trim();
    if (seed != null && seed.isNotEmpty) {
      _searchController.text = seed;
    }
    Future.microtask(() {
      final controller = ref.read(propertyListControllerProvider.notifier);
      controller.applyFilter(
        query: seed ?? '',
        type: widget.initialType,
        listingType: widget.initialListingType,
        clearType: widget.initialType == null,
        clearListingType: widget.initialListingType == null,
      );
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(propertyListControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(0)} L';
    }
    return _currencyFormat.format(price);
  }

  void _applyActiveFilters() {
    ref.read(propertyListControllerProvider.notifier).applyFilter(
          query: _searchController.text,
          bhk: _filterBhk ? 3 : null,
          maxPrice: _filterPrice ? 15000000 : null,
        );
  }

  Future<void> _signOut() async {
    await ref.read(authSessionProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  List<PropertyItem> _applyCategoryFilter(List<PropertyItem> items) {
    if (_activeCategory == 'All') return items;
    if (_activeCategory == 'New launches') {
      return items.where((i) => i.isUnderConstruction).toList();
    }
    if (_activeCategory == 'Owner') {
      // Return properties not uploaded by agency
      return items.where((i) => i.ownerName != null && i.ownerName!.isNotEmpty).toList();
    }
    if (_activeCategory == 'Top Picks') {
      return items.where((i) => i.isFeatured || i.isVerified).toList();
    }
    if (_activeCategory == 'Ready to move') {
      return items.where((i) => !i.isUnderConstruction).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyListControllerProvider);
    final sessionAsync = ref.watch(authSessionProvider);
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    final user = sessionAsync.value?.user;
    final initials = user != null && user.name.isNotEmpty
        ? user.name.substring(0, min(2, user.name.length)).toUpperCase()
        : 'RS';

    // Filter items locally based on favorites and category tabs
    var displayedItems = widget.showOnlyFavorites
        ? state.items.where((item) => favorites.contains(item.id)).toList()
        : state.items;

    displayedItems = _applyCategoryFilter(displayedItems);

    final isSearchActive = _searchController.text.isNotEmpty || _activeCategory != 'All';
    final useCompactCards = isSearchActive &&
        widget.initialType == null &&
        widget.initialListingType == null &&
        widget.screenTitle == null;

    Widget bodyContent;

    if (state.loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && displayedItems.isEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(propertyListControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (displayedItems.isEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.showOnlyFavorites ? Icons.favorite_border : Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.showOnlyFavorites
                    ? 'No favorites saved yet'
                    : 'No matching properties found',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: () => ref.read(propertyListControllerProvider.notifier).refresh(),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayedItems.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (_, index) {
            if (index >= displayedItems.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = displayedItems[index];
            final isFav = favorites.contains(item.id);

            // Compact row cards only for free-text search — category browse uses full cards.
            if (useCompactCards) {
              return _buildHotspotPropertyCard(item, isFav);
            }

            // Standard layout
            final String tierLabel;
            final Color badgeBg;
            final Color badgeText;

            if (item.isFeatured) {
              tierLabel = 'Platinum';
              badgeBg = const Color(0xFFFEF3C7);
              badgeText = const Color(0xFFD97706);
            } else if (item.isVerified) {
              tierLabel = 'Gold';
              badgeBg = const Color(0xFFD1FAE5);
              badgeText = const Color(0xFF059669);
            } else {
              tierLabel = 'Silver';
              badgeBg = const Color(0xFFF1F5F9);
              badgeText = const Color(0xFF475569);
            }

            final sqft = item.builtUpArea ?? (item.bhk * 550);
            final statusText = item.isUnderConstruction ? 'Under construction' : 'Ready to move';

            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/property-detail',
                  arguments: item.id,
                ),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    height: 180,
                                    width: double.infinity,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        height: 180,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                                        ),
                                      );
                                    },
                                    errorBuilder: (ctx, e, st) => Container(
                                      height: 180,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.apartment, size: 48, color: Colors.white),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.apartment, size: 48, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tierLabel,
                              style: TextStyle(
                                color: badgeText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 26,
                            ),
                            onPressed: () {
                              ref.read(favoritesProvider.notifier).update((set) {
                                final next = Set<String>.from(set);
                                if (next.contains(item.id)) {
                                  next.remove(item.id);
                                } else {
                                  next.add(item.id);
                                }
                                return next;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.cardHeadline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(item.price),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4F46E5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$sqft sqft · $statusText${item.isVerified ? ' · RERA verified' : ''}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          titleSpacing: 16,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Searching in', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              Text('Delhi NCR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
            ],
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _applyActiveFilters(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '3bhk under 1.5 Cr, South Delhi',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Categories Tabs Row (All, New Launches, Owner, Top Picks)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryTab('All'),
                  _buildCategoryTab('New launches'),
                  _buildCategoryTab('Owner'),
                  _buildCategoryTab('Top Picks'),
                  _buildCategoryTab('Ready to move'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Filter Dropdowns Row (Sort, Budget, BHK, Type)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  _buildDropdownChip('Sort by', _selectedSort != 'relevance', () {
                    setState(() {
                      _selectedSort = _selectedSort == 'relevance' ? 'price_asc' : 'relevance';
                      ref.read(propertyListControllerProvider.notifier).refresh();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('2-3 BHK', _filterBhk, (val) {
                    setState(() => _filterBhk = val);
                    _applyActiveFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Under 1.5 Cr', _filterPrice, (val) {
                    setState(() => _filterPrice = val);
                    _applyActiveFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ready', _filterReady, (val) {
                    setState(() => _filterReady = val);
                  }),
                ],
              ),
            ),

            // Section Info Header: Hotspots Title
            if (isSearchActive && displayedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Matching properties in these hotspots',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Explore properties in high-demand areas',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle ?? 'Properties'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildCategoryTab(String label) {
    final isSelected = _activeCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _activeCategory = label;
            });
            _applyActiveFilters();
          }
        },
        selectedColor: const Color(0xFF4F46E5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDropdownChip(String label, bool isSelected, VoidCallback onTap) {
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
      onPressed: onTap,
      selected: isSelected,
      selectedColor: const Color(0xFFEEF2FF),
      checkmarkColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onChanged,
      selectedColor: const Color(0xFF4F46E5),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1)),
    );
  }

  // Grouped Hotspot Card Style (Horizontal layout: Image on left, details on right)
  Widget _buildHotspotPropertyCard(PropertyItem item, bool isFav) {
    final sqft = item.builtUpArea ?? (item.bhk * 550);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/property-detail',
          arguments: item.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFF1F5F9),
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.apartment, color: Color(0xFF4F46E5), size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Right Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isUnderConstruction ? 'Possession soon' : 'Ready to move',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.cardHeadline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.city}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(item.price),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF4F46E5)),
                        ),
                        Text(
                          '$sqft sq.ft.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
