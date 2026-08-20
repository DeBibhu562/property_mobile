import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../features/property/property_models.dart';

/// Buyer Suggestion — curated projects + recommended listings for the
/// selected city (not the empty generic task dashboard).
class BuyerSuggestionScreen extends ConsumerStatefulWidget {
  const BuyerSuggestionScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<BuyerSuggestionScreen> createState() => _BuyerSuggestionScreenState();
}

class _BuyerSuggestionScreenState extends ConsumerState<BuyerSuggestionScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _projects = const [];
  List<PropertyItem> _listings = const [];
  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final city = ref.read(searchSelectionProvider).city ?? 'New Delhi';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final propertyRepo = ref.read(propertyRepositoryProvider);

      final metaFut = dio.get('/search/portal-meta', queryParameters: {'city': city});
      final listFut = propertyRepo.searchProperties(
        offset: 0,
        limit: 8,
        city: city,
        sortBy: 'relevance',
      );

      final metaRes = await metaFut;
      final page = await listFut;
      final payload = metaRes.data is Map ? (metaRes.data['data'] ?? metaRes.data) : metaRes.data;
      final projects = ((payload['projects'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _listings = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load suggestions.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(searchSelectionProvider).city ?? 'New Delhi';
    final intent = ref.watch(searchSelectionProvider).intent;
    final intentLabel = intent == 'RENT' ? 'rent' : 'buy';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              title: const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Looking to $intentLabel · $city',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Picked for you in $city',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Projects and listings matched to your search city',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Featured projects',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate('/projects'),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_projects.isEmpty)
                      const _SoftEmpty(text: 'No projects for this city yet. Try another city from Search.')
                    else
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _projects.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final p = _projects[i];
                            final cover = resolveImageUrl(p['coverImageUrl']?.toString());
                            final name = (p['name'] ?? 'Project').toString();
                            final locality = (p['locality'] ?? '').toString();
                            final price = (p['priceLabel'] ?? p['rateSqft'] ?? '').toString();
                            final slug = (p['slug'] ?? p['id'] ?? '').toString();
                            return _ProjectChipCard(
                              name: name,
                              locality: locality,
                              price: price,
                              coverUrl: cover,
                              onTap: () {
                                if (slug.isEmpty) return;
                                widget.onNavigate('/project-detail', slug);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recommended listings',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate('/properties'),
                          child: const Text('Browse more'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_listings.isEmpty)
                      const _SoftEmpty(text: 'No listings matched this city. Browse all properties instead.')
                    else
                      ..._listings.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListingRowCard(
                            item: item,
                            priceLabel: item.price > 0 ? _inr.format(item.price) : 'Price on request',
                            onTap: () => widget.onNavigate('/property-detail', item.id),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tip',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Save listings you like, then compare BHK, rate, and locality from Insights.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectChipCard extends StatelessWidget {
  const _ProjectChipCard({
    required this.name,
    required this.locality,
    required this.price,
    required this.coverUrl,
    required this.onTap,
  });

  final String name;
  final String locality;
  final String price;
  final String coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: coverUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFEEF2FF),
                          alignment: Alignment.center,
                          child: const Icon(Icons.apartment, color: Color(0xFF4F46E5)),
                        )
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEF2FF),
                            alignment: Alignment.center,
                            child: const Icon(Icons.apartment, color: Color(0xFF4F46E5)),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                        fontSize: 12,
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

class _ListingRowCard extends StatelessWidget {
  const _ListingRowCard({
    required this.item,
    required this.priceLabel,
    required this.onTap,
  });

  final PropertyItem item;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = item.imageUrl ?? '';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: cover.isEmpty
                      ? Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.home_work_outlined, color: Color(0xFF4F46E5)),
                        )
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEF2FF),
                            child: const Icon(Icons.home_work_outlined, color: Color(0xFF4F46E5)),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.bhk > 0) '${item.bhk} BHK',
                        if (item.locality.isNotEmpty) item.locality,
                        if (item.city.isNotEmpty) item.city,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftEmpty extends StatelessWidget {
  const _SoftEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
    );
  }
}
