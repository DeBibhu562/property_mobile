import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onCenterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Top Matches
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                label: 'Top Matches',
                isSelected: selectedIndex == 0,
                onTap: () => onItemSelected(0),
              ),

              // 2. Post Free Ad
              _NavItem(
                icon: Icons.add_circle_outline_rounded,
                selectedIcon: Icons.add_circle_rounded,
                label: 'Post Free Ad',
                isSelected: selectedIndex == 1,
                onTap: () => onItemSelected(1),
              ),

              // 3. Elevated Center FAB (Red Brand Menu)
              _CenterFabButton(onTap: onCenterTap),

              // 4. New Projects (magicHomes)
              _NavItem(
                icon: Icons.apartment_outlined,
                selectedIcon: Icons.apartment_rounded,
                label: 'New Projects',
                isSelected: selectedIndex == 2,
                badgeText: 'New',
                onTap: () => onItemSelected(2),
              ),

              // 5. You (Profile / Dashboard)
              _NavItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'You',
                isSelected: selectedIndex == 3,
                onTap: () => onItemSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primary : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 68,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            if (badgeText != null)
              Positioned(
                top: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenterFabButton extends StatelessWidget {
  const _CenterFabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  9,
                  (_) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
