import 'package:flutter/material.dart';

/// Shared Housing.com-style design tokens for detail screens.
class DetailTokens {
  static const indigo = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF2FF);
  static const surface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const whatsapp = Color(0xFF25D366);
  static const divider = Color(0xFFF1F5F9);
}

class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader(this.title, {super.key, this.trailing, this.onTap});

  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: DetailTokens.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null)
            const Icon(Icons.keyboard_arrow_up, color: DetailTokens.textSecondary),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

class DetailStickyCtaBar extends StatelessWidget {
  const DetailStickyCtaBar({
    super.key,
    required this.onChat,
    required this.onViewPhone,
    required this.onContact,
  });

  final VoidCallback onChat;
  final VoidCallback onViewPhone;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DetailTokens.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: DetailTokens.whatsapp),
              label: const Text('Chat', style: TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DetailTokens.indigo),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onViewPhone,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DetailTokens.indigo),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View phone', style: TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailTokens.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Contact Seller', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailHeroGallery extends StatelessWidget {
  const DetailHeroGallery({
    super.key,
    required this.imageUrls,
    required this.pageController,
    required this.activeIndex,
    required this.onPageChanged,
    required this.onBack,
    this.onFavorite,
    this.onShare,
    this.onCall,
    this.onFloorPlan,
    this.roomLabel,
    this.height = 320,
  });

  final List<String> imageUrls;
  final PageController pageController;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onCall;
  final VoidCallback? onFloorPlan;
  final String? roomLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.isEmpty
        ? ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80']
        : imageUrls;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: urls.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => Image.network(
              urls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: DetailTokens.indigoLight,
                child: const Icon(Icons.apartment, size: 64, color: DetailTokens.indigo),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back, onBack),
                const Spacer(),
                if (onFavorite != null) _circleBtn(Icons.favorite_border, onFavorite!),
                if (onShare != null) ...[const SizedBox(width: 8), _circleBtn(Icons.ios_share, onShare!)],
                if (onCall != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: DetailTokens.indigo,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onFloorPlan != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'See how the space is laid out',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: onFloorPlan,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: DetailTokens.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('See Floor Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${activeIndex + 1}/${urls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (roomLabel != null && roomLabel!.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(roomLabel!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: DetailTokens.textPrimary)),
    );
  }
}

class PaymentPlanCard extends StatelessWidget {
  const PaymentPlanCard({
    super.key,
    required this.bhkLabel,
    required this.emiLabel,
    required this.durationLabel,
    required this.interestLabel,
    this.onBreakup,
    this.onContactEmi,
  });

  final String bhkLabel;
  final String emiLabel;
  final String durationLabel;
  final String interestLabel;
  final VoidCallback? onBreakup;
  final VoidCallback? onContactEmi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DetailTokens.indigoLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: DetailTokens.textPrimary, fontSize: 14, height: 1.4),
                    children: [
                      const TextSpan(text: 'EMI starts for '),
                      TextSpan(text: bhkLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ' at '),
                      TextSpan(text: emiLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ' /per month'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Duration: $durationLabel • Interest: $interestLabel',
                  style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 12),
                ),
                if (onBreakup != null)
                  TextButton(
                    onPressed: onBreakup,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('View payment breakup >', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
              ],
            ),
          ),
          if (onContactEmi != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onContactEmi,
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailTokens.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Contact seller to explore EMI', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class OverviewGrid extends StatelessWidget {
  const OverviewGrid({super.key, required this.items});

  final List<({IconData icon, String label, String value})> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((e) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 42) / 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: DetailTokens.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(e.icon, size: 18, color: DetailTokens.textSecondary),
                  const SizedBox(height: 6),
                  Text(e.label, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                  const SizedBox(height: 2),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HighlightsList extends StatelessWidget {
  const HighlightsList({super.key, required this.items, this.onSeeMore});

  final List<String> items;
  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.take(5).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: DetailTokens.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 14, height: 1.35))),
                    ],
                  ),
                ),
              ),
          if (onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('See more >', style: TextStyle(decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }
}

class ReraBlock extends StatelessWidget {
  const ReraBlock({super.key, this.reraId, this.onAskMore});

  final String? reraId;
  final VoidCallback? onAskMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (reraId != null && reraId!.isNotEmpty) ? reraId! : 'Rera Not Applicable',
                  style: const TextStyle(color: DetailTokens.textSecondary),
                ),
              ),
              if (reraId != null && reraId!.isNotEmpty)
                const Icon(Icons.copy, size: 16, color: DetailTokens.textSecondary),
            ],
          ),
          if (onAskMore != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAskMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailTokens.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ask for more details', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class RecommendedCarouselCard {
  const RecommendedCarouselCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.imageUrl,
    this.meta,
    this.statusLabel = 'Ready to Move',
  });

  final String id;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String imageUrl;
  final String? meta;
  final String statusLabel;
}

class RecommendedCarousel extends StatelessWidget {
  const RecommendedCarousel({
    super.key,
    required this.items,
    required this.onTap,
    this.onViewPhone,
  });

  final List<RecommendedCarouselCard> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String>? onViewPhone;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 320,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 240,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onTap(item.id),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: DetailTokens.indigoLight),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.statusLabel, style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                          const SizedBox(height: 2),
                          Text(item.priceLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                          if (item.meta != null)
                            Text(item.meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                          const SizedBox(height: 8),
                          if (onViewPhone != null)
                            OutlinedButton(
                              onPressed: () => onViewPhone!(item.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DetailTokens.indigo,
                                side: const BorderSide(color: DetailTokens.indigo),
                                minimumSize: const Size.fromHeight(36),
                              ),
                              child: const Text('View phone'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeighbourhoodMapCard extends StatelessWidget {
  const NeighbourhoodMapCard({
    super.key,
    required this.categories,
    this.onExpand,
    this.onCategory,
  });

  final List<({IconData icon, String label})> categories;
  final VoidCallback? onExpand;
  final ValueChanged<String>? onCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=60',
                    fit: BoxFit.cover,
                    color: Colors.grey.shade400,
                    colorBlendMode: BlendMode.saturation,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
                  ),
                  const Center(child: Icon(Icons.home_work, size: 48, color: DetailTokens.indigo)),
                  if (onExpand != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: TextButton(
                        onPressed: onExpand,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Expand Map >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map(
                  (c) => OutlinedButton.icon(
                    onPressed: onCategory == null ? null : () => onCategory!(c.label),
                    icon: Icon(c.icon, size: 16, color: DetailTokens.indigo),
                    label: Text(c.label, style: const TextStyle(color: DetailTokens.textPrimary, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DetailTokens.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class ContactAvailabilityForm extends StatefulWidget {
  const ContactAvailabilityForm({
    super.key,
    required this.sellerName,
    required this.options,
    required this.onSubmit,
    this.phoneMasked,
  });

  final String sellerName;
  final List<String> options;
  final Future<void> Function(String preference) onSubmit;
  final String? phoneMasked;

  @override
  State<ContactAvailabilityForm> createState() => _ContactAvailabilityFormState();
}

class _ContactAvailabilityFormState extends State<ContactAvailabilityForm> {
  String? _selected;
  bool _whatsapp = true;
  bool _homeLoan = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) _selected = widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: DetailTokens.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: DetailTokens.indigoLight,
                  child: Text(
                    widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        widget.phoneMasked ?? 'Agent',
                        style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('You are looking for', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.options
                  .map(
                    (o) => ChoiceChip(
                      label: Text(o),
                      selected: _selected == o,
                      onSelected: (_) => setState(() => _selected = o),
                      selectedColor: DetailTokens.indigoLight,
                      labelStyle: TextStyle(
                        color: _selected == o ? DetailTokens.indigo : DetailTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(color: _selected == o ? DetailTokens.indigo : DetailTokens.border),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _whatsapp,
              onChanged: (v) => setState(() => _whatsapp = v ?? true),
              title: const Text('Contact me via call, WhatsApp, SMS or email', style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _homeLoan,
              onChanged: (v) => setState(() => _homeLoan = v ?? false),
              title: const Text('I am interested in Home loans', style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        try {
                          await widget.onSubmit(_selected ?? '');
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DetailTokens.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _submitting ? 'Submitting...' : 'Check availability with seller',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmenitiesAccordion extends StatelessWidget {
  const AmenitiesAccordion({super.key, required this.amenities});

  final List<({String category, String name})> amenities;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.take(12).map((a) {
          return Container(
            width: (MediaQuery.of(context).size.width - 42) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: DetailTokens.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: DetailTokens.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.items,
    required this.onWrite,
    this.emptyLabel = 'Be the first to add a review',
  });

  final List<({String name, int rating, String body, String? title})> items;
  final VoidCallback onWrite;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: DetailTokens.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(emptyLabel, style: const TextStyle(color: DetailTokens.textSecondary))),
                  OutlinedButton(
                    onPressed: onWrite,
                    style: OutlinedButton.styleFrom(foregroundColor: DetailTokens.indigo, side: const BorderSide(color: DetailTokens.indigo)),
                    child: const Text('Write a review'),
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (r) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: DetailTokens.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${r.rating}/5', style: const TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    if (r.title != null && r.title!.isNotEmpty)
                      Text(r.title!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(r.body, style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          if (items.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onWrite, child: const Text('Write a review')),
            ),
        ],
      ),
    );
  }
}

class DisclaimerBlock extends StatelessWidget {
  const DisclaimerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: DetailTokens.divider,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disclaimer', style: TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.textSecondary)),
          SizedBox(height: 8),
          Text(
            'PropertyDilaDo is only an intermediary offering its platform to facilitate the transactions between Seller and Customer. '
            'We are not related to any Seller and do not make any representation regarding quality of any product or service.',
            style: TextStyle(fontSize: 11, color: DetailTokens.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
