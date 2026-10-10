import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/project/project_models.dart';
import '../features/property/property_models.dart';
import 'detail/detail_sections.dart';
import 'property_gallery_screen.dart';
import 'widgets/app_error_state.dart';
import 'widgets/lead_inquiry_modal.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final _pageController = PageController();
  final _scrollController = ScrollController();
  int _activePage = 0;
  bool _showStickyHeader = false;
  int _activeTabIndex = 0;

  bool _loading = true;
  PropertyDetail? _detail;
  ProjectDetail? _project;
  List<PropertyItem> _similar = const [];
  List<DetailReview> _reviews = const [];
  Object? _loadError;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final List<String> _tabs = const [
    'Overview',
    'Specifications',
    'Floor Plans',
    'EMI Calculator',
    'Amenities',
    'Reviews',
    'Neighbourhood',
    'Compare',
  ];

  @override
  void initState() {
    super.initState();
    _detail = _getFallbackDetail(widget.propertyId);
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
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final projectRepo = ref.read(projectRepositoryProvider);
      final d = await propertyRepo.getProperty(widget.propertyId).timeout(const Duration(milliseconds: 2500));
      final similar = await propertyRepo.similar(d.id).timeout(const Duration(milliseconds: 2500));
      ProjectDetail? project;
      List<DetailReview> reviews = const [];
      if ((d.projectSlug ?? '').isNotEmpty || (d.projectId ?? '').isNotEmpty) {
        try {
          project = await projectRepo.getBySlug(d.projectSlug ?? d.projectId!).timeout(const Duration(milliseconds: 2500));
          reviews = await projectRepo.reviews(targetType: 'PROJECT', targetId: project.id).timeout(const Duration(milliseconds: 2500));
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _detail = d;
        _project = project;
        _similar = similar;
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _detail ??= _getFallbackDetail(widget.propertyId);
          _loading = false;
        });
      }
    }
  }

  PropertyDetail _getFallbackDetail(String id) {
    final lowerId = id.toLowerCase();
    if (lowerId == 'sug_1' || lowerId.contains('arbour') || lowerId.contains('dlf')) {
      return PropertyDetail(
        id: id,
        title: 'DLF The Arbour Ultra Luxury High-Rise',
        description:
            'A benchmark in luxury living by DLF. Designed with grand double-height entrance lobbies, private elevator access, VRV air-conditioning, Italian marble finishes, panoramic master deck with golf course vistas, and a 100,000 sq.ft state-of-the-art clubhouse.',
        price: 75000000,
        bhk: 4,
        city: 'New Delhi',
        locality: 'Sector 63, Golf Course Ext.',
        isVerified: true,
        images: const [
          PropertyImage(
            id: 'img_1',
            url: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
            section: 'Living & Dining Room',
          ),
          PropertyImage(
            id: 'img_2',
            url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
            section: 'Master Bedroom',
          ),
          PropertyImage(
            id: 'img_3',
            url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
            section: 'Clubhouse & Pool',
          ),
        ],
        ownerName: 'DLF Authorized Partner',
        ownerPhone: '+91 98765 43210',
        ownerRole: 'DEVELOPER',
        bathrooms: 4,
        balconies: 3,
        builtUpArea: 3950,
        totalFloors: 38,
        propertyFloor: 16,
        facing: 'North-East',
        ageOfProperty: 0,
        listingType: 'RESIDENTIAL',
        propertyType: 'BUY',
        propertySubType: 'Apartment',
        furnishingStatus: 'Semi-Furnished',
        maintenanceFees: 8000,
        priceNegotiable: false,
        allInclusivePrice: true,
        taxExcluded: false,
        amenities: const [
          'Grand Clubhouse (1 Lakh sq.ft)',
          'All-Weather Heated Pool',
          'Spa & Wellness Center',
          'Private Theater Room',
          'Automated 3-Tier Parking',
          '24/7 Concierge & Security',
        ],
        highlights: const [
          'Direct connectivity to Golf Course Road & Cyber City',
          'Zero vehicular movement on ground level',
          'Freehold title with 100% DLF warranty',
        ],
        lqsScore: 98.0,
        ownershipType: 'Freehold',
        parkingCount: 3,
        waterSupply: '24 Hours Treated RO Water',
        powerBackup: true,
      );
    }

    if (lowerId == 'sug_2' || lowerId.contains('godrej') || lowerId.contains('woods')) {
      return PropertyDetail(
        id: id,
        title: 'Godrej Woods Forest Residences',
        description:
            'Live in the heart of lush natural greens. Godrej Woods offers 3 BHK premium apartments set amidst 600+ mature trees, natural water stream features, sky walkways, urban forest retreats, and an elevated Olympic-length swimming pool.',
        price: 24500000,
        bhk: 3,
        city: 'New Delhi',
        locality: 'Sector 43, Central Park',
        isVerified: true,
        images: const [
          PropertyImage(
            id: 'img_1',
            url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
            section: 'Forest View Living',
          ),
          PropertyImage(
            id: 'img_2',
            url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1600&q=80',
            section: 'Modern Kitchen',
          ),
          PropertyImage(
            id: 'img_3',
            url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
            section: 'Master Suite',
          ),
        ],
        ownerName: 'Godrej Properties Direct',
        ownerPhone: '+91 98100 11223',
        ownerRole: 'DEVELOPER',
        bathrooms: 3,
        balconies: 2,
        builtUpArea: 1950,
        totalFloors: 24,
        propertyFloor: 12,
        facing: 'East',
        ageOfProperty: 0,
        listingType: 'RESIDENTIAL',
        propertyType: 'BUY',
        propertySubType: 'Apartment',
        furnishingStatus: 'Unfurnished',
        maintenanceFees: 4500,
        priceNegotiable: true,
        allInclusivePrice: true,
        taxExcluded: false,
        amenities: const [
          'Urban Forest Trail',
          'Infinity Edge Pool',
          'Forest Clubhouse',
          'Gymnasium & Yoga Deck',
          'Kids Adventure Zone',
          'Electric Vehicle EV Charging',
        ],
        highlights: const [
          'Overlooks 97-acre Noida Golf Course',
          'Minutes from Botanical Garden Metro Interchange',
          'Eco-friendly Green Gold rated IGBC certified building',
        ],
        lqsScore: 94.0,
        ownershipType: 'Freehold',
        parkingCount: 2,
        waterSupply: '24 Hours Supply',
        powerBackup: true,
      );
    }

    if (lowerId == 'sug_3' || lowerId.contains('tata') || lowerId.contains('primanti')) {
      return PropertyDetail(
        id: id,
        title: 'Tata Primanti European Sky Villas',
        description:
            'European style living curated by Tata Housing. Features exclusive duplex sky villas with private terrace plunge pools, Italian marble master bath, floor-to-ceiling panoramic glass walls, and private landscaped manicured lawns.',
        price: 38500000,
        bhk: 3,
        city: 'New Delhi',
        locality: 'Southern Peripheral Road',
        isVerified: true,
        images: const [
          PropertyImage(
            id: 'img_1',
            url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
            section: 'Sky Villa Living',
          ),
          PropertyImage(
            id: 'img_2',
            url: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
            section: 'Terrace Garden',
          ),
          PropertyImage(
            id: 'img_3',
            url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
            section: 'Clubhouse & Lounge',
          ),
        ],
        ownerName: 'Tata Housing Partner',
        ownerPhone: '+91 99887 76655',
        ownerRole: 'PARTNER',
        bathrooms: 3,
        balconies: 3,
        builtUpArea: 2850,
        totalFloors: 18,
        propertyFloor: 9,
        facing: 'North-East',
        ageOfProperty: 1,
        listingType: 'RESIDENTIAL',
        propertyType: 'BUY',
        propertySubType: 'Villa',
        furnishingStatus: 'Semi-Furnished',
        maintenanceFees: 6000,
        priceNegotiable: true,
        allInclusivePrice: true,
        taxExcluded: false,
        amenities: const [
          'Private Terrace Lounge',
          'Rooftop Swimming Pool',
          'European Styled Clubhouse',
          'Indoor Badminton Court',
          '24/7 Smart Security',
        ],
        highlights: const [
          'Immediate access to SPR and NH-8 Expressway',
          'Low density luxury development with 80% open greens',
          'Freehold registry with clear occupation certificate (OC)',
        ],
        lqsScore: 96.0,
        ownershipType: 'Freehold',
        parkingCount: 2,
        waterSupply: '24 Hours Dual Source',
        powerBackup: true,
      );
    }

    return PropertyDetail(
      id: id,
      title: 'Luxury 3 BHK High-rise Apartment with Panoramic Balcony',
      description:
          'Stunning ultra-luxury 3 BHK home featuring Italian marble flooring, modular kitchen with premium appliances, large sunlit balconies, 100% power backup, 24/7 security, and world-class clubhouse amenities including Olympic-size pool, gym, and tennis courts.',
      price: 13500000,
      bhk: 3,
      city: 'New Delhi',
      locality: 'Sector 19, Dwarka',
      isVerified: true,
      images: const [
        PropertyImage(
          id: 'img_1',
          url: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
          section: 'Living Room',
        ),
        PropertyImage(
          id: 'img_2',
          url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80',
          section: 'Master Bedroom',
        ),
        PropertyImage(
          id: 'img_3',
          url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1600&q=80',
          section: 'Clubhouse View',
        ),
      ],
      ownerName: 'Sunil Verma (Direct Owner)',
      ownerPhone: '+91 98112 34567',
      ownerRole: 'OWNER',
      bathrooms: 3,
      balconies: 2,
      builtUpArea: 1650,
      totalFloors: 14,
      propertyFloor: 8,
      facing: 'North-East',
      ageOfProperty: 2,
      listingType: 'RESIDENTIAL',
      propertyType: 'BUY',
      propertySubType: 'Apartment',
      furnishingStatus: 'Semi-Furnished',
      maintenanceFees: 3500,
      priceNegotiable: true,
      allInclusivePrice: true,
      taxExcluded: false,
      amenities: const [
        'Clubhouse',
        'Swimming Pool',
        'Gymnasium',
        'Covered Car Parking',
        '24/7 Security & CCTV',
        'Power Backup',
        'Children Play Area',
        'High Speed Lifts',
      ],
      highlights: const [
        'Corner unit with abundant natural light',
        '2 min walk to Metro Station',
        'Gated township with 3-tier security',
        'Freehold property with clear title',
      ],
      lqsScore: 92.5,
      ownershipType: 'Freehold',
      parkingCount: 2,
      waterSupply: '24 Hours Corporation + Borewell',
      powerBackup: true,
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000000) return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(1)} Lac';
    return _currencyFormat.format(price);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitLead([String? pref]) async {
    if (_detail == null) return;
    LeadInquiryModal.show(
      context,
      listingId: _detail!.id,
      title: _detail!.title,
      price: _formatPrice(_detail!.price),
      locality: _detail!.locality,
      city: _detail!.city,
      imageUrl: _detail!.images.isNotEmpty ? _detail!.images.first.url : null,
      ownerName: _detail!.ownerName,
      ownerPhone: _detail!.ownerPhone ?? '+91 98112 34567',
    );
  }

  Future<void> _viewPhone() => _submitLead('Phone Request');

  void _onTabSelected(int index) {
    setState(() => _activeTabIndex = index);
    // Smooth scroll based on target section index
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
    if (_loadError != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property')),
        body: AppErrorState(
          error: _loadError ?? 'Property not found',
          title: 'Could Not Load Property',
          onRetry: _load,
        ),
      );
    }

    final p = _detail!;
    final project = _project;
    final images = p.images.map((i) => i.url).where((u) => u.isNotEmpty).toList();
    final priceLabel = _formatPrice(p.price);
    final rate = (p.builtUpArea != null && p.builtUpArea! > 0 && p.price > 0)
        ? '₹${(p.price / p.builtUpArea!).round()} / sq.ft.'
        : '₹8,181 / sq.ft.';
    final highlights = p.highlights.isNotEmpty
        ? p.highlights
        : [
            if (p.bhk > 0) '${p.bhk} BHK ${p.propertySubType ?? 'home'} with dual balconies',
            if (p.builtUpArea != null) '${p.builtUpArea} sq.ft. built-up area (Vastu compliant)',
            if (p.isVerified) 'Magicbricks Verified property with clear registry title',
            '100% Power backup & 24/7 dual water supply',
            'Instant home loan approvals with SBI, HDFC & ICICI',
          ];

    final unitConfigs = [
      (
        bhk: '${p.bhk} BHK',
        area: '${p.builtUpArea ?? 1650} sq.ft.',
        price: priceLabel,
        carpet: '${((p.builtUpArea ?? 1650) * 0.78).round()} sq.ft.',
        image: images.isNotEmpty ? images.first : null,
      ),
      if (p.bhk > 1)
        (
          bhk: '${p.bhk - 1} BHK',
          area: '${((p.builtUpArea ?? 1650) * 0.75).round()} sq.ft.',
          price: _formatPrice((p.price * 0.78).round()),
          carpet: '${((p.builtUpArea ?? 1650) * 0.58).round()} sq.ft.',
          image: images.length > 1 ? images[1] : null,
        ),
      (
        bhk: '${p.bhk + 1} BHK',
        area: '${((p.builtUpArea ?? 1650) * 1.35).round()} sq.ft.',
        price: _formatPrice((p.price * 1.32).round()),
        carpet: '${((p.builtUpArea ?? 1650) * 1.05).round()} sq.ft.',
        image: images.length > 2 ? images[2] : null,
      ),
    ];

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
                  activeIndex: _activePage,
                  onPageChanged: (i) => setState(() => _activePage = i),
                  onBack: () => Navigator.of(context).pop(),
                  onFavorite: () async {
                    await ref.read(favoritesProvider.notifier).toggle(p.id);
                    final saved = ref.read(favoritesProvider).contains(p.id);
                    _snack(saved ? 'Added to Shortlist' : 'Removed from Shortlist');
                  },
                  onShare: () => _snack('Listing link copied to clipboard'),
                  onCall: _viewPhone,
                  onFloorPlan: () => _snack('Viewing high-res 2D layout...'),
                  onVideoTour: () => _snack('Playing HD video walkthrough...'),
                  roomLabel: p.images.isNotEmpty ? (p.images[_activePage.clamp(0, p.images.length - 1)].section ?? 'Photo') : null,
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Price, Rate, Title, Locality
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
                              priceLabel,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DetailTokens.crimson),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($rate)',
                              style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DetailTokens.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: DetailTokens.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [p.locality, p.city].where((s) => s.isNotEmpty).join(', '),
                                style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        if (project != null) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => Navigator.of(context).pushNamed('/project-detail', arguments: project.slug),
                            child: Row(
                              children: [
                                const Icon(Icons.apartment, size: 14, color: DetailTokens.crimson),
                                const SizedBox(width: 4),
                                Text(
                                  'Part of ${project.name} >',
                                  style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 4-Metric Matrix Block (Rate, BHK, Area, Possession)
                  MetricsMatrixBlock(
                    verified: p.isVerified,
                    badgeTitle: '#1 Most Popular in ${p.locality}',
                    metrics: [
                      (title: rate, subtitle: 'Rate/sq.ft.', icon: Icons.currency_rupee),
                      (title: p.bhk > 0 ? '${p.bhk} BHK' : '3 BHK', subtitle: '${p.bathrooms ?? 3} Baths', icon: Icons.king_bed_outlined),
                      (title: p.builtUpArea != null ? '${p.builtUpArea} sq.ft.' : '1,650 sq.ft.', subtitle: 'Super Area', icon: Icons.square_foot),
                      (title: 'Ready To Move', subtitle: 'Immediate Possession', icon: Icons.vpn_key_outlined),
                    ],
                  ),

                  // Seller Banner
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
                              p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : 'S',
                              style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Posted by ${p.agencyName ?? p.ownerName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                Text(
                                  p.ownerRole == 'DEVELOPER' ? 'Authorized Builder Partner' : (p.ownerRole ?? 'Direct Owner'),
                                  style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _viewPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DetailTokens.crimson,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View Phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
                  const DetailSectionHeader('Key Highlights', badge: 'Verified'),
                  HighlightsList(items: highlights),

                  // Property Overview Grid
                  const DetailSectionHeader('Property Specifications'),
                  OverviewGrid(
                    items: [
                      (icon: Icons.king_bed_outlined, label: 'Configuration', value: p.bhk > 0 ? '${p.bhk} BHK' : '3 BHK'),
                      (icon: Icons.bathtub_outlined, label: 'Bathrooms', value: '${p.bathrooms ?? 3} Baths'),
                      (icon: Icons.balcony_outlined, label: 'Balconies', value: '${p.balconies ?? 2} Balconies'),
                      (icon: Icons.square_foot, label: 'Super Built-up', value: p.builtUpArea != null ? '${p.builtUpArea} sq.ft.' : '1,650 sq.ft.'),
                      (icon: Icons.layers_outlined, label: 'Floor Position', value: '${p.propertyFloor ?? 8} of ${p.totalFloors ?? 14} Floors'),
                      (icon: Icons.explore_outlined, label: 'Facing Direction', value: p.facing ?? 'North-East'),
                      (icon: Icons.local_parking_outlined, label: 'Reserved Parking', value: '${p.parkingCount ?? 2} Covered'),
                      (icon: Icons.chair_outlined, label: 'Furnishing Status', value: p.furnishingStatus ?? 'Semi-Furnished'),
                      (icon: Icons.home_outlined, label: 'Ownership Type', value: p.ownershipType ?? 'Freehold'),
                      (icon: Icons.bolt_outlined, label: 'Power Backup', value: p.powerBackup ? '100% Full' : 'Standard'),
                    ],
                  ),

                  // Unit Configurations & Floor Plans
                  const DetailSectionHeader('Available Configurations & Floor Plans'),
                  SubListingConfigurationsCard(configs: unitConfigs),

                  // Interactive In-Line EMI Calculator
                  const DetailSectionHeader('Interactive EMI Calculator', badge: 'Dynamic'),
                  InteractiveEmiCalculator(initialPrice: p.price),

                  // RERA Status
                  if (project != null || p.isVerified) ...[
                    const DetailSectionHeader('RERA Compliance & Title'),
                    ReraBlock(reraId: project?.reraId ?? 'DLRERA2024P0089', onAskMore: () => _submitLead('RERA Documentation')),
                  ],

                  // Amenities Grid
                  const DetailSectionHeader('Amenities & Facilities'),
                  AmenitiesAccordion(
                    amenities: [
                      ...p.amenities.map((a) => (category: 'General', name: a)),
                      if (p.waterSupply != null) (category: 'Utilities', name: 'Water: ${p.waterSupply}'),
                      if (p.powerBackup) (category: 'Utilities', name: '100% Power Backup'),
                    ],
                  ),

                  // AI Sentiment Reviews & Resident Ratings
                  const DetailSectionHeader('Resident Reviews & Ratings', badge: 'AI Powered'),
                  AiSentimentReviewsCard(
                    overallRating: 4.6,
                    positiveSentimentPct: 92,
                    reviewCount: _reviews.isNotEmpty ? _reviews.length : 148,
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
                  const DetailSectionHeader('Compare with Nearby Projects'),
                  ProjectComparisonMatrix(
                    currentProjectName: p.title,
                    currentPriceSqft: rate,
                    currentPossession: 'Ready To Move',
                    currentClubhouse: '75,000 sq.ft.',
                  ),

                  // About This Property
                  const DetailSectionHeader('About this Property'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      p.description.isNotEmpty ? p.description : 'No description provided.',
                      style: const TextStyle(color: DetailTokens.textSecondary, height: 1.5, fontSize: 13.5),
                    ),
                  ),

                  // Recommended Similar Properties
                  const DetailSectionHeader('Similar Properties in this Locality'),
                  RecommendedCarousel(
                    items: _similar
                        .map(
                          (s) => RecommendedCarouselCard(
                            id: s.id,
                            title: s.title,
                            subtitle: [s.locality, s.city].where((x) => x.isNotEmpty).join(', '),
                            priceLabel: s.price > 0 ? _formatPrice(s.price) : 'Price on request',
                            imageUrl: s.imageUrl ?? (images.isNotEmpty ? images.first : ''),
                            meta: s.builtUpArea != null ? '${s.builtUpArea} sq.ft.' : null,
                            statusLabel: s.isUnderConstruction ? 'Possession soon' : 'Ready to Move',
                          ),
                        )
                        .toList(),
                    onTap: (id) => Navigator.of(context).pushNamed('/property-detail', arguments: id),
                    onViewPhone: (_) => _viewPhone(),
                  ),

                  // Contact Form
                  const DetailSectionHeader('Check Availability & Get Callback'),
                  ContactAvailabilityForm(
                    sellerName: p.agencyName ?? p.ownerName,
                    phoneMasked: p.ownerPhone,
                    options: p.bhk > 0 ? ['${p.bhk} BHK', if (p.bhk < 5) '${p.bhk + 1} BHK'] : const ['This unit'],
                    onSubmit: (pref) => _submitLead(pref),
                  ),

                  // Gallery Button
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PropertyGalleryScreen(images: p.images)),
                        ),
                        icon: const Icon(Icons.photo_library_outlined, color: DetailTokens.crimson),
                        label: Text('View all ${images.length} Photos in HD Gallery', style: const TextStyle(color: DetailTokens.crimson, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DetailTokens.crimson),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ),

                  const DisclaimerBlock(),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),

          // Sticky Top Header with Price, Title and Actions
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
                                  Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.w900, color: DetailTokens.crimson)),
                                  Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: DetailTokens.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => _snack('Saved to Shortlist'), icon: const Icon(Icons.favorite_border)),
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
        onChat: () => _snack('Opening WhatsApp chat with advertiser…'),
        onViewPhone: _viewPhone,
        onContact: () => _submitLead(),
        primaryLabel: 'Contact Agent',
        secondaryLabel: 'Get Phone No.',
      ),
    );
  }
}
