import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_session.dart';
import '../core/providers.dart';
import '../core/session_provider.dart';
import '../features/property/property_models.dart';
import '../features/saved_search/saved_search_models.dart';

/// Saved tab — saved searches (JWT) plus locally hearted listing IDs with recommendations.
class SavedTabScreen extends ConsumerStatefulWidget {
  const SavedTabScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(String route, [Object? arguments]) onNavigate;

  @override
  ConsumerState<SavedTabScreen> createState() => _SavedTabScreenState();
}

class _SavedTabScreenState extends ConsumerState<SavedTabScreen> {
  CancelToken? _cancelToken;
  List<SavedSearchItem> _savedSearches = const [];
  List<PropertyItem> _localFavoriteItems = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    final session = ref.read(authSessionProvider).valueOrNull;
    final favorites = ref.read(favoritesProvider);

    try {
      List<SavedSearchItem> searches = const [];
      if (session != null) {
        searches = await ref
            .read(savedSearchRepositoryProvider)
            .listSavedSearches(cancelToken: token);
      }

      final favoriteItems = <PropertyItem>[];
      if (favorites.isNotEmpty) {
        final repo = ref.read(propertyRepositoryProvider);
        for (final id in favorites.take(20)) {
          if (token.isCancelled) return;
          try {
            final detail = await repo.getProperty(id);
            favoriteItems.add(
              PropertyItem(
                id: detail.id,
                title: detail.title,
                price: detail.price,
                bhk: detail.bhk,
                city: detail.city,
                locality: detail.locality,
                isVerified: detail.isVerified,
                builtUpArea: detail.builtUpArea,
                isUnderConstruction: detail.isUnderConstruction,
                imageUrl: detail.images.isNotEmpty ? detail.images.first.url : null,
              ),
            );
          } catch (_) {}
        }
      }

      if (!mounted || token.isCancelled) return;
      setState(() {
        _savedSearches = searches;
        _localFavoriteItems = favoriteItems;
      });
    } catch (_) {
      if (!mounted || token.isCancelled) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Properties',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // When user has saved searches
            if (_savedSearches.isNotEmpty) ...[
              _sectionTitle('Saved Searches (${_savedSearches.length})'),
              const SizedBox(height: 8),
              ..._savedSearches.map(_savedSearchTile),
              const SizedBox(height: 20),
            ],

            // When user has hearted listings
            if (_localFavoriteItems.isNotEmpty) ...[
              _sectionTitle('Hearted Homes (${_localFavoriteItems.length})'),
              const SizedBox(height: 8),
              ..._localFavoriteItems.map(_favoriteTile),
              const SizedBox(height: 24),
            ],

            // If completely empty
            if (_savedSearches.isEmpty && _localFavoriteItems.isEmpty) ...[
              _EmptySavedHero(
                session: session,
                onSignIn: () => widget.onNavigate('/auth'),
              ),
              const SizedBox(height: 28),
            ],

            // Quick Popular Search Chips
            _sectionTitle('Popular Searches to Explore'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SearchFilterChip(
                  label: '3 BHK in Dwarka',
                  icon: Icons.apartment,
                  onTap: () => widget.onNavigate('/properties', {'query': 'Dwarka', 'type': 'APARTMENT'}),
                ),
                _SearchFilterChip(
                  label: 'Luxury Villas in Gurgaon',
                  icon: Icons.holiday_village,
                  onTap: () => widget.onNavigate('/properties', {'query': 'Gurgaon', 'type': 'VILLA'}),
                ),
                _SearchFilterChip(
                  label: 'Under ₹ 1.2 Cr',
                  icon: Icons.account_balance_wallet,
                  onTap: () => widget.onNavigate('/properties', {'maxPrice': 12000000}),
                ),
                _SearchFilterChip(
                  label: 'Ready to Move Rentals',
                  icon: Icons.key,
                  onTap: () => widget.onNavigate('/properties', {'listingType': 'RENT'}),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Curated Recommendations
            _sectionTitle('Recommended For You'),
            const SizedBox(height: 10),
            _RecommendedPropertyCard(
              title: 'DLF Regal Gardens 3 BHK',
              locality: 'Sector 90, Gurgaon',
              price: '₹ 1.65 Cr',
              bhkArea: '3 BHK · 1,750 sq.ft',
              imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
              onTap: () => widget.onNavigate('/properties', {'query': 'DLF'}),
            ),
            const SizedBox(height: 12),
            _RecommendedPropertyCard(
              title: 'Godrej Palm Retreat Premium Suite',
              locality: 'Sector 150, Noida',
              price: '₹ 98 Lac',
              bhkArea: '2 BHK · 1,220 sq.ft',
              imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
              onTap: () => widget.onNavigate('/properties', {'query': 'Godrej'}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _savedSearchTile(SavedSearchItem item) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bookmark_outline, color: Color(0xFF4F46E5), size: 20),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          final q = item.query['q']?.toString();
          widget.onNavigate('/properties', {
            if (q != null && q.isNotEmpty) 'query': q,
            'type': item.query['type']?.toString(),
            'listingType': item.query['listingType']?.toString(),
            'title': item.name,
          });
        },
      ),
    );
  }

  Widget _favoriteTile(PropertyItem item) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? Image.network(
                  item.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.home, color: Color(0xFF4F46E5)),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFEEF2FF),
                  child: const Icon(Icons.home, color: Color(0xFF4F46E5)),
                ),
        ),
        title: Text(item.cardHeadline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text('${item.locality.isNotEmpty ? "${item.locality}, " : ""}${item.city}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => widget.onNavigate('/property-detail', item.id),
      ),
    );
  }
}

class _EmptySavedHero extends StatelessWidget {
  const _EmptySavedHero({this.session, required this.onSignIn});
  final AuthSession? session;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2), // Rose-50
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, size: 36, color: Color(0xFFE11D48)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Saved Properties Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the heart icon on any home or save your search queries to track price drops & new listings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          if (session == null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign in to sync your wishlist across devices', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF4F46E5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedPropertyCard extends StatelessWidget {
  const _RecommendedPropertyCard({
    required this.title,
    required this.locality,
    required this.price,
    required this.bhkArea,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String locality;
  final String price;
  final String bhkArea;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 90,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.apartment, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locality,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF4F46E5)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              bhkArea,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
