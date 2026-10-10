import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CenterActionSheetItem {
  const CenterActionSheetItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.badgeText,
    this.routeArguments,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? badgeText;
  final Object? routeArguments;
}

class CenterActionSheet extends StatelessWidget {
  const CenterActionSheet({
    super.key,
    required this.onNavigate,
  });

  final void Function(String route, [Object? arguments]) onNavigate;

  static Future<void> show(
    BuildContext context, {
    required void Function(String route, [Object? arguments]) onNavigate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => CenterActionSheet(onNavigate: onNavigate),
    );
  }

  static const List<CenterActionSheetItem> items = [
    CenterActionSheetItem(
      title: 'You',
      subtitle: 'View your personalized dashboard',
      icon: Icons.person_rounded,
      route: '/profile',
    ),
    CenterActionSheetItem(
      title: 'Property Valuation',
      subtitle: 'Check out accurate property price',
      icon: Icons.auto_graph_rounded,
      route: '/insights',
    ),
    CenterActionSheetItem(
      title: 'New Projects',
      subtitle: 'Comprehensive insights, Experts Reviews',
      icon: Icons.apartment_rounded,
      route: '/projects',
      badgeText: 'magicHomes',
    ),
    CenterActionSheetItem(
      title: 'Home Interiors',
      subtitle: '300+ Curated interior design brands',
      icon: Icons.chair_rounded,
      route: '/interiors',
    ),
    CenterActionSheetItem(
      title: 'Home Loan',
      subtitle: 'Fastest disbursal & lowest interest rates',
      icon: Icons.account_balance_rounded,
      route: '/emi',
    ),
    CenterActionSheetItem(
      title: 'MB Advice',
      subtitle: 'Your A to Z Real Estate Guide',
      icon: Icons.menu_book_rounded,
      route: '/advice',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            const Text(
              'All your property needs in one place',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 18),

            // List of Options
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Colors.grey.shade100,
                ),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (item.badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (item.route == '/advice' || item.route == '/interiors') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.title} section coming soon!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        onNavigate(item.route, item.routeArguments);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Center Close Button (X)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
