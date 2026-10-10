import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class WelcomeIntentScreen extends ConsumerWidget {
  const WelcomeIntentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Pill & Direct Browse Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined, size: 14, color: Color(0xFF4F46E5)),
                        SizedBox(width: 6),
                        Text(
                          'PropertyDilaDo Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(searchSelectionProvider.notifier).setIntent('BUY');
                      ref.read(searchSelectionProvider.notifier).setCity('New Delhi');
                    },
                    child: const Text(
                      'Skip to Search →',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Hero Headline
              const Text(
                'Find Your Dream Property',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you want to get started. You can change this anytime.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Service Option Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildOptionCard(
                      context: context,
                      title: 'Buy a Home',
                      subtitle: '10 Lac+ verified apartments, villas & builder floors',
                      icon: Icons.holiday_village_outlined,
                      gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      badge: 'MOST POPULAR',
                      badgeColor: const Color(0xFF4F46E5),
                      perks: ['Zero broker bias', 'Lowest price guarantee', 'Direct owner connect'],
                      onTap: () {
                        ref.read(searchSelectionProvider.notifier).setIntent('BUY');
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildOptionCard(
                      context: context,
                      title: 'Rent a Home or Flat',
                      subtitle: '8 Lac+ verified rental homes with zero brokerage options',
                      icon: Icons.key_outlined,
                      gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                      badge: 'VERIFIED RENT',
                      badgeColor: const Color(0xFF059669),
                      perks: ['Verified landlords', 'Ready to move', 'No hidden deposit clauses'],
                      onTap: () {
                        ref.read(searchSelectionProvider.notifier).setIntent('RENT');
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildOptionCard(
                      context: context,
                      title: 'Post Property (Sale / Rent)',
                      subtitle: 'List for free & get verified buyer enquiries in 24 hours',
                      icon: Icons.add_home_work_outlined,
                      gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                      badge: '100% FREE',
                      badgeColor: const Color(0xFFD97706),
                      perks: ['Direct buyer chats', 'Free photo verification', 'Priority rank'],
                      onTap: () {
                        Navigator.of(context).pushNamed('/add-property');
                      },
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

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String badge,
    required Color badgeColor,
    required List<String> perks,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Icon Container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              // Perks row
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: perks
                    .map(
                      (p) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            p,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
