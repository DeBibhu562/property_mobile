import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// SCR-11: Circular Countdown Recommendations Ring Card & Preference Survey Card
class RecommendationsRingCard extends StatelessWidget {
  const RecommendationsRingCard({
    super.key,
    required this.onExploreTap,
    this.remainingCount = 30,
    this.city = 'Delhi NCR',
  });

  final VoidCallback onExploreTap;
  final int remainingCount;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2229), Color(0xFF2D333F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress / Countdown Ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 0.68,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'LEFT',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Content & Action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$remainingCount Properties left to explore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Handpicked for you in $city based on your verified budget preference.',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onExploreTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Recommendations →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

/// SCR-11: Preference Survey Card allowing landmark personalization
class PreferenceSurveyCard extends StatefulWidget {
  const PreferenceSurveyCard({
    super.key,
    this.onSelectionChanged,
  });

  final ValueChanged<List<String>>? onSelectionChanged;

  @override
  State<PreferenceSurveyCard> createState() => _PreferenceSurveyCardState();
}

class _PreferenceSurveyCardState extends State<PreferenceSurveyCard> {
  final Set<String> _selectedLandmarks = {'My Office'};

  final List<Map<String, dynamic>> _landmarkOptions = const [
    {'label': 'My Office', 'icon': Icons.business_outlined},
    {'label': 'Kids School', 'icon': Icons.school_outlined},
    {'label': 'Parents Home', 'icon': Icons.family_restroom_outlined},
    {'label': 'Metro Station', 'icon': Icons.subway_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.explore_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tailor your search by preferred commute',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select primary landmarks to prioritize listings within a 15-minute radius:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _landmarkOptions.map((opt) {
              final label = opt['label'] as String;
              final icon = opt['icon'] as IconData;
              final isSelected = _selectedLandmarks.contains(label);

              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                label: Text(label),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
                selectedColor: AppTheme.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLandmarks.add(label);
                    } else {
                      if (_selectedLandmarks.length > 1) {
                        _selectedLandmarks.remove(label);
                      }
                    }
                  });
                  widget.onSelectionChanged?.call(_selectedLandmarks.toList());
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
