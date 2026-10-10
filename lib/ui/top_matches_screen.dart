import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../features/property/property_list_controller.dart';
import '../features/property/property_models.dart';

class TopMatchesScreen extends ConsumerStatefulWidget {
  const TopMatchesScreen({super.key, required this.onNavigate});

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<TopMatchesScreen> createState() => _TopMatchesScreenState();
}

class _TopMatchesScreenState extends ConsumerState<TopMatchesScreen> {
  int _currentIndex = 0;
  final List<PropertyItem> _history = [];
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static const List<PropertyItem> _fallbackMatches = [
    PropertyItem(
      id: 'top-match-1',
      title: '3 BHK Ultra Luxury Apartment in DLF Phase 5',
      price: 28500000,
      city: 'Gurgaon',
      locality: 'DLF Phase 5',
      listingType: 'RESIDENTIAL',
      bhk: 3,
      builtUpArea: 2150,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    ),
    PropertyItem(
      id: 'top-match-2',
      title: '2 BHK Premium High-Rise with Pool View',
      price: 13500000,
      city: 'Noida',
      locality: 'Sector 75',
      listingType: 'RESIDENTIAL',
      bhk: 2,
      builtUpArea: 1380,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
    ),
    PropertyItem(
      id: 'top-match-3',
      title: '4 BHK Luxury Sky Villa with Private Deck',
      price: 64000000,
      city: 'Bangalore',
      locality: 'Whitefield',
      listingType: 'RESIDENTIAL',
      bhk: 4,
      builtUpArea: 3800,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  String _formatPrice(int price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(0)} L';
    }
    return _currencyFormat.format(price);
  }

  void _onDecideLater(PropertyItem item) {
    setState(() {
      _history.add(item);
      _currentIndex++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved to Decide Later'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.secondary,
          onPressed: _onUndo,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onConnect(PropertyItem item) {
    setState(() {
      _history.add(item);
      _currentIndex++;
    });
    widget.onNavigate('/property-detail', item.id);
  }

  void _onUndo() {
    if (_history.isEmpty || _currentIndex <= 0) return;
    setState(() {
      _history.removeLast();
      _currentIndex--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(propertyListControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Hand-picked Properties for You!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (_history.isNotEmpty)
                    TextButton.icon(
                      onPressed: _onUndo,
                      icon: const Icon(Icons.undo_rounded, size: 16, color: Colors.white70),
                      label: const Text(
                        'Undo',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ),

            // Card / Content
            Expanded(
              child: _buildCardView(
                listState.items.isNotEmpty ? listState.items : _fallbackMatches,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(List<PropertyItem> items) {
    if (items.isEmpty || _currentIndex >= items.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.greenAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'You are all caught up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for fresh hand-picked matches',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (_history.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _history.clear();
                  });
                },
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Review Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    final item = items[_currentIndex];
    final remaining = items.length - _currentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          // The Property Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with Photo Count & Date Badge
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackImage(),
                              )
                            : _fallbackImage(),
                        // Photo Count Badge
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '12',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Posted Date
                        Positioned(
                          bottom: 12,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Posted Recently',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details Section
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatPrice(item.price),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${item.bhk > 0 ? '${item.bhk} BHK ' : ''}${item.listingType ?? 'Apartment'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${item.locality.isNotEmpty ? '${item.locality}, ' : ''}${item.city}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Transaction Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Transaction: ${item.isUnderConstruction ? 'Under Construction' : 'Ready to Move'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Decision Action Buttons
          Row(
            children: [
              // No, Decide Later
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onDecideLater(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'No, Decide Later',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Yes, Connect me
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onConnect(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, Connect me',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining matches available',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(Icons.apartment_rounded, color: Colors.white38, size: 54),
      ),
    );
  }
}
