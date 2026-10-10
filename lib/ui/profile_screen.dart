import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_persona.dart';
import '../core/auth_session.dart';
import '../core/providers.dart';
import '../core/session_provider.dart';
import '../features/entitlement/entitlement_models.dart';
import 'widgets/app_error_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.embedded = false, this.session});

  final bool embedded;
  final AuthSession? session;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<MeEntitlements?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MeEntitlements?> _load() async {
    try {
      return await ref.read(entitlementRepositoryProvider).getMyEntitlements();
    } catch (_) {
      // Graceful fallback for offline / unauthenticated states: returns null so fallback UI renders seamlessly
      return null;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _signOut() async {
    await ref.read(authSessionProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  void _openDeleteAccount() {
    Navigator.of(context).pushNamed('/delete-account');
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session ?? ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (!widget.embedded)
            IconButton(
              tooltip: 'My listings',
              onPressed: () => Navigator.pushNamed(context, '/my-listings'),
              icon: const Icon(Icons.home_work_outlined, color: Color(0xFF475569)),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Color(0xFF475569)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MeEntitlements?>(
          future: _future,
          builder: (context, snapshot) {
            final entitlements = snapshot.data;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (session != null) ...[
                  _HeroUserHeader(session: session),
                  const SizedBox(height: 16),
                ],

                // Membership & Entitlements Section
                _MembershipCard(
                  entitlements: entitlements,
                  session: session,
                ),
                const SizedBox(height: 18),

                // Account Settings & Security
                const _SectionTitle(title: 'Account Settings'),
                const SizedBox(height: 10),
                _SettingsGroup(
                  onSignOut: _signOut,
                ),
                const SizedBox(height: 18),

                Text(
                  'Danger zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 10),
                _DangerZoneCard(
                  onDeleteAccount: _openDeleteAccount,
                ),
                const SizedBox(height: 24),

                // Quick Activity Metrics
                _ActivitySummaryRow(
                  favoritesCount: ref.watch(favoritesProvider).length,
                ),
                const SizedBox(height: 20),

                // Quick Real Estate Services & Tools
                const _SectionTitle(title: 'Property Tools & Services'),
                const SizedBox(height: 10),
                _QuickToolsGrid(
                  onPostProperty: () => Navigator.of(context).pushNamed('/add-property'),
                  onEmiCalc: () => Navigator.of(context).pushNamed('/home'),
                  onInsights: () => Navigator.of(context).pushNamed('/home'),
                  onSuggestions: () => Navigator.of(context).pushNamed('/smart-suggestions'),
                ),
                const SizedBox(height: 24),

                // Structured Limits (if available from backend)
                if (entitlements != null && _hasStructuredLimits(entitlements)) ...[
                  const _SectionTitle(title: 'Plan Usage & Quotas'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildLimitsList(entitlements),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasStructuredLimits(MeEntitlements data) {
    return data.maxActiveListings != null ||
        data.maxImagesPerListing != null ||
        data.maxLeadsPerMonth != null ||
        data.maxSearchesPerDay != null;
  }

  List<Widget> _buildLimitsList(MeEntitlements data) {
    final widgets = <Widget>[];

    final activeLimit = data.maxActiveListings;
    if (activeLimit != null) {
      widgets.add(_LimitProgressTile(
        label: 'Active Listings',
        used: data.usage.activeListings,
        limit: activeLimit,
      ));
    }

    final imagesLimit = data.maxImagesPerListing;
    if (imagesLimit != null) {
      widgets.add(_LimitProgressTile(label: 'Images per Listing', limit: imagesLimit));
    }

    final leads = data.maxLeadsPerMonth;
    if (leads != null) {
      widgets.add(_LimitProgressTile(label: 'Direct Buyer Leads / Month', limit: leads));
    }

    final searches = data.maxSearchesPerDay;
    if (searches != null) {
      widgets.add(_LimitProgressTile(label: 'Search Limit / Day', limit: searches));
    }

    return widgets;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _HeroUserHeader extends StatelessWidget {
  const _HeroUserHeader({required this.session});
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final roleLabel = switch (user.role.toUpperCase()) {
      'ADMIN' || 'SUPER_ADMIN' => 'Administrator',
      'OWNER' || 'SELLER' => 'Property Owner',
      'AGENT' || 'AGENCY_ADMIN' => 'Real Estate Agent',
      _ => 'Buyer / Explorer',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF67E8F9), // Light cyan verified badge
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({this.entitlements, required this.session});
  final MeEntitlements? entitlements;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final isPaid = entitlements != null && !entitlements!.isFree;
    final tierTitle = entitlements?.tier ?? (isPaid ? 'Premium Tier' : 'Free Explorer');
    final upgradeUrl = entitlements?.upgradeUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.workspace_premium : Icons.stars_rounded,
                  color: isPaid ? const Color(0xFFD97706) : const Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isPaid ? 'Active Paid Subscription' : 'Standard Real Estate Privileges Active',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (upgradeUrl.isNotEmpty)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: upgradeUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgrade link copied to clipboard!')),
                    );
                  },
                  child: const Text('Upgrade'),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          // Included perks
          _PerkRow(icon: Icons.check_circle_outline, text: 'Search verified listings across India'),
          const SizedBox(height: 6),
          _PerkRow(icon: Icons.check_circle_outline, text: 'Direct contact with property owners & agents'),
          const SizedBox(height: 6),
          _PerkRow(icon: Icons.check_circle_outline, text: 'Smart AI match recommendations & alerts'),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)), // Emerald green
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow({required this.favoritesCount});
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Saved Homes',
            value: '$favoritesCount',
            icon: Icons.favorite,
            color: const Color(0xFFE11D48),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            label: 'Active Alerts',
            value: 'On',
            icon: Icons.notifications_active,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            label: 'Verified City',
            value: 'Delhi NCR',
            icon: Icons.location_on,
            color: Color(0xFF059669),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _QuickToolsGrid extends StatelessWidget {
  const _QuickToolsGrid({
    required this.onPostProperty,
    required this.onEmiCalc,
    required this.onInsights,
    required this.onSuggestions,
  });

  final VoidCallback onPostProperty;
  final VoidCallback onEmiCalc;
  final VoidCallback onInsights;
  final VoidCallback onSuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ToolTile(
                title: 'Post Property',
                subtitle: 'List for sale/rent',
                icon: Icons.add_home_work_outlined,
                badge: 'FREE',
                color: const Color(0xFF4F46E5),
                onTap: onPostProperty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolTile(
                title: 'Smart Matches',
                subtitle: 'AI suggestions',
                icon: Icons.lightbulb_outline,
                badge: 'NEW',
                color: const Color(0xFFF59E0B),
                onTap: onSuggestions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolTile(
                title: 'EMI Calculator',
                subtitle: 'Home loan plans',
                icon: Icons.calculate_outlined,
                color: const Color(0xFF059669),
                onTap: onEmiCalc,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolTile(
                title: 'Price Trends',
                subtitle: 'Locality insights',
                icon: Icons.trending_up,
                color: const Color(0xFF2563EB),
                onTap: onInsights,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge == 'FREE'
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: badge == 'FREE'
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitProgressTile extends StatelessWidget {
  const _LimitProgressTile({required this.label, this.used, required this.limit});
  final String label;
  final int? used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final showUsage = used != null && limit > 0;
    final ratio = showUsage ? (used! / limit).clamp(0.0, 1.0) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              Text(
                showUsage ? '$used / $limit' : '$limit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.onSignOut,
  });

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF475569)),
            title: const Text('Help & Customer Support'),
            subtitle: const Text('FAQs, support email, and user guides', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email: support@propertydilado.com')),
              );
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF475569)),
            title: const Text('Sign out'),
            subtitle: const Text('End your session on this device', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onDeleteAccount});
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Card(
      elevation: 0,
      color: errorColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: errorColor),
        title: Text(
          'Delete account',
          style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Permanently delete account and all data',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: errorColor),
        onTap: onDeleteAccount,
      ),
    );
  }
}
