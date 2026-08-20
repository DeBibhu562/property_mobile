import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_session.dart';
import '../core/providers.dart';
import '../features/property/property_models.dart';
import 'smart_suggestions_screen.dart';
import 'widgets/emi_calculator_widget.dart';

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
  bool _loading = true;
  bool _showExploreBanner = true;
  bool _suggestionsPrompted = false;
  List<dynamic> _localities = [];
  List<dynamic> _landmarks = [];
  List<dynamic> _projects = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadPortalMeta();
      _maybeOpenSmartSuggestions();
    });
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
    final searchState = ref.read(searchSelectionProvider);
    final city = searchState.city ?? 'New Delhi';

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/search/portal-meta', queryParameters: {'city': city});
      // API wraps payload under res.data['data']
      final payload = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (mounted) {
        setState(() {
          _localities = (payload['localities'] as List<dynamic>?) ?? [];
          _landmarks = (payload['landmarks'] as List<dynamic>?) ?? [];
          _projects = (payload['projects'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      // Fallback data
      if (mounted) {
        setState(() {
          _localities = [
            {'name': 'Dwarka Mor', 'rateSqft': '₹7.3K/sq.ft.'},
            {'name': 'Chhattarpur', 'rateSqft': '₹6.6K/sq.ft.'},
            {'name': 'Saket', 'rateSqft': '₹15.5K/sq.ft.'},
            {'name': 'Dwarka Sector 12', 'rateSqft': '₹9.2K/sq.ft.'},
          ];
          _landmarks = [
            {'name': 'Dwarka Sector- 10 Metro', 'type': 'METRO'},
            {'name': 'Dwarka Mor Metro Station', 'type': 'METRO'},
            {'name': 'Rithala Metro Station', 'type': 'METRO'},
            {'name': 'Chhattarpur Metro Station', 'type': 'METRO'},
          ];
          _projects = [
            {
              'id': 'proj_1',
              'slug': 'guru-ji-vipin-garden',
              'name': 'Guru Ji Vipin Garden',
              'builder': 'AM Innovation Builder',
              'city': 'New Delhi',
              'locality': 'Dwarka Mor',
              'rateSqft': '₹5.99k/sq.ft.',
              'priceLabel': '₹20.0 L – ₹45.0 L',
              'coverImageUrl':
                  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
              'configs': [
                {'bhk': 1},
                {'bhk': 2},
              ],
            },
            {
              'id': 'proj_2',
              'slug': 's-gambhir-the-palladium',
              'name': 'S Gambhir The Palladium',
              'builder': 'Bandhu Real Estate',
              'city': 'New Delhi',
              'locality': 'Dwarka Mor',
              'rateSqft': '₹7.41k/sq.ft.',
              'priceLabel': '₹50.0 L – ₹81.5 L',
              'coverImageUrl':
                  'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
              'configs': [
                {'bhk': 2},
                {'bhk': 3},
              ],
            },
            {
              'id': 'proj_3',
              'slug': 'eldeco-camelot-dwarka',
              'name': 'Eldeco Camelot',
              'builder': 'Eldeco Group',
              'city': 'New Delhi',
              'locality': 'Dwarka Sector 17',
              'rateSqft': '₹36.55k/sq.ft.',
              'priceLabel': '₹3.40 Cr – ₹11.00 Cr',
              'coverImageUrl':
                  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1600&q=80',
              'configs': [
                {'bhk': 3},
                {'bhk': 4},
              ],
            },
          ];
          _loading = false;
        });
      }
    }
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
    final recentIntentLabel = isRent ? 'Rent homes' : 'Buy homes';

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
              padding: const EdgeInsets.only(bottom: 80), // Space for bottom banner
              children: [
                // Header (Avatar, Welcome, Post Property)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: const [
                          Text('Welcome', style: TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1E293B)),
                        ],
                      ),
                      const Spacer(),
                      // Post Property Button
                      Material(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () => widget.onNavigate('/add-property'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Post Property',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'FREE',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFDB2777)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBoxTab(
                        'Buy',
                        Icons.sell_outlined,
                        category == 'buy',
                        onTap: () => _onCategoryTap('buy'),
                      ),
                      const SizedBox(width: 12),
                      _buildBoxTabWithBadge(
                        'Projects',
                        Icons.business,
                        'NEW',
                        category == 'projects',
                        onTap: () => _onCategoryTap('projects'),
                      ),
                      const SizedBox(width: 12),
                      _buildBoxTab(
                        'Rent',
                        Icons.vpn_key_outlined,
                        category == 'rent',
                        onTap: () => _onCategoryTap('rent'),
                      ),
                      const SizedBox(width: 12),
                      _buildBoxTab(
                        'Commercial',
                        Icons.business_center_outlined,
                        category == 'commercial',
                        onTap: () => _onCategoryTap('commercial'),
                      ),
                      const SizedBox(width: 12),
                      _buildBoxTab(
                        'PG',
                        Icons.group_outlined,
                        category == 'pg',
                        onTap: () => _onCategoryTap('pg'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Searching in ', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                            InkWell(
                              onTap: () {
                                ref.read(searchSelectionProvider.notifier).resetCity();
                              },
                              child: Row(
                                children: [
                                  Text(city, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
                                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1E293B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search Field
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (category == 'projects') {
                                widget.onNavigate('/projects');
                              } else {
                                _openListingsForCategory(category == 'buy' ? 'buy' : category);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      searchHint,
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Recent Searches
                        const Text('Recent searches', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history, size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Dwarka Mor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                      const SizedBox(width: 8),
                                      Text('40+ new', style: TextStyle(fontSize: 12, color: const Color(0xFFDB2777))),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(recentIntentLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Explore options link
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Not sure about locality? ',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      children: const [
                        TextSpan(
                          text: 'Explore options >',
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

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
                            color: Color(0xFF4F46E5),
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
                SizedBox(height: _showExploreBanner ? 88 : 40),
              ],
            ),
          ),
          
          // Bottom Banner
          if (_showExploreBanner)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16, // Above nav bar
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Explore relevant projects in Dwarka Mor,\nNew Delhi',
                          style: TextStyle(color: Color(0xFF1E293B), fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          if (category == 'projects' || category == 'buy') {
                            widget.onNavigate('/projects');
                          } else {
                            _openListingsForCategory(category);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Explore',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => setState(() => _showExploreBanner = false),
                        icon: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 20),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
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

  Widget _buildBoxTab(String title, IconData icon, bool isSelected, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxTabWithBadge(
    String title,
    IconData icon,
    String badgeText,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildBoxTab(title, icon, isSelected, onTap: onTap),
        Positioned(
          top: -8,
          right: -8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
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
