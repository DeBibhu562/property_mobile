import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class WelcomeIntentScreen extends ConsumerWidget {
  const WelcomeIntentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Slight cool gray
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Propertely',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What are you looking for?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a service which can be changed later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),

              // Service Option Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildOptionCard(
                      context: context,
                      title: 'Buy a Home',
                      subtitle: '10 Lac+ verified home listings',
                      icon: Icons.sell_outlined,
                      color: const Color(0xFF6366F1), // Indigo/Purple
                      onTap: () {
                        ref.read(searchSelectionProvider.notifier).setIntent('BUY');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context: context,
                      title: 'Rent as a Tenant',
                      subtitle: '8 Lac+ verified home listings',
                      icon: Icons.vpn_key_outlined,
                      color: const Color(0xFF6366F1), // Indigo/Purple
                      onTap: () {
                        ref.read(searchSelectionProvider.notifier).setIntent('RENT');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context: context,
                      title: 'Sell/Rent Property',
                      subtitle: 'Get verified enquiries in 24 hours',
                      icon: Icons.add_home_work_outlined,
                      color: const Color(0xFF6366F1), // Indigo/Purple
                      isFree: true,
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
    required Color color,
    required VoidCallback onTap,
    bool isFree = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(width: 20),
            // Text columns
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8), // Pink-50
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDB2777), // Pink-600
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
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
