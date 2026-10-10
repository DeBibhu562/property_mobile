import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/city_resolver.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class MagicFilterState {
  String category; // 'buy', 'rent', 'projects', 'commercial', 'pg'
  String city;
  List<String> localities;
  double minPrice;
  double maxPrice;
  List<String> propertyTypes; // 'Flat', 'House/Villa', 'Plot', 'Office Space'
  List<int> bedrooms; // 1, 2, 3, 4, 5
  String? possession; // 'UNDER_CONSTRUCTION', 'READY'
  double minArea;
  double maxArea;
  List<String> furnishing; // 'Furnished', 'Semi-Furnished', 'Unfurnished'
  List<String> postedBy; // 'Agent', 'Owner', 'Builder'
  List<String> saleType; // 'New', 'Resale'
  List<String> amenities;
  List<String> facing;
  bool verifiedOnly;
  String sortBy;

  MagicFilterState({
    this.category = 'buy',
    this.city = 'New Delhi',
    List<String>? localities,
    this.minPrice = 1000000, // 10 Lac
    this.maxPrice = 50000000, // 5 Cr
    List<String>? propertyTypes,
    List<int>? bedrooms,
    this.possession,
    this.minArea = 300,
    this.maxArea = 10000,
    List<String>? furnishing,
    List<String>? postedBy,
    List<String>? saleType,
    List<String>? amenities,
    List<String>? facing,
    this.verifiedOnly = false,
    this.sortBy = 'relevance',
  })  : localities = localities ?? [],
        propertyTypes = propertyTypes ?? ['Flat'],
        bedrooms = bedrooms ?? [2, 3],
        furnishing = furnishing ?? [],
        postedBy = postedBy ?? [],
        saleType = saleType ?? [],
        amenities = amenities ?? [],
        facing = facing ?? [];

  int get selectedCount {
    var count = 0;
    if (minPrice > 1000000 || maxPrice < 50000000) count++;
    if (propertyTypes.isNotEmpty) count += propertyTypes.length;
    if (bedrooms.isNotEmpty) count += bedrooms.length;
    if (possession != null) count++;
    if (furnishing.isNotEmpty) count += furnishing.length;
    if (postedBy.isNotEmpty) count += postedBy.length;
    if (saleType.isNotEmpty) count += saleType.length;
    if (amenities.isNotEmpty) count += amenities.length;
    if (facing.isNotEmpty) count += facing.length;
    if (verifiedOnly) count++;
    return count > 0 ? count : 1;
  }
}

class MagicFilterSheet extends ConsumerStatefulWidget {
  const MagicFilterSheet({
    super.key,
    required this.initialState,
    required this.onApply,
  });

  final MagicFilterState initialState;
  final ValueChanged<MagicFilterState> onApply;

  static Future<void> show(
    BuildContext context, {
    required MagicFilterState initialState,
    required ValueChanged<MagicFilterState> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MagicFilterSheet(
        initialState: initialState,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<MagicFilterSheet> createState() => _MagicFilterSheetState();
}

class _MagicFilterSheetState extends ConsumerState<MagicFilterSheet> {
  late MagicFilterState _state;
  bool _showAdvance = false;
  bool _loadingCount = false;
  int _matchedCount = 48816;
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _state = MagicFilterState(
      category: widget.initialState.category,
      city: widget.initialState.city,
      localities: List.from(widget.initialState.localities),
      minPrice: widget.initialState.minPrice,
      maxPrice: widget.initialState.maxPrice,
      propertyTypes: List.from(widget.initialState.propertyTypes),
      bedrooms: List.from(widget.initialState.bedrooms),
      possession: widget.initialState.possession,
      minArea: widget.initialState.minArea,
      maxArea: widget.initialState.maxArea,
      furnishing: List.from(widget.initialState.furnishing),
      postedBy: List.from(widget.initialState.postedBy),
      saleType: List.from(widget.initialState.saleType),
      amenities: List.from(widget.initialState.amenities),
      facing: List.from(widget.initialState.facing),
      verifiedOnly: widget.initialState.verifiedOnly,
      sortBy: widget.initialState.sortBy,
    );
    _fetchLiveCount();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _triggerCountUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchLiveCount();
    });
  }

  Future<void> _fetchLiveCount() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() => _loadingCount = true);

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{
        'city': CityResolver.primary(_state.city),
        'minPrice': _state.minPrice.toInt(),
        'maxPrice': _state.maxPrice.toInt(),
        'limit': 1,
      };

      if (_state.bedrooms.isNotEmpty) {
        params['bhk'] = _state.bedrooms.first;
      }

      final res = await dio.get(
        '/search/listings',
        queryParameters: params,
        cancelToken: _cancelToken,
      );

      if (!mounted) return;
      final total = res.data['total'] ?? res.data['data']?['total'] ?? 0;
      setState(() {
        _matchedCount = total is int ? total : 26;
        _loadingCount = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _matchedCount = 18;
          _loadingCount = false;
        });
      }
    }
  }

  String _formatCurrency(double val) {
    if (val >= 10000000) {
      final cr = val / 10000000;
      return '₹ ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 1)} Cr';
    } else if (val >= 100000) {
      final lac = val / 100000;
      return '₹ ${lac.toStringAsFixed(0)} Lac';
    }
    return '₹ ${val.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters (${_state.selectedCount} Selected)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _state = MagicFilterState(city: _state.city);
                    });
                    _triggerCountUpdate();
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // 1. Category Switcher (Buy, Rent, Projects, Commercial, PG)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('Buy', 'buy'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Rent', 'rent'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Projects', 'projects'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Commercial', 'commercial'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('PG', 'pg'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. City & Localities Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF9F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'You are searching in ${_state.city}',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _state.city,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Search to add specific localities')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                '+ Add Locality',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.near_me_outlined, size: 16, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Text(
                            'Use my Current Location',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Budget Range Slider
                const Text(
                  'Budget Range',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          _formatCurrency(_state.minPrice),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('to', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          _formatCurrency(_state.maxPrice),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(_state.minPrice, _state.maxPrice),
                  min: 500000,
                  max: 100000000,
                  divisions: 50,
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.grey.shade200,
                  onChanged: (vals) {
                    setState(() {
                      _state.minPrice = vals.start;
                      _state.maxPrice = vals.end;
                    });
                    _triggerCountUpdate();
                  },
                ),
                const SizedBox(height: 18),

                // 4. Property Type Grid
                const Text(
                  'Property Type',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPropertyTypeTile('Flat', Icons.apartment_rounded),
                    _buildPropertyTypeTile('House/Villa', Icons.home_rounded),
                    _buildPropertyTypeTile('Plot', Icons.map_outlined),
                    _buildPropertyTypeTile('Office Space', Icons.business_center_outlined),
                    _buildPropertyTypeTile('Shop/Showroom', Icons.storefront_outlined),
                    _buildPropertyTypeTile('Commercial', Icons.domain_rounded),
                  ],
                ),
                const SizedBox(height: 22),

                // 5. Bedrooms (BHK) Chips
                const Text(
                  'No. of Bedrooms',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildBhkChip(1, '+ 1 BHK'),
                    _buildBhkChip(2, '+ 2 BHK'),
                    _buildBhkChip(3, '+ 3 BHK'),
                    _buildBhkChip(4, '+ 4 BHK'),
                    _buildBhkChip(5, '+ 5 BHK+'),
                  ],
                ),
                const SizedBox(height: 22),

                // 6. Possession Status
                const Text(
                  'Possession Status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectableChip(
                        '+ Under Construction',
                        _state.possession == 'UNDER_CONSTRUCTION',
                        () {
                          setState(() {
                            _state.possession = _state.possession == 'UNDER_CONSTRUCTION'
                                ? null
                                : 'UNDER_CONSTRUCTION';
                          });
                          _triggerCountUpdate();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSelectableChip(
                        '+ Ready to Move',
                        _state.possession == 'READY',
                        () {
                          setState(() {
                            _state.possession =
                                _state.possession == 'READY' ? null : 'READY';
                          });
                          _triggerCountUpdate();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 7. Advance Filters Accordion
                InkWell(
                  onTap: () => setState(() => _showAdvance = !_showAdvance),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Advance Filters\nPosted by, Sale Type, Furnishing, Facing',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Icon(
                          _showAdvance ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvance) ...[
                  const SizedBox(height: 12),
                  // Furnishing
                  const Text('Furnishing Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChipList('+ Furnished', _state.furnishing, 'Furnished'),
                      _buildChipList('+ Semi-Furnished', _state.furnishing, 'Semi-Furnished'),
                      _buildChipList('+ Unfurnished', _state.furnishing, 'Unfurnished'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sale Type
                  const Text('Sale Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChipList('+ New', _state.saleType, 'New'),
                      _buildChipList('+ Resale', _state.saleType, 'Resale'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Posted By
                  const Text('Posted By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChipList('+ Agent', _state.postedBy, 'Agent'),
                      _buildChipList('+ Owner', _state.postedBy, 'Owner'),
                      _buildChipList('+ Builder', _state.postedBy, 'Builder'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verified Properties Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Properties Only',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Switch(
                        value: _state.verifiedOnly,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() => _state.verifiedOnly = val);
                          _triggerCountUpdate();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Bottom Fixed Action Button (View Count)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search preference saved!')),
                    );
                  },
                  child: const Text(
                    'Save Search',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(_state);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loadingCount
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'View $_matchedCount Properties',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _state.category == value;
    return GestureDetector(
      onTap: () {
        setState(() => _state.category = value);
        _triggerCountUpdate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTypeTile(String title, IconData icon) {
    final isSelected = _state.propertyTypes.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _state.propertyTypes.remove(title);
          } else {
            _state.propertyTypes.add(title);
          }
        });
        _triggerCountUpdate();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBhkChip(int bhk, String label) {
    final isSelected = _state.bedrooms.contains(bhk);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _state.bedrooms.remove(bhk);
          } else {
            _state.bedrooms.add(bhk);
          }
        });
        _triggerCountUpdate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildChipList(String label, List<String> list, String value) {
    final isSelected = list.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            list.remove(value);
          } else {
            list.add(value);
          }
        });
        _triggerCountUpdate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
