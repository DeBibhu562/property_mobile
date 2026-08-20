import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/project/project_models.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  bool _loading = true;
  List<ProjectSummary> _projects = const [];
  String? _error;
  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProjects);
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(projectRepositoryProvider).list();
      // Pin Team4 Aria demo project at the top of the list.
      const featuredSlug = 'team4-aria-miyapur';
      final sorted = [...items]
        ..sort((a, b) {
          if (a.slug == featuredSlug) return -1;
          if (b.slug == featuredSlug) return 1;
          return 0;
        });
      if (!mounted) return;
      setState(() => _projects = sorted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _priceRange(ProjectSummary proj) {
    final min = proj.minPrice != null ? _inr.format(proj.minPrice) : null;
    final max = proj.maxPrice != null ? _inr.format(proj.maxPrice) : null;
    if (min != null && max != null) return '$min – $max';
    if (min != null) return 'From $min';
    if (max != null) return 'Up to $max';
    return 'Price on request';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadProjects, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _projects.isEmpty
                  ? const Center(
                      child: Text(
                        'No projects found',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjects,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final proj = _projects[index];
                          final isFeatured = proj.slug == 'team4-aria-miyapur';
                          return _ProjectCard(
                            project: proj,
                            isFeatured: isFeatured,
                            priceLabel: _priceRange(proj),
                            onExplore: () => widget.onNavigate('/project-detail', proj.slug),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.isFeatured,
    required this.priceLabel,
    required this.onExplore,
  });

  final ProjectSummary project;
  final bool isFeatured;
  final String priceLabel;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final cover = project.coverImageUrl ?? '';
    final initial = project.name.isNotEmpty ? project.name[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        elevation: isFeatured ? 2 : 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isFeatured ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isFeatured ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onExplore,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: cover.isNotEmpty
                        ? Image.network(
                            cover,
                            fit: BoxFit.cover,
                            height: 180,
                            width: double.infinity,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return _CoverFallback(initial: initial, loading: true);
                            },
                            errorBuilder: (_, __, ___) => _CoverFallback(initial: initial),
                          )
                        : _CoverFallback(initial: initial),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (project.bhkLabels.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Wrap(
                        spacing: 6,
                        children: project.bhkLabels
                            .take(3)
                            .map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF312E81),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${project.builder}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onExplore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Explore',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({
    required this.initial,
    this.loading = false,
  });

  final String initial;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, size: 40, color: Colors.white70),
                const SizedBox(height: 8),
                Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
    );
  }
}
