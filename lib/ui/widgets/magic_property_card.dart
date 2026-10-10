import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/property/property_models.dart';

class MagicPropertyCard extends StatelessWidget {
  const MagicPropertyCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onContactAgent,
    this.onGetPhone,
    this.onShare,
  });

  final PropertyItem item;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onContactAgent;
  final VoidCallback? onGetPhone;
  final VoidCallback? onShare;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String _formatPrice(int price) {
    if (price >= 10000000) {
      final cr = price / 10000000;
      return '₹ ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (price >= 100000) {
      final lac = price / 100000;
      return '₹ ${lac.toStringAsFixed(0)} Lac';
    }
    return _currencyFormat.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final sqft = item.builtUpArea ?? (item.bhk > 0 ? item.bhk * 550 : 1200);
    final isRent = item.listingType == 'RENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Media Header
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackImage(),
                        )
                      : _buildFallbackImage(),
                ),

                // Photo Count Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.camera_alt_outlined, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          '6+',
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

                // Posted Date Label
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
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

                // Share Button (Top Right)
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: onShare ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing link copied to clipboard!')),
                          );
                        },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Information
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(item.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (item.price > 0 && sqft > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· ₹${(item.price / sqft).toStringAsFixed(0)}/sqft',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Config, Property Type & Area
                  Text(
                    '${item.bhk > 0 ? '${item.bhk} BHK ' : ''}${item.listingType ?? 'Apartment'} · $sqft sqft',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Locality & City
                  Text(
                    '${item.locality.isNotEmpty ? '${item.locality}, ' : ''}${item.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Feature Status Tags
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.isUnderConstruction ? Colors.amber : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.isUnderConstruction ? 'Under Construction' : 'Ready to move',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      if (item.isVerified) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Wishlist Heart Icon
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppTheme.primary : const Color(0xFF64748B),
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Get Phone No. Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onGetPhone ??
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Contact Number: ${item.ownerName ?? 'Verified Agent'}'),
                                  ),
                                );
                              },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isRent ? 'Check Availability' : 'Get Phone No.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Contact Agent Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onContactAgent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Contact Agent',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.home_work_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 6),
            Text(
              'No photo available',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
