import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// Buyer Insights — locality rates, landmarks, and a simple market snapshot
/// for the currently selected search city.
class BuyerInsightsScreen extends ConsumerStatefulWidget {
  const BuyerInsightsScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<BuyerInsightsScreen> createState() => _BuyerInsightsScreenState();
}

class _BuyerInsightsScreenState extends ConsumerState<BuyerInsightsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _localities = const [];
  List<dynamic> _landmarks = const [];
  List<dynamic> _projects = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final city = ref.read(searchSelectionProvider).city ?? 'New Delhi';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/search/portal-meta', queryParameters: {'city': city});
      final payload = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (!mounted) return;
      setState(() {
        _localities = (payload['localities'] as List<dynamic>?) ?? [];
        _landmarks = (payload['landmarks'] as List<dynamic>?) ?? [];
        _projects = (payload['projects'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load market insights.';
        _loading = false;
      });
    }
  }

  double? _parseRate(dynamic rateSqft) {
    final raw = rateSqft?.toString() ?? '';
    final match = RegExp(r'([\d.]+)').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(searchSelectionProvider).city ?? 'New Delhi';
    final rates = _localities
        .map((l) => _parseRate(l is Map ? l['rateSqft'] : null))
        .whereType<double>()
        .toList();
    final maxRate = rates.isEmpty ? 1.0 : rates.reduce((a, b) => a > b ? a : b);
    final avgRate = rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        city,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Market snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Locality rates and connectivity for $city',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Localities',
                            value: '${_localities.length}',
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Avg rate',
                            value: avgRate == null ? '—' : '₹${avgRate.toStringAsFixed(1)}K',
                            icon: Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Projects',
                            value: '${_projects.length}',
                            icon: Icons.apartment_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Locality price bands',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Average asking rate per sq.ft.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    if (_localities.isEmpty)
                      const _EmptyHint(text: 'No locality data for this city yet.')
                    else
                      ..._localities.map((raw) {
                        final l = raw as Map;
                        final name = (l['name'] ?? '').toString();
                        final rateLabel = (l['rateSqft'] ?? '').toString();
                        final rate = _parseRate(rateLabel) ?? 0;
                        final pct = (rate / maxRate).clamp(0.08, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    rateLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F46E5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                    const Text(
                      'Nearby landmarks',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_landmarks.isEmpty)
                      const _EmptyHint(text: 'No landmarks mapped for this city.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _landmarks.map((raw) {
                          final m = raw as Map;
                          final name = (m['name'] ?? '').toString();
                          final type = (m['type'] ?? 'POI').toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type == 'METRO' ? Icons.train_outlined : Icons.place_outlined,
                                  size: 16,
                                  color: const Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 220),
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ready to explore inventory?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Browse verified listings in $city matched to your budget and BHK.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF312E81),
                            ),
                            onPressed: () => widget.onNavigate('/properties'),
                            child: const Text('Browse properties'),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}
