import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ServiceTileData {
  const ServiceTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    this.isLocked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final bool isLocked;
}

/// SCR-11: 8-Tile Quick Service Grid for "You" / User Dashboard
class UserDashboardServicesGrid extends StatelessWidget {
  const UserDashboardServicesGrid({
    super.key,
    required this.onContactedTap,
    required this.onSiteVisitTap,
    required this.onSuggestionsTap,
    required this.onLoansTap,
    required this.onInteriorsTap,
    required this.onLegalTap,
    required this.onValuationTap,
    required this.onVastuTap,
    this.contactedCount = 116,
  });

  final VoidCallback onContactedTap;
  final VoidCallback onSiteVisitTap;
  final VoidCallback onSuggestionsTap;
  final VoidCallback onLoansTap;
  final VoidCallback onInteriorsTap;
  final VoidCallback onLegalTap;
  final VoidCallback onValuationTap;
  final VoidCallback onVastuTap;
  final int contactedCount;

  @override
  Widget build(BuildContext context) {
    final services = [
      ServiceTileData(
        title: 'Contacted Properties',
        subtitle: 'View replies & status',
        icon: Icons.forum_outlined,
        badge: '$contactedCount',
        badgeColor: AppTheme.primary,
      ),
      const ServiceTileData(
        title: 'Site Visit',
        subtitle: 'Free pickup & drop',
        icon: Icons.directions_car_outlined,
        badge: 'Free Cab',
        badgeColor: Color(0xFF059669),
      ),
      const ServiceTileData(
        title: 'Property Suggestions',
        subtitle: 'Handpicked for you',
        icon: Icons.auto_awesome_outlined,
        badge: 'AI Match',
        badgeColor: Color(0xFF4F46E5),
      ),
      const ServiceTileData(
        title: 'Home Loans',
        subtitle: 'Lowest interest rate',
        icon: Icons.account_balance_outlined,
        badge: '8.35%*',
        badgeColor: Color(0xFFD97706),
      ),
      const ServiceTileData(
        title: 'Home Interiors',
        subtitle: 'Free design consult',
        icon: Icons.chair_outlined,
        badge: '20% OFF',
        badgeColor: Color(0xFFE11D48),
      ),
      const ServiceTileData(
        title: 'Legal Title Check',
        subtitle: 'Zero property disputes',
        icon: Icons.gavel_outlined,
        badge: 'Lawyers',
        badgeColor: Color(0xFF0284C7),
        isLocked: true,
      ),
      const ServiceTileData(
        title: 'Property Valuation',
        subtitle: 'Instant fair price check',
        icon: Icons.analytics_outlined,
        badge: 'PropWorth',
        badgeColor: Color(0xFF7C3AED),
        isLocked: true,
      ),
      const ServiceTileData(
        title: 'Vastu Consultation',
        subtitle: 'Harmonious homes',
        icon: Icons.compass_calibration_outlined,
        badge: 'Vastu',
        badgeColor: Color(0xFFD97706),
        isLocked: true,
      ),
    ];

    final callbacks = [
      onContactedTap,
      onSiteVisitTap,
      onSuggestionsTap,
      onLoansTap,
      onInteriorsTap,
      onLegalTap,
      onValuationTap,
      onVastuTap,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.grid_view_rounded, size: 18, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'Quick Real Estate Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) {
            final s = services[index];
            final onTap = callbacks[index];

            return _ServiceCard(
              data: s,
              onTap: onTap,
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.data,
    required this.onTap,
  });

  final ServiceTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: data.badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, size: 18, color: data.badgeColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: data.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.isLocked) ...[
                        Icon(Icons.lock, size: 9, color: data.badgeColor),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        data.badge,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: data.badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Bottom Info: Title & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
