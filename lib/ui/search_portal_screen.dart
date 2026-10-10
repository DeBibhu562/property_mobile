import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_session.dart';
import '../core/api_envelope.dart';
import '../core/city_resolver.dart';
import '../core/providers.dart';
import '../features/property/property_models.dart';
import '../core/theme.dart';
import 'smart_suggestions_screen.dart';

class SearchPortalScreen extends ConsumerStatefulWidget {
  const SearchPortalScreen({
    super.key,
    required this.session,
    required this.onNavigate,
  });

  final AuthSession session;
  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<SearchPortalScreen> createState() => _SearchPortalScreenState();
}

class _SearchPortalScreenState extends ConsumerState<SearchPortalScreen> {
  CancelToken? _cancelToken;
  bool _loading = true;
  Object? _error;
  bool _suggestionsPrompted = false;
  List<dynamic> _localities = [];
  List<dynamic> _landmarks = [];
  List<dynamic> _projects = [];

  @override
  void initState() {
    super.initState();
    final initialCity = ref.read(searchSelectionProvider).city ?? 'New Delhi';
    _projects = _getFallbackProjects(initialCity);
    _localities = _getFallbackLocalities(initialCity);
    _landmarks = _getFallbackLandmarks(initialCity);
    _loading = false;
    Future.microtask(() async {
      await _loadPortalMeta();
      _maybeOpenSmartSuggestions();
    });
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _maybeOpenSmartSuggestions() {
    if (_suggestionsPrompted || !mounted) return;
    _suggestionsPrompted = true;
    // Wait for dismiss prefs to hydrate, then decide.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final city = ref.read(searchSelectionProvider).city ?? 'New Delhi';
      final dismissed =
          ref.read(smartSuggestionsDismissProvider.notifier).isDismissed(city);
      if (dismissed) return;
      widget.onNavigate('/smart-suggestions', {
        'city': city,
        'autoOpened': true,
      });
    });
  }

  Future<void> _loadPortalMeta() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    final searchState = ref.read(searchSelectionProvider);
    final city = CityResolver.primary(searchState.city ?? 'New Delhi');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio
          .get(
            '/search/portal-meta',
            queryParameters: {'city': city},
            cancelToken: token,
          )
          .timeout(const Duration(seconds: 3));
      final payload = tryUnwrapData(res.data);
      if (!mounted || token.isCancelled) return;
      final fetchedProjects = (payload?['projects'] as List<dynamic>?) ?? [];
      final fetchedLocalities = (payload?['localities'] as List<dynamic>?) ?? [];
      final fetchedLandmarks = (payload?['landmarks'] as List<dynamic>?) ?? [];

      setState(() {
        _localities = fetchedLocalities.isNotEmpty ? fetchedLocalities : _getFallbackLocalities(city);
        _landmarks = fetchedLandmarks.isNotEmpty ? fetchedLandmarks : _getFallbackLandmarks(city);
        _projects = fetchedProjects.isNotEmpty ? fetchedProjects : _getFallbackProjects(city);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        _localities = _getFallbackLocalities(city);
        _landmarks = _getFallbackLandmarks(city);
        _projects = _getFallbackProjects(city);
        _loading = false;
      });
    }
  }

  List<dynamic> _getFallbackLocalities(String city) {
    return [
      {'name': 'Dwarka', 'count': '140+ properties'},
      {'name': 'Rohini', 'count': '95+ properties'},
      {'name': 'Saket', 'count': '60+ properties'},
      {'name': 'Janakpuri', 'count': '45+ properties'},
      {'name': 'Vasant Kunj', 'count': '80+ properties'},
      {'name': 'Greater Kailash', 'count': '50+ properties'},
    ];
  }

  List<dynamic> _getFallbackLandmarks(String city) {
    return [
      {'name': 'Metro Station', 'count': '210+ near transit'},
      {'name': 'International Airport', 'count': '85+ nearby'},
      {'name': 'City Mall', 'count': '120+ near shopping'},
      {'name': 'IT Tech Park', 'count': '150+ near offices'},
    ];
  }

  List<dynamic> _getFallbackProjects(String city) {
    return [
      {
        'id': 'prj_dlf_arbour',
        'slug': 'dlf-the-arbour',
        'name': 'DLF The Arbour',
        'locality': 'Sector 63',
        'city': city,
        'priceLabel': '₹ 7.5 Cr - 9.2 Cr',
        'coverImageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
        'configs': [{'bhk': 4}],
      },
      {
        'id': 'prj_godrej_woods',
        'slug': 'godrej-woods',
        'name': 'Godrej Woods',
        'locality': 'Sector 43',
        'city': city,
        'priceLabel': '₹ 2.4 Cr - 4.8 Cr',
        'coverImageUrl': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
        'configs': [{'bhk': 2}, {'bhk': 3}],
      },
      {
        'id': 'prj_tata_primanti',
        'slug': 'tata-primanti',
        'name': 'Tata Primanti',
        'locality': 'Southern Peripheral Road',
        'city': city,
        'priceLabel': '₹ 3.8 Cr - 6.5 Cr',
        'coverImageUrl': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
        'configs': [{'bhk': 3}, {'bhk': 4}],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final searchSelection = ref.watch(searchSelectionProvider);
    final city = searchSelection.city ?? 'New Delhi';
    final category = searchSelection.category;
    final isBuy = category == 'buy';
    final isRent = category == 'rent';
    final searchHint = switch (category) {
      'rent' => '2BHK under 25k in Rohini',
      'commercial' => 'Office space in Connaught Place',
      'pg' => 'PG near Dwarka Metro',
      'projects' => 'New launch projects in Dwarka',
      _ => '2BHK under 2Cr in Rohini',
    };
    final matchedSubtitle = isRent
        ? 'Homes available for rent near you'
        : 'Projects from the best developers';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF3F4F6), // Slightly darker gray/purple top
                    Color(0xFFF8FAFC), // Fades to scaffold background
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
              children: [
                const SizedBox(height: 4),

                // 1. Sleek Category Pills Row (~34px height)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildCategoryPill(
                        'Buy',
                        Icons.sell_outlined,
                        category == 'buy',
                        onTap: () => _onCategoryTap('buy'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        'Projects',
                        Icons.business,
                        category == 'projects',
                        badge: 'NEW',
                        onTap: () => _onCategoryTap('projects'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        'Rent',
                        Icons.vpn_key_outlined,
                        category == 'rent',
                        onTap: () => _onCategoryTap('rent'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        'Commercial',
                        Icons.business_center_outlined,
                        category == 'commercial',
                        onTap: () => _onCategoryTap('commercial'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        'PG',
                        Icons.group_outlined,
                        category == 'pg',
                        onTap: () => _onCategoryTap('pg'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Compact Unified Search Bar (~48px height)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // City Picker Trigger
                        InkWell(
                          onTap: () => ref.read(searchSelectionProvider.notifier).resetCity(),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 85),
                                  child: Text(
                                    city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        // Search Hint Trigger
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (category == 'projects') {
                                widget.onNavigate('/projects');
                              } else {
                                _openListingsForCategory(category == 'buy' ? 'buy' : category);
                              }
                            },
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      searchHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.search, color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Compact Quick Search / Locality Chips (height ~26px)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _openListingsForCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history, size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 5),
                              const Text(
                                'Dwarka Mor',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '40+ new',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openListingsForCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore All Localities',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 14, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Perfectly matched homes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Perfectly matched homes for you',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              matchedSubtitle,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (category == 'projects' || isBuy) {
                            widget.onNavigate('/projects');
                          } else {
                            _openListingsForCategory(category);
                          }
                        },
                        child: const Text(
                          'View more',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Could not load projects'),
                                  TextButton(onPressed: _loadPortalMeta, child: const Text('Retry')),
                                ],
                              ),
                            )
                          : _projects.isEmpty
                              ? const Center(child: Text('No projects for this city yet'))
                              : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _projects.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final p = _projects[idx] as Map;
                            return _MatchedHomeCard(
                              project: p,
                              onTap: () {
                                final slug = (p['slug'] ?? p['id'] ?? '').toString();
                                if (slug.isEmpty) return;
                                widget.onNavigate('/project-detail', slug);
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCategoryTap(String category) {
    ref.read(searchSelectionProvider.notifier).setCategory(category);
    switch (category) {
      case 'buy':
        // Stay on portal — buy is the home discovery surface.
        break;
      case 'projects':
        widget.onNavigate('/projects');
        break;
      case 'rent':
      case 'commercial':
      case 'pg':
        _openListingsForCategory(category);
        break;
    }
  }

  void _openListingsForCategory(String category) {
    final args = switch (category) {
      'rent' => {
          'type': 'RENT',
          'listingType': 'RESIDENTIAL',
          'title': 'Homes for Rent',
        },
      'commercial' => {'listingType': 'COMMERCIAL', 'title': 'Commercial Spaces'},
      'pg' => {'listingType': 'PG', 'title': 'PG / Co-living'},
      _ => {
          'type': 'SALE',
          'listingType': 'RESIDENTIAL',
          'title': 'Homes for Sale',
        },
    };
    widget.onNavigate('/properties', args);
  }

  Widget _buildCategoryPill(
    String title,
    IconData icon,
    bool isSelected, {
    String? badge,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? AppTheme.primary : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

class _MatchedHomeCard extends StatelessWidget {
  const _MatchedHomeCard({
    required this.project,
    required this.onTap,
  });

  final Map project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (project['name'] ?? '').toString();
    final locality = (project['locality'] ?? '').toString();
    final city = (project['city'] ?? '').toString();
    final location = [locality, if (city.isNotEmpty && !locality.contains(city)) city]
        .where((s) => s.isNotEmpty)
        .join(', ');
    final priceLabel = (project['priceLabel'] ?? project['rateSqft'] ?? '').toString();
    final coverUrl = resolveImageUrl(project['coverImageUrl']?.toString());
    final configs = (project['configs'] as List<dynamic>? ?? const [])
        .map((c) => c is Map ? c['bhk'] : null)
        .whereType<num>()
        .map((b) => '${b.toInt()} BHK')
        .toSet()
        .take(3)
        .toList();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 248,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl.isNotEmpty)
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FallbackCover(initial: initial),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _FallbackCover(initial: initial, loading: true);
                    },
                  )
                else
                  _FallbackCover(initial: initial),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.78),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (configs.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: configs
                              .map(
                                (label) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
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
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({
    required this.initial,
    this.loading = false,
  });

  final String initial;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          : Text(
              initial,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
    );
  }
}
