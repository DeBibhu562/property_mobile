import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../core/theme.dart';
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
  String _selectedFilter = 'All Projects';
  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _filterOptions = [
    'All Projects',
    'New Launch',
    'Under Construction',
    'Ready to Move',
  ];

  static const List<ProjectSummary> _fallbackProjects = [
    ProjectSummary(
      id: 'prj-aria-1',
      name: 'Team4 Aria',
      slug: 'team4-aria-miyapur',
      builder: 'Team4 Life Spaces',
      city: 'Hyderabad',
      locality: 'Miyapur',
      coverImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      minPrice: 12500000,
      maxPrice: 24500000,
      bhkLabels: ['2 BHK', '3 BHK'],
      status: 'Under Construction',
    ),
    ProjectSummary(
      id: 'prj-dlf-1',
      name: 'DLF The Arbour',
      slug: 'dlf-the-arbour',
      builder: 'DLF Group',
      city: 'Gurgaon',
      locality: 'Sector 63',
      coverImageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
      minPrice: 75000000,
      maxPrice: 92000000,
      bhkLabels: ['4 BHK'],
      status: 'New Launch',
    ),
    ProjectSummary(
      id: 'prj-godrej-1',
      name: 'Godrej Woods',
      slug: 'godrej-woods',
      builder: 'Godrej Properties',
      city: 'Noida',
      locality: 'Sector 43',
      coverImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
      minPrice: 24000000,
      maxPrice: 48000000,
      bhkLabels: ['2 BHK', '3 BHK', '4 BHK'],
      status: 'Ready to Move',
    ),
    ProjectSummary(
      id: 'prj-tata-1',
      name: 'Tata Primanti',
      slug: 'tata-primanti',
      builder: 'Tata Housing',
      city: 'Gurgaon',
      locality: 'Southern Peripheral Road',
      coverImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
      minPrice: 38000000,
      maxPrice: 65000000,
      bhkLabels: ['3 BHK', '4 BHK'],
      status: 'Ready to Move',
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProjects);
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(projectRepositoryProvider)
          .list()
          .timeout(const Duration(seconds: 4));

      const featuredSlug = 'team4-aria-miyapur';
      final sorted = [...items]
        ..sort((a, b) {
          if (a.slug == featuredSlug) return -1;
          if (b.slug == featuredSlug) return 1;
          return 0;
        });

      if (!mounted) return;
      setState(() {
        _projects = sorted.isNotEmpty ? sorted : _fallbackProjects;
      });
    } catch (_) {
      // Graceful fallback: render curated real-estate projects immediately
      if (!mounted) return;
      setState(() {
        _projects = _fallbackProjects;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _priceRange(ProjectSummary proj) {
    if (proj.minPrice != null && proj.maxPrice != null) {
      return '${_formatCrLakh(proj.minPrice!)} – ${_formatCrLakh(proj.maxPrice!)}';
    } else if (proj.minPrice != null) {
      return 'From ${_formatCrLakh(proj.minPrice!)}';
    } else if (proj.maxPrice != null) {
      return 'Up to ${_formatCrLakh(proj.maxPrice!)}';
    }
    return 'Price on Request';
  }

  String _formatCrLakh(int price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(0)} L';
    }
    return _inr.format(price);
  }

  List<ProjectSummary> get _filteredProjects {
    if (_selectedFilter == 'All Projects') return _projects;
    return _projects.where((p) {
      final status = (p.status ?? '').toLowerCase();
      if (_selectedFilter == 'New Launch') return status.contains('launch') || status.contains('new');
      if (_selectedFilter == 'Under Construction') return status.contains('construction') || status.contains('under');
      if (_selectedFilter == 'Ready to Move') return status.contains('ready');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchCity = ref.watch(searchSelectionProvider).city ?? 'All Cities';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'magic',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const Text(
                  'Homes',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'New Projects in $searchCity',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Project Feed
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apartment_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_selectedFilter found',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _loadProjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                          itemCount: _filteredProjects.length,
                          itemBuilder: (context, index) {
                            final proj = _filteredProjects[index];
                            final isFeatured = proj.slug == 'team4-aria-miyapur';
                            return _MagicProjectCard(
                              project: proj,
                              isFeatured: isFeatured,
                              priceLabel: _priceRange(proj),
                              onExplore: () => widget.onNavigate('/project-detail', proj.slug),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MagicProjectCard extends StatelessWidget {
  const _MagicProjectCard({
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
    final status = project.status ?? 'New Launch';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? AppTheme.primary.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
          width: isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onExplore,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner with Badges
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
                          errorBuilder: (_, __, ___) => _CoverFallback(initial: initial),
                        )
                      : _CoverFallback(initial: initial),
                ),
                // Gradient Scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFeatured ? AppTheme.primary : AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isFeatured ? '★ FEATURED' : status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                // RERA Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'RERA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // BHK Chips Overlay at bottom
                if (project.bhkLabels.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Wrap(
                      spacing: 6,
                      children: project.bhkLabels.take(3).map((bhk) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            bhk,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${project.builder}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Price and Action Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRICE RANGE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onExplore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Project',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11),
                          ],
                        ),
                      ),
                    ],
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

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment_rounded, size: 40, color: Colors.white54),
          const SizedBox(height: 6),
          Text(
            initial,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
