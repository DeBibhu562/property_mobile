import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/project/project_models.dart';
import '../features/property/property_models.dart';
import 'detail/detail_sections.dart';
import 'property_gallery_screen.dart';

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

  bool _loading = true;
  bool _submitting = false;
  PropertyDetail? _detail;
  ProjectDetail? _project;
  List<PropertyItem> _similar = const [];
  List<PaymentPlanItem> _plans = const [];
  List<DetailReview> _reviews = const [];
  String? _loadError;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 280;
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
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final projectRepo = ref.read(projectRepositoryProvider);
      final d = await propertyRepo.getProperty(widget.propertyId);
      final similar = await propertyRepo.similar(d.id);
      ProjectDetail? project;
      List<PaymentPlanItem> plans = const [];
      if ((d.projectSlug ?? '').isNotEmpty || (d.projectId ?? '').isNotEmpty) {
        try {
          project = await projectRepo.getBySlug(d.projectSlug ?? d.projectId!);
          plans = project.paymentPlans.isNotEmpty
              ? project.paymentPlans.map((e) => PaymentPlanItem.fromJson(e)).toList()
              : await projectRepo.paymentPlans(project.slug);
        } catch (_) {}
      }
      final reviews = await projectRepo.reviews(targetType: 'LISTING', targetId: d.id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _project = project;
        _similar = similar;
        _plans = plans;
        _reviews = reviews;
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _loadError = e.message ?? 'Failed to load property');
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPrice(int price) {
    if (price >= 10000000) return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(1)} L';
    return _currencyFormat.format(price);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitLead([String? pref]) async {
    if (_submitting || _detail == null) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/listings/${_detail!.id}/leads', data: {
        'message': pref == null || pref.isEmpty
            ? 'I am interested in this property. Please call me back.'
            : 'Interested in $pref for ${_detail!.title}. Please call me back.',
      });
      if (!mounted) return;
      _snack('Enquiry sent to seller');
    } catch (_) {
      if (!mounted) return;
      _snack('Could not send enquiry — try again after login');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _viewPhone() async {
    final phone = _detail?.ownerPhone;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seller phone'),
        content: Text(phone != null && phone.isNotEmpty ? phone : 'Phone available after seller approval.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError ?? 'Not found'),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final p = _detail!;
    final project = _project;
    final images = p.images.map((i) => i.url).where((u) => u.isNotEmpty).toList();
    final priceLabel = _formatPrice(p.price);
    final rate = (p.builtUpArea != null && p.builtUpArea! > 0 && p.price > 0)
        ? '₹${(p.price / p.builtUpArea! / 1000).toStringAsFixed(1)}K / sq.ft.'
        : null;
    final plan = _plans.isNotEmpty ? _plans.first : null;
    final highlights = p.highlights.isNotEmpty
        ? p.highlights
        : [
            if (p.bhk > 0) '${p.bhk} BHK ${p.propertySubType ?? 'home'}',
            if (p.builtUpArea != null) '${p.builtUpArea} sq.ft. built-up',
            if (p.isVerified) 'Verified listing',
            'Home loan assistance available',
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
                  onFavorite: () {
                    final favs = ref.read(favoritesProvider.notifier);
                    final set = {...ref.read(favoritesProvider)};
                    if (set.contains(p.id)) {
                      set.remove(p.id);
                    } else {
                      set.add(p.id);
                    }
                    favs.state = set;
                    _snack(set.contains(p.id) ? 'Saved' : 'Removed from saved');
                  },
                  onShare: () => _snack('Share link copied'),
                  onCall: _viewPhone,
                  onFloorPlan: project?.floorPlans.isNotEmpty == true
                      ? () => _snack('Floor plan available for linked project')
                      : null,
                  roomLabel: p.images.isNotEmpty ? (p.images[_activePage.clamp(0, p.images.length - 1)].section ?? 'Photo') : null,
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          [p.locality, p.city].where((s) => s.isNotEmpty).join(', '),
                          style: const TextStyle(color: DetailTokens.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(priceLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        if (rate != null)
                          Text('($rate)', style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13)),
                        Text(
                          p.bhk > 0
                              ? '(${p.bhk} BHK ${p.propertySubType ?? p.listingType ?? ''})'
                              : '(${p.propertySubType ?? p.listingType ?? 'Property'})',
                          style: const TextStyle(color: DetailTokens.textSecondary),
                        ),
                        if (project != null)
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/project-detail', arguments: project.slug),
                            child: Text('View project: ${project.name} >'),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: DetailTokens.indigoLight,
                          child: Text(
                            p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : 'S',
                            style: const TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Posted by ${p.agencyName ?? p.ownerName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(p.ownerRole ?? 'Seller', style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _viewPhone,
                          style: ElevatedButton.styleFrom(backgroundColor: DetailTokens.indigo, foregroundColor: Colors.white, elevation: 0),
                          child: const Text('View phone'),
                        ),
                      ],
                    ),
                  ),
                  if (plan != null) ...[
                    const DetailSectionHeader('Payment plan'),
                    PaymentPlanCard(
                      bhkLabel: plan.configBhk != null ? '${plan.configBhk} BHK' : (p.bhk > 0 ? '${p.bhk} BHK' : 'this home'),
                      emiLabel: _formatPrice(plan.emiAmount),
                      durationLabel: '${plan.tenureYears} yrs',
                      interestLabel: '${plan.interestRate}%',
                      onBreakup: () => _snack('Open EMI calculator from Insights tab'),
                      onContactEmi: () => _submitLead('EMI'),
                    ),
                  ],
                  const DetailSectionHeader('Key highlights'),
                  HighlightsList(items: highlights),
                  const DetailSectionHeader('Property overview'),
                  OverviewGrid(
                    items: [
                      (icon: Icons.king_bed_outlined, label: 'BHK', value: p.bhk > 0 ? '${p.bhk}' : '—'),
                      (icon: Icons.bathtub_outlined, label: 'Bathrooms', value: '${p.bathrooms ?? '—'}'),
                      (icon: Icons.square_foot, label: 'Built-up', value: p.builtUpArea != null ? '${p.builtUpArea} sq.ft.' : '—'),
                      (icon: Icons.local_parking_outlined, label: 'Parking', value: p.parkingCount != null ? '${p.parkingCount}' : '—'),
                      (icon: Icons.chair_outlined, label: 'Furnishing', value: p.furnishingStatus ?? '—'),
                      (icon: Icons.home_outlined, label: 'Ownership', value: p.ownershipType ?? '—'),
                      if (project?.totalTowers != null)
                        (icon: Icons.apartment, label: 'Towers', value: '${project!.totalTowers}'),
                      if (project?.possessionDate != null)
                        (icon: Icons.vpn_key_outlined, label: 'Possession', value: DateFormat('MMM, yyyy').format(project!.possessionDate!)),
                    ],
                  ),
                  if (project != null) ...[
                    const DetailSectionHeader('RERA ID'),
                    ReraBlock(reraId: project.reraId, onAskMore: () => _submitLead()),
                  ],
                  const DetailSectionHeader('Amenities'),
                  AmenitiesAccordion(
                    amenities: [
                      ...p.amenities.map((a) => (category: 'General', name: a)),
                      if (p.waterSupply != null) (category: 'Utilities', name: 'Water: ${p.waterSupply}'),
                      if (p.powerBackup) (category: 'Utilities', name: 'Power Backup'),
                    ],
                  ),
                  const DetailSectionHeader('About this property'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      p.description.isNotEmpty ? p.description : 'No description provided.',
                      style: const TextStyle(color: DetailTokens.textSecondary, height: 1.45),
                    ),
                  ),
                  const DetailSectionHeader('Recommended properties'),
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
                  const DetailSectionHeader('Compare with similar properties'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(projectRepositoryProvider).addCompare(targetType: 'LISTING', targetId: p.id);
                        _snack('Added to compare');
                      },
                      icon: const Icon(Icons.compare_arrows, color: DetailTokens.indigo),
                      label: const Text('Add this listing to compare', style: TextStyle(color: DetailTokens.indigo)),
                    ),
                  ),
                  if (project != null) ...[
                    const DetailSectionHeader('Explore your neighbourhood'),
                    NeighbourhoodMapCard(
                      categories: const [
                        (icon: Icons.local_hospital_outlined, label: 'Healthcare'),
                        (icon: Icons.directions_transit_outlined, label: 'Commute'),
                        (icon: Icons.restaurant_outlined, label: 'Food and Drinks'),
                        (icon: Icons.shopping_bag_outlined, label: 'Shopping'),
                      ],
                      onExpand: () => _snack('Map expand coming soon'),
                    ),
                  ],
                  const DetailSectionHeader('Check availability & more information'),
                  ContactAvailabilityForm(
                    sellerName: p.agencyName ?? p.ownerName,
                    phoneMasked: p.ownerPhone,
                    options: p.bhk > 0 ? ['${p.bhk} BHK', if (p.bhk < 5) '${p.bhk + 1} BHK'] : const ['This unit'],
                    onSubmit: (pref) => _submitLead(pref),
                  ),
                  const DetailSectionHeader('Reviews'),
                  ReviewsSection(
                    items: _reviews
                        .map((r) => (name: r.name, rating: r.rating, body: r.body, title: r.title))
                        .toList(),
                    onWrite: () => _snack('Sign in to write a review'),
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PropertyGalleryScreen(images: p.images)),
                        ),
                        child: const Text('Open full gallery'),
                      ),
                    ),
                  const DisclaimerBlock(),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),
          if (_showStickyHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 2,
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => _snack('Saved'), icon: const Icon(Icons.favorite_border)),
                        Material(
                          color: DetailTokens.indigo,
                          shape: const CircleBorder(),
                          child: IconButton(onPressed: _viewPhone, icon: const Icon(Icons.phone, color: Colors.white, size: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: DetailStickyCtaBar(
        onChat: () => _snack('Opening WhatsApp chat…'),
        onViewPhone: _viewPhone,
        onContact: () => _submitLead(),
      ),
    );
  }
}
