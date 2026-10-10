import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_error_formatter.dart';
import '../core/providers.dart';
import '../features/admin/admin_models.dart';
import 'widgets/app_error_state.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  late Future<List<ModerationProperty>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ModerationProperty>> _load() {
    return ref.read(adminRepositoryProvider).moderationQueue();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _approve(ModerationProperty item) async {
    try {
      await ref.read(adminRepositoryProvider).approveProperty(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property approved successfully')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final parsed = ApiErrorFormatter.format(e, defaultMessage: 'Approve failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parsed.message)),
      );
    }
  }

  Future<void> _reject(ModerationProperty item) async {
    try {
      await ref.read(adminRepositoryProvider).rejectProperty(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property rejected')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final parsed = ApiErrorFormatter.format(e, defaultMessage: 'Reject failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parsed.message)),
      );
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    // Force Dark Mode theme styling for Admin Workspace
    final darkBackground = const Color(0xFF020617); // Obsidian black
    final darkCardBackground = const Color(0xFF0F172A); // Slate blue

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBackground,
        cardTheme: CardThemeData(
          color: darkCardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                title: const Text('Moderation Queue', style: TextStyle(color: Colors.white)),
                backgroundColor: darkBackground,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<ModerationProperty>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  error: snapshot.error,
                  isDark: true,
                  title: 'Could Not Load Moderation Queue',
                  onRetry: _refresh,
                );
              }

              final items = snapshot.data ?? const <ModerationProperty>[];

              // Filter SLA overdue items (submissions older than 2 hours)
              final now = DateTime.now();
              final overSlaItems = items.where((item) {
                final diff = now.difference(item.createdAt);
                return diff.inHours >= 2 && item.status == 'PENDING';
              }).toList();

              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header text matching Screen 5
                    const Text(
                      'Moderation queue',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${items.length} listings waiting · target under 2 hrs',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // SLA Overdue Alert Box matching Screen 5
                    if (overSlaItems.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C2D12).withOpacity(0.2), // soft burnt orange
                          border: Border.all(color: const Color(0xFFEA580C)), // dark orange
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${overSlaItems.length} listings over SLA',
                          style: const TextStyle(
                            color: Color(0xFFF97316), // bright orange text
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: const Center(
                          child: Text(
                            'Moderation queue is empty.',
                            style: TextStyle(color: Colors.white38, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...items.map((item) {
                        final diff = now.difference(item.createdAt);
                        final isOverdue = diff.inHours >= 2;

                        final badgeLabel = isOverdue ? 'Overdue' : 'In queue';
                        final badgeColor = isOverdue ? const Color(0xFFEF4444) : Colors.grey.shade500;

                        // Calculate visual labels based on mock details
                        final String checksStatus;
                        if (item.rejectedImagesCount > 0) {
                          checksStatus = 'Blur detected on ${item.rejectedImagesCount} photos · submitted ${_timeAgo(item.createdAt)}';
                        } else {
                          checksStatus = 'All checks passed · submitted ${_timeAgo(item.createdAt)}';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Overdue Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.bhk}BHK · ${item.locality}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badgeColor),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Subtitle
                                Text(
                                  checksStatus,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                // Approve / Reject buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981), // Emerald green
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _approve(item),
                                          child: const Text(
                                            'Approve',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFEF4444),
                                            side: const BorderSide(color: Color(0xFFEF4444)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _reject(item),
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
