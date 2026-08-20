import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers.dart';
import '../features/property/property_models.dart';

const _dismissKeyPrefix = 'smart_suggestions_dismissed_';

/// Persists whether the user dismissed smart suggestions for a city (per day).
class SmartSuggestionsDismissNotifier extends StateNotifier<Set<String>> {
  SmartSuggestionsDismissNotifier() : super({}) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey();
    final raw = prefs.getStringList('$_dismissKeyPrefix$today') ?? const [];
    state = raw.toSet();
  }

  String _dayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  bool isDismissed(String city) => state.contains(city.toLowerCase());

  Future<void> dismiss(String city) async {
    final next = {...state, city.toLowerCase()};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_dismissKeyPrefix${_dayKey()}', next.toList());
  }

  Future<void> clear(String city) async {
    final next = {...state}..remove(city.toLowerCase());
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_dismissKeyPrefix${_dayKey()}', next.toList());
  }
}

final smartSuggestionsDismissProvider =
    StateNotifierProvider<SmartSuggestionsDismissNotifier, Set<String>>((ref) {
  return SmartSuggestionsDismissNotifier();
});

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

/// Full-screen dismissible smart suggestions carousel.
/// Swipe vertically (or use arrows) to move between admin-curated listings.
/// Opening details pushes on top; dismissing with X closes the popup.
class SmartSuggestionsScreen extends ConsumerStatefulWidget {
  const SmartSuggestionsScreen({
    super.key,
    this.city,
    this.autoOpened = false,
    this.embedded = false,
  });

  final String? city;
  final bool autoOpened;
  /// When true (Suggestion tab), dismiss hides content instead of popping a route.
  final bool embedded;

  @override
  ConsumerState<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends ConsumerState<SmartSuggestionsScreen> {
  final _pageController = PageController();
  final _imageControllers = <int, PageController>{};

  bool _loading = true;
  String? _error;
  String _title = 'Smart Suggestions';
  String _subtitle = '';
  List<SmartSuggestionItem> _items = const [];
  int _index = 0;
  final Map<int, int> _imageIndex = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _imageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final city = widget.city ??
        ref.read(searchSelectionProvider).city ??
        'New Delhi';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/search/suggestions',
        queryParameters: {'city': city, 'limit': 12},
      );
      final root = res.data is Map ? res.data as Map : {};
      final data = root['data'] is Map ? root['data'] as Map : root;
      final items = ((data['items'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((e) => SmartSuggestionItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _title = (data['title'] ?? '${items.length}+ Smart Suggestions').toString();
        _subtitle = (data['subtitle'] ?? 'Based on your last search in $city').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load suggestions';
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final city = widget.city ??
        ref.read(searchSelectionProvider).city ??
        'New Delhi';
    await ref.read(smartSuggestionsDismissProvider.notifier).dismiss(city);
    if (!mounted) return;
    if (widget.embedded) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _showAgain() async {
    final city = widget.city ??
        ref.read(searchSelectionProvider).city ??
        'New Delhi';
    await ref.read(smartSuggestionsDismissProvider.notifier).clear(city);
    if (!mounted) return;
    setState(() {});
    await _load();
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
    final city = widget.city ??
        ref.watch(searchSelectionProvider).city ??
        'New Delhi';
    final dismissed = ref.watch(smartSuggestionsDismissProvider).contains(city.toLowerCase());

    if (widget.embedded && dismissed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'Suggestions dismissed for today',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can show admin-curated top properties again anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Show suggestions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.ios_share_outlined, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                              TextButton(onPressed: _dismiss, child: const Text('Close')),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lightbulb_outline, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  const Text('No suggestions right now'),
                                  TextButton(onPressed: _dismiss, child: const Text('Close')),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: _items.length,
                                  onPageChanged: (i) => setState(() => _index = i),
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                                    top: 0,
                                    child: Center(
                                      child: IconButton(
                                        onPressed: () => _goTo(_index - 1),
                                        icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF4F46E5)),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.9),
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
                                          Text(
                                            '${_index + 1} / ${_items.length}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _goTo(_index + 1),
                                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
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
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${imageIndex + 1}/${item.imageUrls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border, color: Color(0xFF0F172A)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                if (item.isVerified)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.metaLine,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onOpenDetails,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.locationLabel,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (item.unitLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.unitLabel,
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                    ),
                  ],
                  if (item.configs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.configs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final c = item.configs[i];
                          return Container(
                            width: 180,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['label'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c['areaLabel'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const Spacer(),
                                Text(
                                  c['priceLabel'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF4F46E5)),
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
                          label: const Text('Chat', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            backgroundColor: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onContact,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Contact Seller', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: onOpenDetails,
                      child: const Text('View full details'),
                    ),
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
