import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Magicbricks-style design tokens for detail screens.
class DetailTokens {
  static const crimson = Color(0xFFD8232A);
  static const crimsonLight = Color(0xFFFFF0F0);
  static const crimsonDark = Color(0xFFB71C1C);
  static const gold = Color(0xFFE58000);
  static const goldLight = Color(0xFFFFF8E7);
  static const surface = Color(0xFFFBF9F8);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF1E2229);
  static const textSecondary = Color(0xFF6B7280);
  static const whatsapp = Color(0xFF25D366);
  static const divider = Color(0xFFF3F4F6);
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);

  // Backward compatibility aliases
  static const indigo = crimson;
  static const indigoLight = crimsonLight;
}

class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader(this.title, {super.key, this.trailing, this.onTap, this.badge});

  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DetailTokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DetailTokens.crimsonLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: DetailTokens.crimson, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
          if (onTap != null)
            const Icon(Icons.keyboard_arrow_right, color: DetailTokens.textSecondary, size: 20),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

/// Sticky anchor tab bar matching Magicbricks PDP.
class StickyAnchorTabBar extends StatelessWidget {
  const StickyAnchorTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DetailTokens.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (context, i) {
          final isSelected = activeIndex == i;
          return InkWell(
            onTap: () => onTabSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? DetailTokens.crimson : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? DetailTokens.crimson : DetailTokens.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dual-action sticky bottom action bar matching Magicbricks.
class DetailStickyCtaBar extends StatelessWidget {
  const DetailStickyCtaBar({
    super.key,
    required this.onChat,
    required this.onViewPhone,
    required this.onContact,
    this.primaryLabel = 'Contact Agent',
    this.secondaryLabel = 'Get Phone No.',
    this.showChat = true,
  });

  final VoidCallback onChat;
  final VoidCallback onViewPhone;
  final VoidCallback onContact;
  final String primaryLabel;
  final String secondaryLabel;
  final bool showChat;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + (bottomInset > 0 ? bottomInset : 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showChat) ...[
            Material(
              color: DetailTokens.whatsapp.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.chat_bubble, size: 20, color: DetailTokens.whatsapp),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: onViewPhone,
              style: OutlinedButton.styleFrom(
                foregroundColor: DetailTokens.crimson,
                side: const BorderSide(color: DetailTokens.crimson, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                secondaryLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: ElevatedButton(
              onPressed: onContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailTokens.crimson,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero gallery with photo counter, video walkthrough preview, and actions.
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
    this.onVideoTour,
    this.roomLabel,
    this.height = 300,
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
  final VoidCallback? onVideoTour;
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
                color: DetailTokens.crimsonLight,
                child: const Icon(Icons.apartment, size: 64, color: DetailTokens.crimson),
              ),
            ),
          ),
          // Top gradient for status bar and actions readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 90,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                ),
              ),
            ),
          ),
          // Top Action Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back, onBack),
                const Spacer(),
                if (onFavorite != null) _circleBtn(Icons.favorite_border, onFavorite!),
                if (onShare != null) ...[const SizedBox(width: 8), _circleBtn(Icons.share_outlined, onShare!)],
                if (onCall != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: DetailTokens.crimson,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Video Tour Pill
          if (onVideoTour != null)
            Positioned(
              left: 12,
              bottom: 48,
              child: GestureDetector(
                onTap: onVideoTour,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill, color: DetailTokens.crimson, size: 16),
                      SizedBox(width: 5),
                      Text('Watch Video Walkthrough', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          // Bottom Counter Badge: 📷 1/24 Photos
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    '${activeIndex + 1}/${urls.length} Photos',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          // Floor Plan Trigger or Room Tag
          if (onFloorPlan != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: onFloorPlan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard_outlined, size: 13, color: DetailTokens.crimson),
                      SizedBox(width: 4),
                      Text('Floor Plan', style: TextStyle(color: DetailTokens.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            )
          else if (roomLabel != null && roomLabel!.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(roomLabel!, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: DetailTokens.textPrimary),
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      ),
    );
  }
}

/// 4-Metric Highlight Matrix (Rate, Config, Area, Possession/Status).
class MetricsMatrixBlock extends StatelessWidget {
  const MetricsMatrixBlock({
    super.key,
    required this.metrics,
    this.badgeTitle,
    this.verified = false,
  });

  final List<({String title, String subtitle, IconData icon})> metrics;
  final String? badgeTitle;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (badgeTitle != null || verified) ...[
            Row(
              children: [
                if (verified)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DetailTokens.greenLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DetailTokens.green.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 13, color: DetailTokens.green),
                        SizedBox(width: 4),
                        Text('mb Verified', style: TextStyle(color: DetailTokens.green, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                if (badgeTitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DetailTokens.goldLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DetailTokens.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 13, color: DetailTokens.gold),
                        const SizedBox(width: 4),
                        Text(badgeTitle!, style: const TextStyle(color: DetailTokens.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DetailTokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DetailTokens.border),
            ),
            child: Row(
              children: metrics.map((m) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(m.icon, size: 18, color: DetailTokens.crimson),
                        const SizedBox(height: 6),
                        Text(
                          m.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: DetailTokens.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10.5, color: DetailTokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sub-Listing Unit Configurations Matrix (All, 2 BHK, 3 BHK, 4 BHK).
class SubListingConfigurationsCard extends StatefulWidget {
  const SubListingConfigurationsCard({
    super.key,
    required this.configs,
    this.onViewFloorPlan,
  });

  final List<({String bhk, String area, String price, String carpet, String? image})> configs;
  final ValueChanged<String>? onViewFloorPlan;

  @override
  State<SubListingConfigurationsCard> createState() => _SubListingConfigurationsCardState();
}

class _SubListingConfigurationsCardState extends State<SubListingConfigurationsCard> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    if (widget.configs.isEmpty) return const SizedBox.shrink();

    final bhkCategories = ['All', ...widget.configs.map((c) => c.bhk).toSet()];
    final displayed = _activeFilter == 'All'
        ? widget.configs
        : widget.configs.where((c) => c.bhk == _activeFilter).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bhkCategories.map((cat) {
                final isSelected = _activeFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _activeFilter = cat),
                    selectedColor: DetailTokens.crimsonLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? DetailTokens.crimson : DetailTokens.textPrimary,
                    ),
                    side: BorderSide(color: isSelected ? DetailTokens.crimson : DetailTokens.border),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Configuration Unit Cards
          ...displayed.map((unit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DetailTokens.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: DetailTokens.crimsonLight,
                      child: unit.image != null
                          ? Image.network(unit.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.architecture, color: DetailTokens.crimson))
                          : const Icon(Icons.architecture, color: DetailTokens.crimson, size: 32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(unit.bhk, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(unit.price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: DetailTokens.crimson)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('Super Area: ${unit.area}', style: const TextStyle(fontSize: 12, color: DetailTokens.textPrimary)),
                        Text('Carpet Area: ${unit.carpet}', style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (widget.onViewFloorPlan != null) {
                        widget.onViewFloorPlan!(unit.bhk);
                      } else {
                        _showFloorPlanModal(context, unit);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 20, color: DetailTokens.crimson),
                    tooltip: 'View Floor Plan',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showFloorPlanModal(BuildContext context, ({String area, String bhk, String carpet, String? image, String price}) unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${unit.bhk} Layout & Floor Plan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DetailTokens.border),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.architecture, size: 64, color: DetailTokens.crimson),
                      SizedBox(height: 8),
                      Text('Architectural Blueprint Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('High-resolution 2D Layout with measurements', style: TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Super Built-Up', style: TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                        Text(unit.area, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carpet Area', style: TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                        Text(unit.carpet, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Price', style: TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                        Text(unit.price, style: const TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.crimson)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Interactive in-line EMI calculator with dynamic slider computation.
class InteractiveEmiCalculator extends StatefulWidget {
  const InteractiveEmiCalculator({
    super.key,
    this.initialPrice = 10000000,
    this.onApplyLoan,
  });

  final int initialPrice;
  final VoidCallback? onApplyLoan;

  @override
  State<InteractiveEmiCalculator> createState() => _InteractiveEmiCalculatorState();
}

class _InteractiveEmiCalculatorState extends State<InteractiveEmiCalculator> {
  late double _loanAmount;
  double _tenureYears = 20;
  double _interestRate = 8.5;

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Default to 80% of property price or 50L
    _loanAmount = (widget.initialPrice * 0.8).clamp(1000000.0, 50000000.0);
  }

  double get _monthlyEmi {
    final p = _loanAmount;
    final r = (_interestRate / 100) / 12;
    final n = _tenureYears * 12;
    if (r == 0) return p / n;
    final pow = math.pow(1 + r, n);
    return (p * r * pow) / (pow - 1);
  }

  double get _totalPayment => _monthlyEmi * (_tenureYears * 12);
  double get _totalInterest => _totalPayment - _loanAmount;

  String _fmt(double val) {
    if (val >= 10000000) return '₹${(val / 10000000).toStringAsFixed(2)} Cr';
    if (val >= 100000) return '₹${(val / 100000).toStringAsFixed(1)} Lac';
    return _currency.format(val.round());
  }

  @override
  Widget build(BuildContext context) {
    final emiStr = _currency.format(_monthlyEmi.round());
    final principalRatio = (_loanAmount / _totalPayment).clamp(0.1, 0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DetailTokens.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Result Readout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DetailTokens.crimsonLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly EMI Payment', style: TextStyle(fontSize: 12, color: DetailTokens.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '$emiStr / mo',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DetailTokens.crimson),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DetailTokens.crimson.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_interestRate.toStringAsFixed(1)}% p.a.',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: DetailTokens.crimson),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slider 1: Loan Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Loan Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(_fmt(_loanAmount), style: const TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.crimson)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DetailTokens.crimson,
                thumbColor: DetailTokens.crimson,
                inactiveTrackColor: DetailTokens.border,
                trackHeight: 3,
              ),
              child: Slider(
                value: _loanAmount,
                min: 1000000,
                max: 50000000,
                divisions: 98,
                onChanged: (v) => setState(() => _loanAmount = v),
              ),
            ),

            // Slider 2: Tenure
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Loan Tenure', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${_tenureYears.toInt()} Years', style: const TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.crimson)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DetailTokens.crimson,
                thumbColor: DetailTokens.crimson,
                inactiveTrackColor: DetailTokens.border,
                trackHeight: 3,
              ),
              child: Slider(
                value: _tenureYears,
                min: 5,
                max: 30,
                divisions: 25,
                onChanged: (v) => setState(() => _tenureYears = v),
              ),
            ),

            // Slider 3: Interest Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Interest Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${_interestRate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.crimson)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DetailTokens.crimson,
                thumbColor: DetailTokens.crimson,
                inactiveTrackColor: DetailTokens.border,
                trackHeight: 3,
              ),
              child: Slider(
                value: _interestRate,
                min: 7.0,
                max: 12.0,
                divisions: 50,
                onChanged: (v) => setState(() => _interestRate = v),
              ),
            ),

            const SizedBox(height: 10),
            // Payment Breakdown Ratio Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: (principalRatio * 100).round(),
                      child: Container(color: DetailTokens.crimson),
                    ),
                    Expanded(
                      flex: ((1 - principalRatio) * 100).round(),
                      child: Container(color: DetailTokens.gold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: DetailTokens.crimson, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Principal: ${_fmt(_loanAmount)}', style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: DetailTokens.gold, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Interest: ${_fmt(_totalInterest)}', style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: widget.onApplyLoan ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checking Home Loan offers from SBI, HDFC & ICICI...')),
                );
              },
              icon: const Icon(Icons.account_balance_outlined, size: 18, color: DetailTokens.crimson),
              label: const Text('Check Bank Loan Eligibility', style: TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DetailTokens.crimson),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI Sentiment Summary & 5-Star Ratings Matrix.
class AiSentimentReviewsCard extends StatelessWidget {
  const AiSentimentReviewsCard({
    super.key,
    this.overallRating = 4.6,
    this.positiveSentimentPct = 92,
    this.reviewCount = 148,
    this.onWriteReview,
  });

  final double overallRating;
  final int positiveSentimentPct;
  final int reviewCount;
  final VoidCallback? onWriteReview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DetailTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Analysis Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DetailTokens.crimsonLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.auto_awesome, color: DetailTokens.crimson, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('mb AI Sentiment Analysis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DetailTokens.greenLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$positiveSentimentPct% Positive', style: const TextStyle(color: DetailTokens.green, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Overall Rating Score Callout
            Row(
              children: [
                Text(
                  overallRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: DetailTokens.textPrimary),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return const Icon(Icons.star, size: 16, color: DetailTokens.gold);
                      }),
                    ),
                    Text('Based on $reviewCount verified resident reviews', style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // 5 Criteria Progress Bars
            _ratingBar('Connectivity & Commute', 4.8),
            _ratingBar('Lifestyle & Amenities', 4.7),
            _ratingBar('Construction & Finishes', 4.5),
            _ratingBar('Green Area & Open Space', 4.6),
            _ratingBar('Security & Maintenance', 4.8),
            const SizedBox(height: 12),
            // Verified Resident Quote Pills
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DetailTokens.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_quote, size: 18, color: DetailTokens.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '"Excellent connectivity to Metro & schools. Zero noise pollution and lush landscaping."',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: DetailTokens.textPrimary),
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

  Widget _ratingBar(String title, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(title, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 5.0,
                backgroundColor: DetailTokens.divider,
                color: DetailTokens.crimson,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Local Landmark Proximity and "What's Nearby" matrix.
class NeighbourhoodProximityCard extends StatefulWidget {
  const NeighbourhoodProximityCard({
    super.key,
    this.landmarks = const [],
    this.onExpandMap,
  });

  final List<({String name, String category, String distance, IconData icon})> landmarks;
  final VoidCallback? onExpandMap;

  @override
  State<NeighbourhoodProximityCard> createState() => _NeighbourhoodProximityCardState();
}

class _NeighbourhoodProximityCardState extends State<NeighbourhoodProximityCard> {
  String _selectedCategory = 'All';

  List<({String name, String category, String distance, IconData icon})> get _defaultLandmarks => [
        (name: 'Sector 21 Metro Interchange', category: 'Transit', distance: '0.8 km', icon: Icons.subway_outlined),
        (name: 'Delhi Public School (DPS)', category: 'Schools', distance: '1.2 km', icon: Icons.school_outlined),
        (name: 'Venkateshwar Super Specialty Hospital', category: 'Hospitals', distance: '1.5 km', icon: Icons.local_hospital_outlined),
        (name: 'Vegas Luxury Mall & Cinepolis', category: 'Shopping', distance: '2.1 km', icon: Icons.shopping_bag_outlined),
        (name: 'IGI Airport Terminal 3', category: 'Transit', distance: '8.5 km', icon: Icons.flight_takeoff_outlined),
      ];

  @override
  Widget build(BuildContext context) {
    final list = widget.landmarks.isNotEmpty ? widget.landmarks : _defaultLandmarks;
    final categories = ['All', 'Transit', 'Schools', 'Hospitals', 'Shopping'];
    final displayed = _selectedCategory == 'All'
        ? list
        : list.where((item) => item.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Map preview banner with expand action
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=60',
                    fit: BoxFit.cover,
                    color: Colors.grey.shade400,
                    colorBlendMode: BlendMode.saturation,
                    errorBuilder: (_, __, ___) => Container(color: DetailTokens.surface),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: DetailTokens.crimson, size: 18),
                          SizedBox(width: 4),
                          Text('Prime Strategic Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  if (widget.onExpandMap != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: ElevatedButton(
                        onPressed: widget.onExpandMap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Open in Maps >'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: DetailTokens.crimsonLight,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? DetailTokens.crimson : DetailTokens.textPrimary,
                    ),
                    side: BorderSide(color: isSelected ? DetailTokens.crimson : DetailTokens.border),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Proximity items
          ...displayed.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DetailTokens.border),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: DetailTokens.crimson),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DetailTokens.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.distance,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DetailTokens.crimson),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Side-by-side Project Comparison Matrix.
class ProjectComparisonMatrix extends StatelessWidget {
  const ProjectComparisonMatrix({
    super.key,
    required this.currentProjectName,
    this.currentPriceSqft = '₹8,181 / sq.ft.',
    this.currentPossession = 'Ready To Move',
    this.currentClubhouse = '1,00,000 sq.ft.',
  });

  final String currentProjectName;
  final String currentPriceSqft;
  final String currentPossession;
  final String currentClubhouse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DetailTokens.border),
        ),
        child: Column(
          children: [
            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: DetailTokens.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text('Specification', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: DetailTokens.textSecondary)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      currentProjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: DetailTokens.crimson),
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text('Local Competitor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: DetailTokens.textSecondary)),
                  ),
                ],
              ),
            ),
            _compRow('Avg Rate', currentPriceSqft, '₹9,450 / sq.ft.'),
            _compRow('Possession', currentPossession, 'Dec 2027'),
            _compRow('Clubhouse', currentClubhouse, '45,000 sq.ft.'),
            _compRow('RERA Status', 'Approved ✓', 'Approved ✓'),
            _compRow('Rating', '4.8 ★', '4.3 ★'),
          ],
        ),
      ),
    );
  }

  Widget _compRow(String label, String currentVal, String compVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DetailTokens.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary)),
          ),
          Expanded(
            flex: 4,
            child: Text(currentVal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DetailTokens.textPrimary)),
          ),
          Expanded(
            flex: 3,
            child: Text(compVal, style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary)),
          ),
        ],
      ),
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
              color: DetailTokens.crimsonLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DetailTokens.crimson.withValues(alpha: 0.2)),
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
                      TextSpan(text: emiLabel, style: const TextStyle(fontWeight: FontWeight.w900, color: DetailTokens.crimson)),
                      const TextSpan(text: ' / month'),
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
                    child: const Text('View payment breakup >', style: TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          if (onContactEmi != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onContactEmi,
              style: ElevatedButton.styleFrom(
                backgroundColor: DetailTokens.crimson,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Contact Seller for Loan Assistance', style: TextStyle(fontWeight: FontWeight.w800)),
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
                  Icon(e.icon, size: 18, color: DetailTokens.crimson),
                  const SizedBox(height: 6),
                  Text(e.label, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                  const SizedBox(height: 2),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
                      const Icon(Icons.check_circle, size: 16, color: DetailTokens.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ),
          if (onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('See all highlights >', style: TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w700)),
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
    final validRera = reraId != null && reraId!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: validRera ? DetailTokens.greenLight.withValues(alpha: 0.4) : DetailTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: validRera ? DetailTokens.green.withValues(alpha: 0.3) : DetailTokens.border),
        ),
        child: Row(
          children: [
            Icon(validRera ? Icons.verified_user : Icons.info_outline, size: 20, color: validRera ? DetailTokens.green : DetailTokens.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(validRera ? 'RERA Approved Project' : 'RERA Verification Pending', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(validRera ? 'RERA ID: $reraId' : 'Contact developer for regulatory filings', style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                ],
              ),
            ),
            if (validRera)
              const Icon(Icons.copy, size: 16, color: DetailTokens.textSecondary),
          ],
        ),
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
      height: 300,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 230,
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
                          errorBuilder: (_, __, ___) => Container(color: DetailTokens.crimsonLight),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.statusLabel, style: const TextStyle(fontSize: 10.5, color: DetailTokens.green, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(item.priceLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: DetailTokens.crimson)),
                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: DetailTokens.textSecondary)),
                          const SizedBox(height: 6),
                          if (onViewPhone != null)
                            OutlinedButton(
                              onPressed: () => onViewPhone!(item.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DetailTokens.crimson,
                                side: const BorderSide(color: DetailTokens.crimson),
                                minimumSize: const Size.fromHeight(32),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('View Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
          color: Colors.white,
          border: Border.all(color: DetailTokens.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: DetailTokens.crimsonLight,
                  child: Text(
                    widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(
                        widget.phoneMasked ?? 'Direct Partner',
                        style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Select Your Preferred Unit Configuration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.options
                  .map(
                    (o) => ChoiceChip(
                      label: Text(o),
                      selected: _selected == o,
                      onSelected: (_) => setState(() => _selected = o),
                      selectedColor: DetailTokens.crimsonLight,
                      labelStyle: TextStyle(
                        color: _selected == o ? DetailTokens.crimson : DetailTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: _selected == o ? DetailTokens.crimson : DetailTokens.border),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _whatsapp,
              onChanged: (v) => setState(() => _whatsapp = v ?? true),
              title: const Text('Receive instant brochure and price sheet on WhatsApp', style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: DetailTokens.crimson,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _homeLoan,
              onChanged: (v) => setState(() => _homeLoan = v ?? false),
              title: const Text('I need free Home Loan assistance', style: TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: DetailTokens.crimson,
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
                  backgroundColor: DetailTokens.crimson,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _submitting ? 'Submitting...' : 'Check Availability & Request Callback',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: DetailTokens.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: DetailTokens.crimson),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DetailTokens.crimson,
                      side: const BorderSide(color: DetailTokens.crimson),
                    ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DetailTokens.crimsonLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${r.rating} ★', style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w800, fontSize: 11)),
                        ),
                      ],
                    ),
                    if (r.title != null && r.title!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.title!, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 4),
                    Text(r.body, style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
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
          Text('Disclaimer & Magicbricks Assurance', style: TextStyle(fontWeight: FontWeight.w800, color: DetailTokens.textSecondary, fontSize: 12)),
          SizedBox(height: 8),
          Text(
            'PropertyDilaDo is an advertising platform connecting prospective buyers and verified sellers. '
            'All listings are verified against local registrar norms and RERA declarations. Users are advised to exercise independent due diligence before financial commitments.',
            style: TextStyle(fontSize: 11, color: DetailTokens.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
