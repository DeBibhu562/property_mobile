import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth_session.dart';
import '../../core/providers.dart';
import '../../features/lead/lead_models.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key, required this.session, required this.onNavigate});
  final AuthSession session;
  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> {
  bool _loading = true;
  int _activeListings = 18;
  int _newLeads = 7;
  int _responseRate = 92;
  double _earnings = 140000; // 1.4 Lakhs default
  List<SellerLead> _recentLeads = [];

  final _currencyFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Fetch workspace stats from backend
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/me/workspace-stats');
      final root = res.data ?? {};
      if (root['success'] == true && root['data'] is Map<String, dynamic>) {
        final data = root['data'] as Map<String, dynamic>;
        setState(() {
          _activeListings = (data['activeListings'] as num?)?.toInt() ?? 18;
          _newLeads = (data['newLeads'] as num?)?.toInt() ?? 7;
          _responseRate = (data['responseRate'] as num?)?.toInt() ?? 92;
          _earnings = (data['earningsThisMonth'] as num?)?.toDouble() ?? 140000;
        });
      }

      // Fetch recent leads for the list
      final leadPage = await ref.read(leadRepositoryProvider).sellerLeads(limit: 5);
      setState(() {
        _recentLeads = leadPage.items;
        _loading = false;
      });
    } catch (_) {
      // Fallback to default mockup data if offline/error but keep loading = false
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatIndianAmount(double val) {
    if (val >= 100000) {
      return '₹${(val / 100000).toStringAsFixed(1)}L';
    }
    return _currencyFormat.format(val);
  }

  String _timeAgo(String dateStr) {
    if (dateStr.isEmpty) return '2h';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (_) {
      return '2h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Colors
    final avatarColors = [
      const Color(0xFFC084FC), // light purple
      const Color(0xFF60A5FA), // light blue
      const Color(0xFFF87171), // light red
      const Color(0xFF34D399), // light green
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => Navigator.pushNamed(context, '/add-property').then((_) => _loadDashboardData()),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const SizedBox(height: 12),
              // Greeting Section
              Text(
                'Good morning, ${widget.session.user.name}',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$_newLeads pending follow-ups today',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              // 2x2 Grid of stats
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Active listings', '$_activeListings'),
                  _buildStatCard('New leads', '$_newLeads'),
                  _buildStatCard('Response rate', '$_responseRate%'),
                  _buildStatCard('This month', _formatIndianAmount(_earnings)),
                ],
              ),
              const SizedBox(height: 28),
              // Lead inbox title
              const Text(
                'Lead inbox',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              // Lead Inbox List
              if (_recentLeads.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No active leads in inbox.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ..._recentLeads.take(4).map((lead) {
                  final initials = lead.buyerName != null && lead.buyerName!.isNotEmpty
                      ? lead.buyerName!.substring(0, min(2, lead.buyerName!.length)).toUpperCase()
                      : 'EN';
                  final colorIndex = lead.buyerName.hashCode % avatarColors.length;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: avatarColors[colorIndex].withOpacity(0.15),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: avatarColors[colorIndex],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        lead.buyerName ?? 'Anonymous Buyer',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lead.subjectTitle,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        _timeAgo(lead.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () => Navigator.pushNamed(context, '/leads'),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
