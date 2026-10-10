import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/listing/listing_models.dart';
import 'widgets/app_error_state.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  late Future<List<MyListing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MyListing>> _load() {
    return ref.read(listingRepositoryProvider).myListings();
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
      appBar: AppBar(title: const Text('My listings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MyListing>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error, onRetry: _refresh);
            }
            final items = snapshot.data ?? const <MyListing>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No listings yet.')),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ListingTile(listing: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});
  final MyListing listing;

  String get _bandLabel {
    final score = listing.rankScore;
    if (score == null) return 'Unscored';
    if (score >= 0.75) return 'High';
    if (score >= 0.5) return 'Good';
    if (score >= 0.25) return 'Fair';
    return 'Low';
  }

  Color _bandColor(BuildContext context) {
    final score = listing.rankScore;
    if (score == null) return Colors.grey;
    if (score >= 0.75) return Colors.green.shade700;
    if (score >= 0.5) return Colors.lightBlue.shade700;
    if (score >= 0.25) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = listing.rankScore == null ? '—' : listing.rankScore!.toStringAsFixed(2);
    return ListTile(
      title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          _StatusChip(status: listing.status),
          const SizedBox(width: 8),
          Text(
            '$_bandLabel · $scoreText',
            style: TextStyle(color: _bandColor(context), fontWeight: FontWeight.w600),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(
        context,
        '/listing-visibility',
        arguments: listing.id,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      error: error,
      title: 'Could Not Load Listings',
      onRetry: onRetry,
    );
  }
}
