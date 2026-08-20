import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_session.dart';
import '../core/providers.dart';
import '../core/session_provider.dart';
import '../features/entitlement/entitlement_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.embedded = false, this.session});

  final bool embedded;
  final AuthSession? session;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<MeEntitlements> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MeEntitlements> _load() {
    return ref.read(entitlementRepositoryProvider).getMyEntitlements();
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

  @override
  Widget build(BuildContext context) {
    final session = widget.session ?? ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My account'),
        actions: [
          if (!widget.embedded)
            IconButton(
              tooltip: 'My listings',
              onPressed: () => Navigator.pushNamed(context, '/my-listings'),
              icon: const Icon(Icons.list_alt_outlined),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<MeEntitlements>(
          future: _future,
          builder: (context, snapshot) {
            final children = <Widget>[];

            if (session != null) {
              children.addAll([
                _UserHeader(session: session),
                const SizedBox(height: 16),
              ]);
            }

            if (snapshot.connectionState == ConnectionState.waiting && children.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              children.add(_ErrorView(error: snapshot.error, onRetry: _refresh));
              return ListView(padding: const EdgeInsets.all(16), children: children);
            }

            final data = snapshot.data;
            if (data == null) {
              children.add(const Center(child: Text('No entitlements available.')));
              return ListView(padding: const EdgeInsets.all(16), children: children);
            }

            children.addAll([
              _TierHeader(data: data),
              const SizedBox(height: 24),
              Text('Plan limits', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._buildLimits(data),
              const SizedBox(height: 24),
              _UpgradeCta(upgradeUrl: data.upgradeUrl, isPlatinum: data.tier == 'PLATINUM', isFree: data.isFree),
            ]);

            return ListView(padding: const EdgeInsets.all(16), children: children);
          },
        ),
      ),
    );
  }

  List<Widget> _buildLimits(MeEntitlements data) {
    final widgets = <Widget>[];

    final activeLimit = data.maxActiveListings;
    if (activeLimit != null) {
      widgets.add(_LimitTile(
        label: 'Active listings',
        used: data.usage.activeListings,
        limit: activeLimit,
      ));
    }

    final imagesLimit = data.maxImagesPerListing;
    if (imagesLimit != null) {
      widgets.add(_LimitTile(label: 'Images per listing', limit: imagesLimit));
    }

    final featured = data.featuredListingSlots;
    if (featured != null) {
      widgets.add(_LimitTile(label: 'Featured slots', limit: featured));
    }

    final leads = data.maxLeadsPerMonth;
    if (leads != null) {
      widgets.add(_LimitTile(label: 'Leads / month', limit: leads));
    }

    final searches = data.maxSearchesPerDay;
    if (searches != null) {
      widgets.add(_LimitTile(label: 'Searches / day', limit: searches));
    }

    final canExport = data.canExportLeads;
    if (canExport != null) {
      widgets.add(_BooleanTile(label: 'Export leads', enabled: canExport));
    }

    final priority = data.prioritySupport;
    if (priority != null) {
      widgets.add(_BooleanTile(label: 'Priority support', enabled: priority));
    }

    if (widgets.isEmpty) {
      widgets.add(const ListTile(
        title: Text('No structured limits'),
        subtitle: Text('Plan limits are not yet configured.'),
      ));
    }

    return widgets;
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.session});
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          [
            user.phone,
            if (user.email != null && user.email!.isNotEmpty) user.email,
          ].join(' · '),
        ),
        trailing: Chip(label: Text(user.role), visualDensity: VisualDensity.compact),
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.data});
  final MeEntitlements data;

  Color _tierColor(BuildContext context) {
    switch (data.tier) {
      case 'PLATINUM':
        return const Color(0xFFC7D2FE);
      case 'GOLD':
        return const Color(0xFFFDE68A);
      case 'SILVER':
        return const Color(0xFFE5E7EB);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  String _tierLabel() => data.tier ?? 'Free';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _tierLabel(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  'Source: ${data.source}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (data.planCode != null) ...[
              const SizedBox(height: 8),
              Text(
                data.planCode!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({required this.label, this.used, required this.limit});
  final String label;
  final int? used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final showUsage = used != null && limit > 0;
    final ratio = showUsage ? (used! / limit).clamp(0.0, 1.0) : null;
    final color = ratio == null
        ? Theme.of(context).colorScheme.primary
        : (ratio >= 1
            ? Colors.red.shade600
            : (ratio >= 0.8 ? Colors.orange.shade700 : Theme.of(context).colorScheme.primary));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                showUsage ? '$used / $limit' : '$limit',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                color: color,
                backgroundColor: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BooleanTile extends StatelessWidget {
  const _BooleanTile({required this.label, required this.enabled});
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        enabled ? 'Included' : 'Not included',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}

class _UpgradeCta extends StatelessWidget {
  const _UpgradeCta({required this.upgradeUrl, required this.isPlatinum, required this.isFree});
  final String upgradeUrl;
  final bool isPlatinum;
  final bool isFree;

  String get _label {
    if (isPlatinum) return 'Manage subscription';
    if (isFree) return 'Upgrade to a paid plan';
    return 'Upgrade';
  }

  Future<void> _copyLink(BuildContext context) async {
    if (upgradeUrl.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: upgradeUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upgrade link copied. Paste it in your browser to continue.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Need more headroom?', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Higher tiers raise active-listing, lead, and search limits.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: upgradeUrl.isEmpty ? null : () => _copyLink(context),
                  child: Text(_label),
                ),
              ],
            ),
            if (upgradeUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                upgradeUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  String _message() {
    if (error is DioException) {
      final dioErr = error as DioException;
      final code = dioErr.response?.statusCode;
      if (code == 401) return 'Your session expired. Please sign in again.';
      final body = dioErr.response?.data;
      if (body is Map && body['error'] is String) return body['error'] as String;
      return dioErr.message ?? 'Failed to load entitlements.';
    }
    return error?.toString() ?? 'Failed to load entitlements.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 12),
        Text(
          _message(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
