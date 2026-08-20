import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/lead/lead_models.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  late Future<LeadPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LeadPage> _load() => ref.read(leadRepositoryProvider).sellerLeads();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _updateStatus(SellerLead lead, String status) async {
    try {
      await ref.read(leadRepositoryProvider).updateLeadStatus(lead.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lead marked $status')),
      );
      await _refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead inbox')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<LeadPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
                  ),
                ],
              );
            }
            final page = snapshot.data;
            final items = page?.items ?? const <SellerLead>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No leads yet.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final lead = items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lead.subjectTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _StatusChip(status: lead.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(lead.message),
                        if (lead.buyerName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${lead.buyerName}${lead.buyerPhone != null ? ' · ${lead.buyerPhone}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (lead.status == 'NEW') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _updateStatus(lead, 'CONTACTED'),
                                child: const Text('Mark contacted'),
                              ),
                              TextButton(
                                onPressed: () => _updateStatus(lead, 'CLOSED'),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
