import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/listing/listing_models.dart';

class ListingVisibilityScreen extends ConsumerStatefulWidget {
  const ListingVisibilityScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingVisibilityScreen> createState() => _ListingVisibilityScreenState();
}

class _ListingVisibilityScreenState extends ConsumerState<ListingVisibilityScreen> {
  late Future<ListingVisibility> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ListingVisibility> _load() {
    return ref.read(listingRepositoryProvider).visibility(widget.listingId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visibility')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ListingVisibility>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error, onRetry: _refresh);
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('No data.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RankCard(rank: data.rank),
                const SizedBox(height: 16),
                _StatsRow(impressions: data.impressions, windowDays: data.windowDays),
                const SizedBox(height: 24),
                Text('Daily impressions', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Aggregated overnight from Redis. Today\'s impressions land here after the next nightly run.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _DailyTable(daily: data.impressions.daily),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'As of ${data.freshness.todayUtc} UTC',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank});
  final RankSummary rank;

  Color _bandColor() {
    switch (rank.band) {
      case 'high':
        return Colors.green.shade700;
      case 'good':
        return Colors.lightBlue.shade700;
      case 'fair':
        return Colors.orange.shade700;
      case 'low':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _label() {
    switch (rank.band) {
      case 'high':
        return 'High';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'low':
        return 'Low';
      default:
        return 'Unscored';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rank band',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bandColor().withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _label(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _bandColor()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rank.score == null ? '—' : rank.score!.toStringAsFixed(3),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rank.updatedAt == null
                        ? 'Not yet scored — the worker visits new listings hourly.'
                        : 'Scored ${rank.updatedAt!.toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.impressions, required this.windowDays});
  final ImpressionSummary impressions;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: '7-day impressions',
            value: '${impressions.last7Days}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: '$windowDays-day impressions',
            value: '${impressions.total}',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _DailyTable extends StatelessWidget {
  const _DailyTable({required this.daily});
  final List<DailyImpression> daily;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No impressions recorded for this listing yet.'),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  child: Text('Date (UTC)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 110, child: Text('Impressions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...daily.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(d.date, style: const TextStyle(fontFamily: 'monospace')),
                  ),
                  SizedBox(width: 110, child: Text('${d.count}', style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
        ],
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
      final code = (error as DioException).response?.statusCode;
      if (code == 401) return 'Your session expired. Please sign in again.';
      if (code == 403) return 'You don\'t have permission to view this listing\'s analytics.';
      if (code == 404) return 'That listing was not found.';
    }
    return error?.toString() ?? 'Failed to load visibility.';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 12),
        Text(_message(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
