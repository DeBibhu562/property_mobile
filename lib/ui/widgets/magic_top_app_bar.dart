import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MagicTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MagicTopAppBar({
    super.key,
    this.onMenuTap,
    this.onNotificationTap,
    this.onPostPropertyTap,
    this.unreadNotificationsCount = 2,
    this.showPostProperty = true,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onPostPropertyTap;
  final int unreadNotificationsCount;
  final bool showPostProperty;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left Drawer Hamburger Menu
            IconButton(
              onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.textPrimary,
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 8),

            // Brand Logo Pill (Exact Magicbricks style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'mb',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const Spacer(),

            // Notification Bell with Badge
            IconButton(
              onPressed: onNotificationTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications (2 unread)'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 6),

            // "Post Property FREE" Action Button
            if (showPostProperty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: GestureDetector(
                  onTap: onPostPropertyTap ??
                      () {
                        Navigator.of(context).pushNamed('/add-property');
                      },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Post Property',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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
