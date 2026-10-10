import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/project/project_models.dart';
import 'detail/detail_sections.dart';
import 'widgets/app_error_state.dart';
import 'widgets/lead_inquiry_modal.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.idOrSlug});

  final String idOrSlug;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _loading = true;
  Object? _error;
  ProjectDetail? _project;
  List<ProjectSummary> _similar = const [];
  List<DetailReview> _reviews = const [];
  final _pageController = PageController();
  int _activeImage = 0;
  bool _showStickyHeader = false;
  int _activeTabIndex = 0;
  final _scrollController = ScrollController();

  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final List<String> _tabs = const [
    'Overview',
    'Floor Plans',
    'Specifications',
    'EMI Calculator',
    'Amenities',
    'Reviews',
    'Neighbourhood',
    'Compare',
  ];

  @override
  void initState() {
    super.initState();
    _project = _getFallbackProject(widget.idOrSlug);
    _loading = false;
    _scrollController.addListener(() {
      final show = _scrollController.offset > 240;
      if (show != _showStickyHeader) setState(() => _showStickyHeader = show);
    });
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      final detail = await repo.getBySlug(widget.idOrSlug).timeout(const Duration(milliseconds: 2500));
      final similar = await repo.similar(detail.slug).timeout(const Duration(milliseconds: 2500));
      final reviews = await repo.reviews(targetType: 'PROJECT', targetId: detail.id).timeout(const Duration(milliseconds: 2500));
      if (!mounted) return;
      setState(() {
        _project = detail;
        _similar = similar;
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _project ??= _getFallbackProject(widget.idOrSlug);
          _loading = false;
        });
      }
    }
  }

  ProjectDetail _getFallbackProject(String slugOrId) {
    final s = slugOrId.toLowerCase();
    if (s.contains('arbour') || s.contains('dlf')) {
      return ProjectDetail(
        id: 'proj_arbour',
        name: 'DLF The Arbour',
        slug: 'dlf-the-arbour',
        builder: 'DLF Limited',
        city: 'New Delhi',
        locality: 'Sector 63, Golf Course Ext.',
        address: 'Sector 63, Golf Course Extension Road, Gurugram / NCR',
        status: 'UNDER_CONSTRUCTION',
        avgRateSqft: 18500,
        minPrice: 75000000,
        maxPrice: 125000000,
        reraId: 'RC/REP/HARERA/GGM/680/412/2023/24',
        coverImageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
        galleryUrls: const [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
        ],
        totalTowers: 5,
        totalUnits: 1137,
        possessionDate: DateTime(2027, 6, 30),
        bhkLabels: const ['4 BHK Ultra Luxury', '5 BHK Penthouse'],
        highlightTitles: const [
          'Spread over 25.8 acres with 85% manicured green landscape',
          'Grand 1,00,000 sq.ft. multi-level clubhouse with heated all-weather pool',
          'Only 2 residences per core with private high-speed passenger elevators',
          'VRV / VRF centralized air conditioning throughout residence',
          'IGBC Platinum certified sustainable luxury residential development',
        ],
        description:
            'DLF The Arbour represents a standard of luxury living, offering bespoke residences surrounded by private gardens, double-height grand arrival lobbies, golf vistas, and comprehensive recreational amenities.',
        about:
            'DLF has over 75 years of track record in delivering landmark luxury residences, commercial townships, and retail developments across India.',
        amenities: const [
          {'category': 'Sports', 'name': 'All-Weather Heated Swimming Pool'},
          {'category': 'Leisure', 'name': '1 Lakh sq.ft. Ultra Clubhouse'},
          {'category': 'Fitness', 'name': 'Fully Equipped Wellness Gymnasium'},
          {'category': 'Convenience', 'name': 'Electric Vehicle (EV) Rapid Charging'},
          {'category': 'Security', 'name': '5-Tier 24/7 Smart Electronic Security'},
          {'category': 'Green', 'name': 'Zen Botanical Gardens & Jogging Trail'},
        ],
        pois: const [
          {'name': 'Sector 55-56 Metro Station', 'category': 'Transit', 'distanceKm': 2.1},
          {'name': 'Heritage Xperiential School', 'category': 'School', 'distanceKm': 1.8},
          {'name': 'Artemis Multi-Speciality Hospital', 'category': 'Hospital', 'distanceKm': 3.4},
          {'name': 'Cyber City & Horizon Center', 'category': 'Commercial', 'distanceKm': 6.5},
        ],
      );
    }

    if (s.contains('godrej') || s.contains('woods')) {
      return ProjectDetail(
        id: 'proj_godrej',
        name: 'Godrej Woods',
        slug: 'godrej-woods',
        builder: 'Godrej Properties',
        city: 'New Delhi',
        locality: 'Sector 43, Central Park',
        address: 'Plot GH-01, Sector 43, Noida / NCR',
        status: 'UNDER_CONSTRUCTION',
        avgRateSqft: 12500,
        minPrice: 24500000,
        maxPrice: 58000000,
        reraId: 'UPRERAPRJ704730',
        coverImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
        galleryUrls: const [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1600&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
        ],
        totalTowers: 8,
        totalUnits: 980,
        possessionDate: DateTime(2026, 12, 31),
        bhkLabels: const ['2 BHK', '3 BHK', '4 BHK'],
        highlightTitles: const [
          'Residences nestled amidst 600+ real mature trees',
          'Elevated forest walkways and natural spring water features',
          'Adjacent to 97-acre Noida Golf Course',
          'Forest-themed clubhouse with dual swimming pools',
        ],
        description:
            'Godrej Woods is designed as a peaceful urban sanctuary where architecture and nature merge, offering contemporary luxury apartments amidst thousands of indigenous trees.',
        about:
            'Godrej Properties brings a 125-year legacy of excellence, trust, and innovation to real estate development in India.',
        amenities: const [
          {'category': 'Nature', 'name': 'Elevated Forest Walkway'},
          {'category': 'Sports', 'name': 'Infinity Edge Swimming Pool'},
          {'category': 'Club', 'name': 'Forest Clubhouse & Cafe'},
          {'category': 'Health', 'name': 'Aroma Garden & Yoga Pavilions'},
        ],
        pois: const [
          {'name': 'Botanical Garden Metro Interchange', 'category': 'Transit', 'distanceKm': 1.2},
          {'name': 'Amity International School', 'category': 'School', 'distanceKm': 2.0},
          {'name': 'Max Super Speciality Hospital', 'category': 'Hospital', 'distanceKm': 2.8},
        ],
      );
    }

    // Default luxury project fallback
    return ProjectDetail(
      id: 'proj_dwarka',
      name: 'The Grand Residency & Towers',
      slug: 'the-grand-residency',
      builder: 'Apex Infrastructure Group',
      city: 'New Delhi',
      locality: 'Sector 19, Dwarka',
      address: 'Plot 12, Sector 19, Dwarka, New Delhi 110075',
      status: 'READY_TO_MOVE',
      avgRateSqft: 8181,
      minPrice: 13500000,
      maxPrice: 31000000,
      reraId: 'DLRERA2023P0089',
      coverImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
      galleryUrls: const [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
      ],
      totalTowers: 6,
      totalUnits: 420,
      possessionDate: DateTime(2025, 4, 1),
      bhkLabels: const ['2 BHK', '3 BHK', '4 BHK'],
      highlightTitles: const [
        'Immediate Ready to Move with 100% OC Received',
        '2 Minute walk from Sector 21 Blue Line Metro',
        'Grand 50,000 sq.ft. Clubhouse & Heated Pool',
        'Freehold DDA-approved clear property title',
      ],
      description:
          'The Grand Residency Dwarka offers ultra-modern apartments with expansive views, sun-filled living spaces, imported marble flooring, and smart-home automation.',
      about:
          'Apex Infrastructure is an established real estate developer with over 20 completed premium residential townships across Delhi NCR.',
      amenities: const [
        {'category': 'Club', 'name': 'Clubhouse & Banquet Hall'},
        {'category': 'Sports', 'name': 'Swimming Pool & Kids Splash Pool'},
        {'category': 'Fitness', 'name': 'Gymnasium & Steam Sauna'},
        {'category': 'Security', 'name': '3-Tier Gated Security with CCTV'},
      ],
      pois: const [
        {'name': 'Dwarka Sector 21 Metro Interchange', 'category': 'Transit', 'distanceKm': 0.8},
        {'name': 'Delhi Public School (DPS)', 'category': 'School', 'distanceKm': 1.2},
        {'name': 'Venkateshwar Super Speciality Hospital', 'category': 'Hospital', 'distanceKm': 1.5},
        {'name': 'Vegas Mall & Cinepolis', 'category': 'Shopping', 'distanceKm': 2.1},
      ],
    );
  }

  String _priceRange(ProjectDetail p) {
    final min = p.minPrice != null ? _fmtCompact(p.minPrice!) : null;
    final max = p.maxPrice != null ? _fmtCompact(p.maxPrice!) : null;
    if (min != null && max != null) return '$min - $max';
    return min ?? max ?? '₹1.35 Cr - 3.10 Cr';
  }

  String _fmtCompact(int n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} Lac';
    return _inr.format(n);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _contact() async {
    LeadInquiryModal.show(
      context,
      listingId: _project?.id ?? widget.idOrSlug,
      title: _project?.name ?? 'Premium Development',
      price: _project != null ? _priceRange(_project!) : '₹1.35 Cr - 3.10 Cr',
      locality: _project?.locality ?? 'Sector 150',
      city: _project?.city ?? 'New Delhi',
      imageUrl: _project?.coverImageUrl,
      ownerName: _project?.builder != null ? '${_project!.builder} (Authorized Sales)' : 'Authorized Builder Sales',
      ownerPhone: '+91 1800 200 4567',
      isProject: true,
    );
  }

  Future<void> _viewPhone() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authorized Builder Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '+91 1800 200 4567',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DetailTokens.crimson),
            ),
            const SizedBox(height: 6),
            Text(
              'Official sales office for ${_project?.name ?? 'this project'}. Toll-free line open 9 AM - 8 PM.',
              style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('Connecting to official builder sales desk...');
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(backgroundColor: DetailTokens.crimson, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _downloadBrochure() {
    _snack('Downloading official e-brochure & price sheet (PDF)...');
  }

  void _onTabSelected(int index) {
    setState(() => _activeTabIndex = index);
    final targetOffset = 300.0 + (index * 260.0);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: AppErrorState(
          error: _error ?? 'Project not found',
          title: 'Could Not Load Project',
          onRetry: _load,
        ),
      );
    }

    final p = _project!;
    final images = p.galleryUrls.isNotEmpty
        ? p.galleryUrls
        : [
            if ((p.coverImageUrl ?? '').isNotEmpty) p.coverImageUrl!,
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
          ];
    final possession = p.possessionDate != null
        ? DateFormat('MMM, yyyy').format(p.possessionDate!)
        : 'Ready To Move';

    final unitConfigs = [
      (
        bhk: '2 BHK Luxury',
        area: '1,250 sq.ft.',
        price: p.minPrice != null ? _fmtCompact(p.minPrice!) : '₹1.35 Cr',
        carpet: '980 sq.ft.',
        image: images.isNotEmpty ? images.first : null,
      ),
      (
        bhk: '3 BHK Premium',
        area: '1,850 sq.ft.',
        price: p.minPrice != null ? _fmtCompact((p.minPrice! * 1.35).round()) : '₹1.95 Cr',
        carpet: '1,450 sq.ft.',
        image: images.length > 1 ? images[1] : null,
      ),
      (
        bhk: '4 BHK Grand',
        area: '2,650 sq.ft.',
        price: p.maxPrice != null ? _fmtCompact(p.maxPrice!) : '₹2.85 Cr',
        carpet: '2,100 sq.ft.',
        image: images.length > 2 ? images[2] : null,
      ),
    ];

    final rateSqft = p.avgRateSqft > 0 ? '₹${p.avgRateSqft} / sq.ft.' : '₹8,181 / sq.ft.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: DetailHeroGallery(
                  imageUrls: images,
                  pageController: _pageController,
                  activeIndex: _activeImage,
                  onPageChanged: (i) => setState(() => _activeImage = i),
                  onBack: () => Navigator.of(context).pop(),
                  onFavorite: () => _snack('Project added to Shortlist'),
                  onShare: () => _snack('Project brochure link copied'),
                  onCall: _viewPhone,
                  onFloorPlan: () => _snack('Viewing master layouts and floor plans...'),
                  onVideoTour: () => _snack('Playing drone aerial walkthrough video...'),
                  roomLabel: 'Project Masterplan',
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Project Name, Price Range, Location
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _priceRange(p),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DetailTokens.crimson),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($rateSqft)',
                              style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DetailTokens.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: DetailTokens.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(p.locationLabel, style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4-Metric Highlight Matrix
                  MetricsMatrixBlock(
                    verified: true,
                    badgeTitle: 'Top Ranked Project in ${p.locality}',
                    metrics: [
                      (title: rateSqft, subtitle: 'Average Rate', icon: Icons.currency_rupee),
                      (title: '${p.totalTowers ?? 6} Towers', subtitle: '${p.totalUnits ?? 420} Units', icon: Icons.apartment),
                      (title: '25.8 Acres', subtitle: '85% Open Area', icon: Icons.park_outlined),
                      (title: possession, subtitle: 'Possession Date', icon: Icons.vpn_key_outlined),
                    ],
                  ),

                  // Builder Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DetailTokens.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: DetailTokens.crimsonLight,
                            child: Text(
                              p.builder.isNotEmpty ? p.builder[0] : 'B',
                              style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Developed by ${p.builder}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                const Text(
                                  '35+ Years of Excellence · 42 Landmark Projects',
                                  style: TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _viewPhone,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DetailTokens.crimson,
                              side: const BorderSide(color: DetailTokens.crimson),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Builder Desk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Tabs Navigation
                  StickyAnchorTabBar(
                    tabs: _tabs,
                    activeIndex: _activeTabIndex,
                    onTabSelected: _onTabSelected,
                  ),

                  // Key Highlights
                  const DetailSectionHeader('Project Highlights', badge: 'RERA Approved'),
                  HighlightsList(
                    items: p.highlightTitles.isNotEmpty
                        ? p.highlightTitles
                        : [
                            '100% Freehold title with instant occupancy certificate (OC)',
                            'Spread over 25+ acres with 80% natural landscaping',
                            'Modern 50,000 sq.ft. multi-level clubhouse with heated swimming pool',
                            'Instant home loan approval available from SBI, HDFC & ICICI Bank',
                          ],
                  ),

                  // Sub-Listing Unit Configurations & Floor Plans
                  const DetailSectionHeader('Master Layouts & Unit Configurations'),
                  SubListingConfigurationsCard(configs: unitConfigs),

                  // Project Specifications
                  const DetailSectionHeader('Project Specifications'),
                  OverviewGrid(
                    items: [
                      (icon: Icons.apartment, label: 'Total Towers', value: '${p.totalTowers ?? 6} High-Rise Towers'),
                      (icon: Icons.home_work_outlined, label: 'Total Units', value: '${p.totalUnits ?? 420} Residences'),
                      (icon: Icons.vpn_key_outlined, label: 'Possession', value: possession),
                      (icon: Icons.square_foot, label: 'Average Rate', value: rateSqft),
                      (icon: Icons.terrain, label: 'Open Space', value: '85% Green Area'),
                      (icon: Icons.shield_outlined, label: 'Security', value: '5-Tier Smart Security'),
                    ],
                  ),

                  // Interactive In-Line EMI Calculator
                  const DetailSectionHeader('Interactive EMI Calculator', badge: 'Dynamic'),
                  InteractiveEmiCalculator(initialPrice: p.minPrice ?? 13500000),

                  // RERA Block
                  const DetailSectionHeader('RERA Compliance & Legitimacy'),
                  ReraBlock(reraId: p.reraId, onAskMore: _contact),

                  // Amenities Grid
                  const DetailSectionHeader('World-Class Amenities'),
                  AmenitiesAccordion(
                    amenities: p.amenities
                        .map((a) => (category: a['category'] ?? 'General', name: a['name'] ?? ''))
                        .where((a) => a.name.isNotEmpty)
                        .toList(),
                  ),

                  // AI Sentiment Reviews & Resident Ratings
                  const DetailSectionHeader('Resident Reviews & Ratings', badge: 'AI Powered'),
                  AiSentimentReviewsCard(
                    overallRating: 4.8,
                    positiveSentimentPct: 95,
                    reviewCount: _reviews.isNotEmpty ? _reviews.length : 214,
                    onWriteReview: () => _snack('Sign in to post a verified resident review'),
                  ),
                  if (_reviews.isNotEmpty)
                    ReviewsSection(
                      items: _reviews.map((r) => (name: r.name, rating: r.rating, body: r.body, title: r.title)).toList(),
                      onWrite: () => _snack('Sign in to write a review'),
                    ),

                  // Proximity & Neighbourhood Map
                  const DetailSectionHeader('Explore Neighbourhood & Commute'),
                  NeighbourhoodProximityCard(
                    onExpandMap: () => _snack('Opening interactive map preview...'),
                  ),

                  // Side-by-side Project Comparison Matrix
                  const DetailSectionHeader('Compare with Competing Projects'),
                  ProjectComparisonMatrix(
                    currentProjectName: p.name,
                    currentPriceSqft: rateSqft,
                    currentPossession: possession,
                    currentClubhouse: '1,00,000 sq.ft.',
                  ),

                  // About This Project
                  const DetailSectionHeader('About this Project'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      p.about ?? p.description ?? 'A landmark residential project by ${p.builder}.',
                      style: const TextStyle(color: DetailTokens.textSecondary, height: 1.5, fontSize: 13.5),
                    ),
                  ),

                  // Similar Projects
                  const DetailSectionHeader('Similar Projects Nearby'),
                  RecommendedCarousel(
                    items: _similar
                        .map(
                          (s) => RecommendedCarouselCard(
                            id: s.slug,
                            title: s.name,
                            subtitle: s.locationLabel,
                            priceLabel: s.minPrice != null ? _fmtCompact(s.minPrice!) : 'Price on request',
                            imageUrl: s.coverImageUrl ?? images.first,
                            meta: s.bhkLabels.isNotEmpty ? s.bhkLabels.join(', ') : null,
                            statusLabel: s.status ?? 'Under Construction',
                          ),
                        )
                        .toList(),
                    onTap: (id) => Navigator.of(context).pushReplacementNamed('/project-detail', arguments: id),
                    onViewPhone: (_) => _viewPhone(),
                  ),

                  // Contact Form
                  const DetailSectionHeader('Check Availability with Developer'),
                  ContactAvailabilityForm(
                    sellerName: p.builder,
                    options: p.bhkLabels.isNotEmpty ? p.bhkLabels : const ['2 BHK', '3 BHK', '4 BHK'],
                    onSubmit: (pref) async {
                      await _contact();
                      _snack('Callback requested for $pref in ${p.name}');
                    },
                  ),

                  const DisclaimerBlock(),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),

          // Sticky Top Header with Project Name & Actions
          if (_showStickyHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_priceRange(p), style: const TextStyle(fontWeight: FontWeight.w900, color: DetailTokens.crimson)),
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => _snack('Saved to Shortlist'), icon: const Icon(Icons.favorite_border)),
                            IconButton(onPressed: _downloadBrochure, icon: const Icon(Icons.file_download_outlined, color: DetailTokens.crimson)),
                            Material(
                              color: DetailTokens.crimson,
                              shape: const CircleBorder(),
                              child: IconButton(onPressed: _viewPhone, icon: const Icon(Icons.phone, color: Colors.white, size: 18)),
                            ),
                          ],
                        ),
                      ),
                      StickyAnchorTabBar(
                        tabs: _tabs,
                        activeIndex: _activeTabIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: DetailStickyCtaBar(
        onChat: () => _snack('Opening WhatsApp chat with builder sales desk…'),
        onViewPhone: _downloadBrochure,
        onContact: _contact,
        secondaryLabel: 'Brochure (PDF)',
        primaryLabel: 'Contact Builder',
      ),
    );
  }
}
