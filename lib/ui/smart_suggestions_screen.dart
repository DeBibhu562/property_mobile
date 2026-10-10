import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/city_resolver.dart';
import '../core/providers.dart';
import '../features/property/property_models.dart';

/// Dismiss / snooze state for the auto-open popup (per city, in-memory or persisted via provider).
final smartSuggestionsDismissProvider =
    StateNotifierProvider<SmartSuggestionsDismissNotifier, Set<String>>((ref) {
  return SmartSuggestionsDismissNotifier();
});

class SmartSuggestionsDismissNotifier extends StateNotifier<Set<String>> {
  SmartSuggestionsDismissNotifier() : super({});

  bool isDismissed(String city) {
    return state.contains(city.toLowerCase());
  }

  Future<void> dismiss(String city) async {
    state = {...state, city.toLowerCase()};
  }

  Future<void> clear(String city) async {
    state = state.where((c) => c != city.toLowerCase()).toSet();
  }
}

/// Rich suggestions model for the feed.
class SmartSuggestionItem {
  final String id;
  final String title;
  final String city;
  final String locality;
  final String priceLabel;
  final String metaLine;
  final String unitLabel;
  final List<String> imageUrls;
  final String sellerName;
  final List<Map<String, String>> configs;
  final bool isVerified;

  const SmartSuggestionItem({
    required this.id,
    required this.title,
    required this.city,
    required this.locality,
    required this.priceLabel,
    required this.metaLine,
    required this.unitLabel,
    required this.imageUrls,
    required this.sellerName,
    required this.configs,
    this.isVerified = false,
  });

  factory SmartSuggestionItem.fromJson(Map<String, dynamic> json) {
    final images = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((e) => resolveImageUrl(e?.toString()))
        .where((u) => u.isNotEmpty)
        .toList();
    final configs = (json['configs'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (c) => {
            'label': (c['label'] ?? '').toString(),
            'areaLabel': (c['areaLabel'] ?? '').toString(),
            'priceLabel': (c['priceLabel'] ?? '').toString(),
          },
        )
        .toList();
    return SmartSuggestionItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Property',
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      priceLabel: json['priceLabel']?.toString() ?? 'Price on request',
      metaLine: json['metaLine']?.toString() ?? 'Ready to Move',
      unitLabel: json['unitLabel']?.toString() ?? '',
      imageUrls: images.isNotEmpty
          ? images
          : [
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
            ],
      sellerName: json['sellerName']?.toString() ?? 'Seller',
      configs: configs,
      isVerified: json['isVerified'] == true,
    );
  }

  String get locationLabel {
    final parts = [locality, city].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}

/// Fullscreen or Tab-based Smart Suggestions UI
class SmartSuggestionsScreen extends ConsumerStatefulWidget {
  const SmartSuggestionsScreen({
    super.key,
    this.city,
    this.autoOpened = false,
    this.embedded = false,
  });

  final String? city;
  final bool autoOpened;
  final bool embedded;

  @override
  ConsumerState<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends ConsumerState<SmartSuggestionsScreen> {
  final _pageController = PageController();
  final _imageControllers = <int, PageController>{};
  CancelToken? _cancelToken;

  String _title = 'Smart Suggestions';
  String _subtitle = '';
  List<SmartSuggestionItem> _items = const [];
  int _index = 0;
  final Map<int, int> _imageIndex = {};

  @override
  void initState() {
    super.initState();
    final city = widget.city ?? ref.read(searchSelectionProvider).city ?? 'New Delhi';
    _items = _getFallbackSuggestions(city);
    _title = 'AI Smart Matches';
    _subtitle = 'Curated top properties in $city';
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _pageController.dispose();
    for (final c in _imageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    final city = widget.city ?? ref.read(searchSelectionProvider).city ?? 'New Delhi';
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/search/suggestions',
        queryParameters: {'city': CityResolver.primary(city), 'limit': 12},
        cancelToken: token,
      ).timeout(const Duration(milliseconds: 2500));

      final root = res.data is Map ? res.data as Map : {};
      final data = root['data'] is Map ? root['data'] as Map : root;
      final fetchedItems = ((data['items'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((e) => SmartSuggestionItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();

      if (!mounted || token.isCancelled) return;
      final items = fetchedItems.isNotEmpty ? fetchedItems : _getFallbackSuggestions(city);
      setState(() {
        _items = items;
        _title = (data['title'] ?? 'AI Smart Matches').toString();
        _subtitle = (data['subtitle'] ?? 'Curated top properties in $city').toString();
      });
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        if (_items.isEmpty) _items = _getFallbackSuggestions(city);
      });
    }
  }

  List<SmartSuggestionItem> _getFallbackSuggestions(String city) {
    return [
      SmartSuggestionItem(
        id: 'sug_1',
        title: 'DLF The Arbour Ultra Luxury High-Rise',
        city: city,
        locality: 'Sector 63, Golf Course Ext.',
        priceLabel: '₹ 7.50 Cr',
        metaLine: 'Ready to Move · 3,950 sq.ft',
        unitLabel: '4 BHK Ultra Luxury Suite',
        imageUrls: const [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
        ],
        sellerName: 'DLF Authorized Partner',
        configs: const [
          {'label': '4 BHK Suite', 'areaLabel': '3,950 sq.ft', 'priceLabel': '₹ 7.50 Cr'},
          {'label': '5 BHK Penthouse', 'areaLabel': '5,200 sq.ft', 'priceLabel': '₹ 9.80 Cr'},
        ],
        isVerified: true,
      ),
      SmartSuggestionItem(
        id: 'sug_2',
        title: 'Godrej Woods Forest Residences',
        city: city,
        locality: 'Sector 43, Central Park',
        priceLabel: '₹ 2.45 Cr',
        metaLine: 'Under Construction · Possession 2026',
        unitLabel: '3 BHK Green Residence',
        imageUrls: const [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1600&q=80',
        ],
        sellerName: 'Godrej Properties Direct',
        configs: const [
          {'label': '2 BHK Luxury', 'areaLabel': '1,250 sq.ft', 'priceLabel': '₹ 1.65 Cr'},
          {'label': '3 BHK Premium', 'areaLabel': '1,950 sq.ft', 'priceLabel': '₹ 2.45 Cr'},
        ],
        isVerified: true,
      ),
      SmartSuggestionItem(
        id: 'sug_3',
        title: 'Tata Primanti European Sky Villas',
        city: city,
        locality: 'Southern Peripheral Road',
        priceLabel: '₹ 3.85 Cr',
        metaLine: 'Ready to Move · 2,850 sq.ft',
        unitLabel: '3 BHK Sky Residence',
        imageUrls: const [
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
        ],
        sellerName: 'Tata Housing Partner',
        configs: const [
          {'label': '3 BHK Villa', 'areaLabel': '2,850 sq.ft', 'priceLabel': '₹ 3.85 Cr'},
          {'label': '4 BHK Penthouse', 'areaLabel': '4,100 sq.ft', 'priceLabel': '₹ 5.90 Cr'},
        ],
        isVerified: true,
      ),
    ];
  }

  Future<void> _dismiss() async {
    final city = widget.city ?? ref.read(searchSelectionProvider).city ?? 'New Delhi';
    await ref.read(smartSuggestionsDismissProvider.notifier).dismiss(city);
    if (!mounted) return;
    if (widget.embedded) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _items.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openDetail(SmartSuggestionItem item) {
    Navigator.of(context).pushNamed('/property-detail', arguments: item.id);
  }

  PageController _imageControllerFor(int cardIndex) {
    return _imageControllers.putIfAbsent(cardIndex, () => PageController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                onPressed: _dismiss,
              ),
        automaticallyImplyLeading: !widget.embedded,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              _subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _SuggestionCard(
                    item: item,
                    imageController: _imageControllerFor(index),
                    imageIndex: _imageIndex[index] ?? 0,
                    onImageChanged: (i) => setState(() => _imageIndex[index] = i),
                    onOpenDetails: () => _openDetail(item),
                    onContact: () => _openDetail(item),
                  ),
                );
              },
            ),
            if (_index > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _goTo(_index - 1),
                      icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF4F46E5)),
                    ),
                  ),
                ),
              ),
            if (_index < _items.length - 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_index + 1} of ${_items.length} · Swipe up for next',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _goTo(_index + 1),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.imageController,
    required this.imageIndex,
    required this.onImageChanged,
    required this.onOpenDetails,
    required this.onContact,
  });

  final SmartSuggestionItem item;
  final PageController imageController;
  final int imageIndex;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onOpenDetails;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel Header
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: imageController,
                  itemCount: item.imageUrls.length,
                  onPageChanged: onImageChanged,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: onOpenDetails,
                      child: Image.network(
                        item.imageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFEEF2FF),
                          alignment: Alignment.center,
                          child: const Icon(Icons.apartment, size: 48, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${imageIndex + 1} / ${item.imageUrls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (item.isVerified)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Verified Partner',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Property Content Body
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.metaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onOpenDetails,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.priceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (item.unitLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· ${item.unitLabel}',
                          style: const TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  if (item.configs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.configs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final c = item.configs[i];
                          return Container(
                            width: 170,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['label'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      c['areaLabel'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Text(
                                  c['priceLabel'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF4F46E5)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenDetails,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                          label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onContact,
                          icon: const Icon(Icons.phone_in_talk, size: 18),
                          label: const Text('Call Seller', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
