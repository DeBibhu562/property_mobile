import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/property/property_models.dart';

enum SwipeStampType { none, connect, decideLater }

class TinderSwipeCard extends StatefulWidget {
  const TinderSwipeCard({
    super.key,
    required this.property,
    this.dragDx = 0.0,
    this.isTopCard = false,
    this.onTap,
  });

  final PropertyItem property;
  final double dragDx;
  final bool isTopCard;
  final VoidCallback? onTap;

  @override
  State<TinderSwipeCard> createState() => _TinderSwipeCardState();
}

class _TinderSwipeCardState extends State<TinderSwipeCard> {
  int _currentPhotoIndex = 0;
  late final List<String> _photos;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _photos = _buildPhotoList(widget.property);
  }

  @override
  void didUpdateWidget(covariant TinderSwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.id != widget.property.id) {
      _currentPhotoIndex = 0;
      _photos.clear();
      _photos.addAll(_buildPhotoList(widget.property));
    }
  }

  List<String> _buildPhotoList(PropertyItem p) {
    final list = <String>[];
    if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
      list.add(p.imageUrl!);
    }
    // High-fidelity architectural photos for multi-photo gallery preview
    list.addAll(const [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    ]);
    return list.take(3).toList();
  }

  String _formatPrice(int price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(0)} Lac';
    }
    return _currencyFormat.format(price);
  }

  void _nextPhoto() {
    if (_photos.length <= 1) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex + 1) % _photos.length;
    });
  }

  void _prevPhoto() {
    if (_photos.length <= 1) return;
    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex - 1 + _photos.length) % _photos.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;

    // Calculate stamp opacities from drag distance
    const threshold = 90.0;
    final rightProgress = (widget.dragDx / threshold).clamp(0.0, 1.0);
    final leftProgress = (-widget.dragDx / threshold).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Photo Carousel & Stamps
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The Image
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Image.network(
                        _photos[_currentPhotoIndex],
                        key: ValueKey(_photos[_currentPhotoIndex]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.apartment_rounded, color: Colors.white38, size: 54),
                          ),
                        ),
                      ),
                    ),

                    // Gradient Scrim for readable badges
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.0, 0.2, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tap zones for photo carousel (Left = prev, Right = next)
                    if (widget.isTopCard)
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _prevPhoto,
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _nextPhoto,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Top Left: Photo Count Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentPhotoIndex + 1}/${_photos.length} Photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Right: Match Percentage Badge
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              '98% Match',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Photo Indicators (Dots)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_photos.length, (idx) {
                          final isSelected = idx == _currentPhotoIndex;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSelected ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Bottom Left: Posted Date Badge
                    Positioned(
                      bottom: 10,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Posted Recently',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // SWIPE STAMP OVERLAY: "CONNECT" (Right drag)
                    if (rightProgress > 0)
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Transform.rotate(
                          angle: -15 * math.pi / 180,
                          child: Opacity(
                            opacity: rightProgress,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF059669), width: 3),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                                  SizedBox(width: 6),
                                  Text(
                                    'CONNECT',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // SWIPE STAMP OVERLAY: "NOT DECIDED YET" (Left drag)
                    if (leftProgress > 0)
                      Positioned(
                        top: 40,
                        right: 20,
                        child: Transform.rotate(
                          angle: 15 * math.pi / 180,
                          child: Opacity(
                            opacity: leftProgress,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDC2626), width: 3),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, color: Color(0xFFDC2626), size: 22),
                                  SizedBox(width: 6),
                                  Text(
                                    'NOT DECIDED YET',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Section: Details & Features
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price & Configuration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatPrice(p.price),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${p.bhk > 0 ? '${p.bhk} BHK • ' : ''}${p.builtUpArea != null ? '${p.builtUpArea} sqft' : (p.listingType ?? 'Apartment')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Title
                          Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Locality & City
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${p.locality.isNotEmpty ? '${p.locality}, ' : ''}${p.city}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Highlight Chips: Transaction Type + Verification + Key Amenities
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF0F766E)),
                                const SizedBox(width: 4),
                                Text(
                                  'Transaction: ${p.isUnderConstruction ? 'Under Construction' : 'New Property'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (p.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Color(0xFF059669)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Property',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Gated Society',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
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
        ),
      ),
    );
  }
}
