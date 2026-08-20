import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/project/project_models.dart';
import 'detail/detail_sections.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.idOrSlug});

  final String idOrSlug;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _loading = true;
  String? _error;
  ProjectDetail? _project;
  List<ProjectSummary> _similar = const [];
  List<PaymentPlanItem> _plans = const [];
  List<DetailReview> _reviews = const [];
  final _pageController = PageController();
  int _activeImage = 0;
  bool _showStickyHeader = false;
  final _scrollController = ScrollController();

  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
      _error = null;
    });
    try {
      final repo = ref.read(projectRepositoryProvider);
      final detail = await repo.getBySlug(widget.idOrSlug);
      final similar = await repo.similar(detail.slug);
      final plans = detail.paymentPlans.isNotEmpty
          ? detail.paymentPlans.map((e) => PaymentPlanItem.fromJson(e)).toList()
          : await repo.paymentPlans(detail.slug);
      final reviews = await repo.reviews(targetType: 'PROJECT', targetId: detail.id);
      if (!mounted) return;
      setState(() {
        _project = detail;
        _similar = similar;
        _plans = plans;
        _reviews = reviews;
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Failed to load project');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _priceRange(ProjectDetail p) {
    final min = p.minPrice != null ? _inr.format(p.minPrice) : null;
    final max = p.maxPrice != null ? _inr.format(p.maxPrice) : null;
    if (min != null && max != null) return '$min - $max';
    return min ?? max ?? 'Price on request';
  }

  String _fmtCompact(int n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} L';
    return _inr.format(n);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _contact() async {
    _snack('Seller will contact you shortly');
  }

  Future<void> _viewPhone() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seller phone'),
        content: Text('Contact ${_project?.builder ?? 'seller'} via app support for this demo.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Not found'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final p = _project!;
    final images = p.galleryUrls.isNotEmpty
        ? p.galleryUrls
        : [
            if ((p.coverImageUrl ?? '').isNotEmpty) p.coverImageUrl!,
          ];
    final plan = _plans.isNotEmpty ? _plans.first : null;
    final possession = p.possessionDate != null
        ? DateFormat('MMM, yyyy').format(p.possessionDate!)
        : 'On request';

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
                  onFavorite: () => _snack('Saved'),
                  onShare: () => _snack('Share link copied'),
                  onCall: _viewPhone,
                  onFloorPlan: p.floorPlans.isEmpty
                      ? null
                      : () => _snack('Floor plan: ${p.floorPlans.first['name'] ?? 'Available'}'),
                  roomLabel: 'Exterior',
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(p.locationLabel, style: const TextStyle(color: DetailTokens.textSecondary)),
                        const SizedBox(height: 10),
                        Text(_priceRange(p), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        if (p.avgRateSqft > 0)
                          Text(
                            '(₹${(p.avgRateSqft / 1000).toStringAsFixed(1)}K / sq.ft.)',
                            style: const TextStyle(color: DetailTokens.textSecondary, fontSize: 13),
                          ),
                        if (p.bhkLabels.isNotEmpty)
                          Text('(${p.bhkLabels.join(', ')})', style: const TextStyle(color: DetailTokens.textSecondary)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: DetailTokens.indigoLight,
                          child: Text(p.builder.isNotEmpty ? p.builder[0] : 'B', style: const TextStyle(color: DetailTokens.indigo, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Posted by ${p.builder}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const Text('See Agent Profile >', style: TextStyle(fontSize: 12, color: DetailTokens.indigo)),
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
                  const DetailSectionHeader('Payment plan'),
                  if (plan != null)
                    PaymentPlanCard(
                      bhkLabel: plan.configBhk != null ? '${plan.configBhk} BHK' : 'homes',
                      emiLabel: _fmtCompact(plan.emiAmount),
                      durationLabel: '${plan.tenureYears} yrs',
                      interestLabel: '${plan.interestRate}%',
                      onBreakup: () => _snack('Open EMI calculator from Insights / EMI tab'),
                      onContactEmi: _contact,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('EMI details available on request', style: TextStyle(color: DetailTokens.textSecondary)),
                    ),
                  const DetailSectionHeader('Project overview'),
                  OverviewGrid(
                    items: [
                      (icon: Icons.apartment, label: 'Towers', value: '${p.totalTowers ?? '—'}'),
                      (icon: Icons.home_work_outlined, label: 'Project units', value: '${p.totalUnits ?? '—'}'),
                      (icon: Icons.vpn_key_outlined, label: 'Possession starts', value: possession),
                      (icon: Icons.square_foot, label: 'Avg rate', value: p.avgRateSqft > 0 ? '₹${p.avgRateSqft}' : '—'),
                    ],
                  ),
                  const DetailSectionHeader('Key highlights'),
                  HighlightsList(
                    items: p.highlightTitles.isNotEmpty
                        ? p.highlightTitles
                        : [
                            if ((p.highlightsSummary ?? '').isNotEmpty) p.highlightsSummary!,
                            'Home loan assistance available',
                            'Verified project inventory on PropertyDilaDo',
                          ],
                  ),
                  const DetailSectionHeader('RERA ID'),
                  ReraBlock(reraId: p.reraId, onAskMore: _contact),
                  const DetailSectionHeader('Recommended properties'),
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
                          ),
                        )
                        .toList(),
                    onTap: (id) => Navigator.of(context).pushReplacementNamed('/project-detail', arguments: id),
                    onViewPhone: (_) => _viewPhone(),
                  ),
                  const DetailSectionHeader('Compare with similar properties'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(projectRepositoryProvider).addCompare(targetType: 'PROJECT', targetId: p.id);
                        _snack('Added to compare');
                      },
                      icon: const Icon(Icons.compare_arrows, color: DetailTokens.indigo),
                      label: const Text('Add this project to compare', style: TextStyle(color: DetailTokens.indigo)),
                    ),
                  ),
                  if (_similar.isNotEmpty)
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _similar.first.coverImageUrl ?? images.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: DetailTokens.indigoLight),
                        ),
                      ),
                      title: Text(_similar.first.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_similar.first.locationLabel),
                      onTap: () => Navigator.of(context).pushReplacementNamed('/project-detail', arguments: _similar.first.slug),
                    ),
                  const DetailSectionHeader('Explore your neighbourhood'),
                  NeighbourhoodMapCard(
                    categories: const [
                      (icon: Icons.local_hospital_outlined, label: 'Healthcare'),
                      (icon: Icons.directions_transit_outlined, label: 'Commute'),
                      (icon: Icons.restaurant_outlined, label: 'Food and Drinks'),
                      (icon: Icons.shopping_bag_outlined, label: 'Shopping'),
                    ],
                    onExpand: () => _snack('Map expand coming soon'),
                    onCategory: (c) {
                      final match = p.pois.where((x) => (x['category']?.toString() ?? '').toUpperCase().contains(c.split(' ').first.toUpperCase()));
                      _snack(match.isEmpty ? 'No $c POIs yet' : match.map((e) => e['name']).join(', '));
                    },
                  ),
                  if (p.pois.isNotEmpty)
                    ...p.pois.take(4).map(
                          (poi) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: DetailTokens.indigo),
                            title: Text(poi['name']?.toString() ?? ''),
                            subtitle: Text('${poi['category'] ?? ''}${poi['distanceKm'] != null ? ' · ${poi['distanceKm']} km' : ''}'),
                          ),
                        ),
                  const DetailSectionHeader('Check availability & more information'),
                  ContactAvailabilityForm(
                    sellerName: p.builder,
                    options: p.bhkLabels.isNotEmpty ? p.bhkLabels : const ['2 BHK', '3 BHK'],
                    onSubmit: (pref) async {
                      await _contact();
                      _snack('Interest noted for $pref');
                    },
                  ),
                  const DetailSectionHeader('Amenities'),
                  AmenitiesAccordion(
                    amenities: p.amenities
                        .map((a) => (category: a['category'] ?? 'General', name: a['name'] ?? ''))
                        .where((a) => a.name.isNotEmpty)
                        .toList(),
                  ),
                  const DetailSectionHeader('Know about this project'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      p.about ?? p.description ?? 'Premium residential project by ${p.builder}.',
                      style: const TextStyle(color: DetailTokens.textSecondary, height: 1.45),
                    ),
                  ),
                  const DetailSectionHeader('Reviews'),
                  ReviewsSection(
                    items: _reviews
                        .map((r) => (name: r.name, rating: r.rating, body: r.body, title: r.title))
                        .toList(),
                    onWrite: () => _snack('Sign in to write a review'),
                    emptyLabel: 'Be the first to add a review for this project',
                  ),
                  const DetailSectionHeader('Better priced projects'),
                  RecommendedCarousel(
                    items: _similar
                        .skip(1)
                        .take(6)
                        .map(
                          (s) => RecommendedCarouselCard(
                            id: s.slug,
                            title: s.name,
                            subtitle: s.locationLabel,
                            priceLabel: s.minPrice != null ? _fmtCompact(s.minPrice!) : 'Price on request',
                            imageUrl: s.coverImageUrl ?? images.first,
                          ),
                        )
                        .toList(),
                    onTap: (id) => Navigator.of(context).pushReplacementNamed('/project-detail', arguments: id),
                  ),
                  const SizedBox(height: 12),
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
                              Text(_priceRange(p), style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: DetailTokens.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => _snack('Saved'), icon: const Icon(Icons.favorite_border)),
                        IconButton(onPressed: () => _snack('Shared'), icon: const Icon(Icons.ios_share)),
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
        onContact: _contact,
      ),
    );
  }
}
