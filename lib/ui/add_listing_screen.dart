import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_error_formatter.dart';
import '../core/indian_currency_formatter.dart';
import '../core/providers.dart';
import '../core/theme.dart';

/// Milestone 5: 8-Step "Post Property Free" Wizard & Monetization (`SCR-14`)
/// Replicates Magicbricks post property experience with draft persistence,
/// real-time Indian currency words converter, floor pickers, photo selection,
/// and tiered monetization packages (Free vs Diamond vs Titanium).
class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  static const String _kDraftKey = 'propertydilado_post_property_draft_v1';

  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 to 7 (Steps 1 to 8)
  bool _submitting = false;
  bool _submittedSuccess = false;
  String? _createdListingId;

  // Form Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'New Delhi');
  final _localityCtrl = TextEditingController();
  final _subLocalityCtrl = TextEditingController();
  final _societyCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  final _builtUpAreaCtrl = TextEditingController();
  final _carpetAreaCtrl = TextEditingController();
  final _maintenanceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  // Step 1: Intent
  String _intent = 'SELL'; // 'SELL', 'RENT', 'PG'

  // Step 2: Property Type
  String _propertyType = 'Flat / Apartment';
  String _propertyCategory = 'RESIDENTIAL'; // 'RESIDENTIAL', 'COMMERCIAL', 'PLOT', 'PG'

  // Step 3: Location
  final List<String> _popularCities = [
    'New Delhi', 'Gurgaon', 'Noida', 'Greater Noida', 'Bangalore', 'Mumbai', 'Pune', 'Hyderabad'
  ];

  // Step 4: Unit Details
  int _bhk = 2;
  int _bathrooms = 2;
  int _balconies = 1;
  int _propertyFloor = 3;
  int _totalFloors = 12;
  String _furnishingStatus = 'Semi-Furnished'; // 'Unfurnished', 'Semi-Furnished', 'Fully Furnished'

  // Step 5: Pricing & Financials
  bool _priceNegotiable = false;
  String _priceWords = '';

  // Step 6: Availability & Age
  String _availability = 'Immediately'; // 'Immediately', 'Within 15 Days', 'Within 30 Days'
  String _ageOfProperty = '1 to 5 Years'; // 'New Construction (< 1 yr)', '1 to 5 Years', '5 to 10 Years', '10+ Years'
  String _facing = 'East'; // 'East', 'North', 'North-East', 'West', 'South'
  bool _isUnderConstruction = false;

  // Step 7: Photos & Media
  final List<String> _selectedPhotos = [
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop', // Modern Living Room
    'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=600&auto=format&fit=crop', // Master Bedroom
  ];

  final List<Map<String, String>> _samplePhotoCatalog = [
    {'title': 'Living Room', 'url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop'},
    {'title': 'Master Bedroom', 'url': 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=600&auto=format&fit=crop'},
    {'title': 'Modular Kitchen', 'url': 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=600&auto=format&fit=crop'},
    {'title': 'Modern Bathroom', 'url': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600&auto=format&fit=crop'},
    {'title': 'Balcony View', 'url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&auto=format&fit=crop'},
    {'title': 'Building Exterior', 'url': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&auto=format&fit=crop'},
  ];

  // Step 8: Monetization Tier
  String _selectedPackage = 'DIAMOND'; // 'FREE', 'DIAMOND', 'TITANIUM'

  @override
  void initState() {
    super.initState();
    _priceCtrl.addListener(_onPriceChanged);
    _loadDraft();
  }

  @override
  void dispose() {
    _priceCtrl.removeListener(_onPriceChanged);
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _localityCtrl.dispose();
    _subLocalityCtrl.dispose();
    _societyCtrl.dispose();
    _houseNoCtrl.dispose();
    _builtUpAreaCtrl.dispose();
    _carpetAreaCtrl.dispose();
    _maintenanceCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  void _onPriceChanged() {
    final raw = _priceCtrl.text.replaceAll(',', '').trim();
    final amount = int.tryParse(raw);
    setState(() {
      if (amount != null && amount > 0) {
        _priceWords = '${IndianCurrencyFormatter.toWords(amount)} Rupees';
      } else {
        _priceWords = '';
      }
    });
  }

  // --- Draft Persistence ---
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_kDraftKey);
      if (draftJson != null && draftJson.isNotEmpty) {
        final data = jsonDecode(draftJson) as Map<String, dynamic>;
        setState(() {
          if (data['intent'] != null) _intent = data['intent'] as String;
          if (data['propertyType'] != null) _propertyType = data['propertyType'] as String;
          if (data['propertyCategory'] != null) _propertyCategory = data['propertyCategory'] as String;
          if (data['city'] != null) _cityCtrl.text = data['city'] as String;
          if (data['locality'] != null) _localityCtrl.text = data['locality'] as String;
          if (data['society'] != null) _societyCtrl.text = data['society'] as String;
          if (data['subLocality'] != null) _subLocalityCtrl.text = data['subLocality'] as String;
          if (data['bhk'] != null) _bhk = data['bhk'] as int;
          if (data['bathrooms'] != null) _bathrooms = data['bathrooms'] as int;
          if (data['balconies'] != null) _balconies = data['balconies'] as int;
          if (data['propertyFloor'] != null) _propertyFloor = data['propertyFloor'] as int;
          if (data['totalFloors'] != null) _totalFloors = data['totalFloors'] as int;
          if (data['furnishingStatus'] != null) _furnishingStatus = data['furnishingStatus'] as String;
          if (data['builtUpArea'] != null) _builtUpAreaCtrl.text = data['builtUpArea'].toString();
          if (data['carpetArea'] != null) _carpetAreaCtrl.text = data['carpetArea'].toString();
          if (data['price'] != null) _priceCtrl.text = data['price'].toString();
          if (data['priceNegotiable'] != null) _priceNegotiable = data['priceNegotiable'] as bool;
          if (data['availability'] != null) _availability = data['availability'] as String;
          if (data['ageOfProperty'] != null) _ageOfProperty = data['ageOfProperty'] as String;
          if (data['facing'] != null) _facing = data['facing'] as String;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'intent': _intent,
        'propertyType': _propertyType,
        'propertyCategory': _propertyCategory,
        'city': _cityCtrl.text.trim(),
        'locality': _localityCtrl.text.trim(),
        'society': _societyCtrl.text.trim(),
        'subLocality': _subLocalityCtrl.text.trim(),
        'bhk': _bhk,
        'bathrooms': _bathrooms,
        'balconies': _balconies,
        'propertyFloor': _propertyFloor,
        'totalFloors': _totalFloors,
        'furnishingStatus': _furnishingStatus,
        'builtUpArea': _builtUpAreaCtrl.text.trim(),
        'carpetArea': _carpetAreaCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'priceNegotiable': _priceNegotiable,
        'availability': _availability,
        'ageOfProperty': _ageOfProperty,
        'facing': _facing,
      };
      await prefs.setString(_kDraftKey, jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDraftKey);
    } catch (_) {}
  }

  // --- Step Navigation ---
  void _nextStep() {
    _saveDraft();
    if (_currentStep < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _showExitDialog();
    }
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Draft & Exit?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Your entered details have been saved as a draft. You can resume editing anytime!',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.maybePop(context);
    }
  }

  // --- Submission to Backend API ---
  Future<void> _submitListing() async {
    setState(() => _submitting = true);
    try {
      final title = _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : '$_bhk BHK $_propertyType in ${_localityCtrl.text.trim().isNotEmpty ? _localityCtrl.text.trim() : _cityCtrl.text.trim()}';

      final desc = _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : 'Beautiful $_bhk BHK $_propertyType with ${_carpetAreaCtrl.text.trim()} sqft area in ${_localityCtrl.text.trim()}, ${_cityCtrl.text.trim()}. Equipped with modern amenities, ${_furnishingStatus.toLowerCase()} configuration, and prime connectivity.';

      final priceVal = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 4500000;
      final builtUpVal = int.tryParse(_builtUpAreaCtrl.text.trim()) ?? 1250;
      final carpetVal = int.tryParse(_carpetAreaCtrl.text.trim()) ?? 1050;

      final payload = <String, dynamic>{
        'title': title,
        'description': desc,
        'type': _intent == 'SELL' ? 'SALE' : 'RENT',
        'listingType': _propertyCategory,
        'propertySubType': _propertyType,
        'city': _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : 'New Delhi',
        'locality': _localityCtrl.text.trim().isNotEmpty ? _localityCtrl.text.trim() : 'Sector 150',
        'price': priceVal,
        'bhk': _bhk,
        'bedrooms': _bhk,
        'bathrooms': _bathrooms,
        'balconies': _balconies,
        'propertyFloor': _propertyFloor,
        'totalFloors': _totalFloors,
        'furnishingStatus': _furnishingStatus,
        'builtUpArea': builtUpVal,
        'plotArea': carpetVal,
        'ageOfProperty': _ageOfProperty,
        'facing': _facing,
        'priceNegotiable': _priceNegotiable,
        'isUnderConstruction': _isUnderConstruction,
        'photos': _selectedPhotos,
        'isFeatured': _selectedPackage != 'FREE',
      };

      final repo = ref.read(listingRepositoryProvider);
      final created = await repo.createListing(payload);

      await _clearDraft();

      if (mounted) {
        setState(() {
          _submitting = false;
          _submittedSuccess = true;
          _createdListingId = created.id;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        final err = ApiErrorFormatter.format(e, defaultMessage: 'Failed to publish listing');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: Text(err.message, style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedSuccess) {
      return _buildSuccessScreen();
    }

    final double progress = (_currentStep + 1) / 8.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prevStep();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
            onPressed: _prevStep,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Post Property',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '100% FREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Step ${_currentStep + 1} of 8 • ${_getStepTitle(_currentStep)}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
        ),
        body: _submitting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Publishing your property on Property DilaDo...',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              )
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _buildStep1Intent(),
                  _buildStep2PropertyType(),
                  _buildStep3Location(),
                  _buildStep4UnitDetails(),
                  _buildStep5Pricing(),
                  _buildStep6Availability(),
                  _buildStep7Photos(),
                  _buildStep8Monetization(),
                ],
              ),
        bottomNavigationBar: _submittedSuccess || _submitting ? null : _buildBottomButtonBar(),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Property Intent';
      case 1: return 'Property Type';
      case 2: return 'Location Details';
      case 3: return 'Unit Configuration';
      case 4: return 'Price & Financials';
      case 5: return 'Availability & Age';
      case 6: return 'Photos & Media';
      case 7: return 'Package & Publish';
      default: return '';
    }
  }

  // --- Step 1: Listing Intent ---
  Widget _buildStep1Intent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'What do you want to do with your property?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select your listing intent to connect with the right verified buyers or tenants.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildIntentCard(
          id: 'SELL',
          title: 'Sell Property',
          subtitle: 'Transfer ownership with 0% brokerage directly to genuine buyers',
          icon: Icons.sell_outlined,
          badge: 'HIGHEST DEMAND',
        ),
        const SizedBox(height: 14),
        _buildIntentCard(
          id: 'RENT',
          title: 'Rent / Lease Out',
          subtitle: 'Find trustworthy tenants with instant background verified profiles',
          icon: Icons.vpn_key_outlined,
          badge: 'ZERO VACANCY',
        ),
        const SizedBox(height: 14),
        _buildIntentCard(
          id: 'PG',
          title: 'PG / Co-Living',
          subtitle: 'List paying guest rooms, shared beds, or coliving spaces for youth',
          icon: Icons.hotel_outlined,
          badge: 'STEADY INCOME',
        ),
        const SizedBox(height: 30),
        _buildBenefitTip(
          icon: Icons.check_circle_outline,
          title: 'Property DilaDo Guarantee',
          desc: 'Over 10 Lakh verified buyers & tenants browse our portal every month.',
        ),
      ],
    );
  }

  Widget _buildIntentCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
  }) {
    final isSelected = _intent == id;
    return InkWell(
      onTap: () {
        setState(() {
          _intent = id;
          if (id == 'PG') {
            _propertyCategory = 'PG';
          } else {
            _propertyCategory = 'RESIDENTIAL';
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Property Type ---
  Widget _buildStep2PropertyType() {
    final types = [
      {'name': 'Flat / Apartment', 'icon': Icons.apartment_outlined, 'cat': 'RESIDENTIAL'},
      {'name': 'Independent House / Villa', 'icon': Icons.villa_outlined, 'cat': 'RESIDENTIAL'},
      {'name': 'Builder Floor', 'icon': Icons.home_work_outlined, 'cat': 'RESIDENTIAL'},
      {'name': 'Plot / Land', 'icon': Icons.terrain_outlined, 'cat': 'PLOT'},
      {'name': 'Studio Apartment', 'icon': Icons.weekend_outlined, 'cat': 'RESIDENTIAL'},
      {'name': 'Penthouse', 'icon': Icons.domain_outlined, 'cat': 'RESIDENTIAL'},
      {'name': 'Commercial Office / Shop', 'icon': Icons.storefront_outlined, 'cat': 'COMMERCIAL'},
      {'name': 'Farm House', 'icon': Icons.nature_people_outlined, 'cat': 'RESIDENTIAL'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'What type of property is it?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pick the configuration that accurately matches your unit structure.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: types.length,
          itemBuilder: (ctx, i) {
            final t = types[i];
            final name = t['name'] as String;
            final icon = t['icon'] as IconData;
            final cat = t['cat'] as String;
            final isSelected = _propertyType == name;

            return InkWell(
              onTap: () {
                setState(() {
                  _propertyType = name;
                  _propertyCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Step 3: Location Details ---
  Widget _buildStep3Location() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Where is your property located?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Accurate society & locality details get up to 3.2x more genuine buyer contacts.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Quick City Chips
        const Text('Popular Cities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularCities.map((c) {
            final isSelected = _cityCtrl.text.trim().toLowerCase() == c.toLowerCase();
            return ChoiceChip(
              label: Text(c),
              selected: isSelected,
              onSelected: (_) => setState(() => _cityCtrl.text = c),
              selectedColor: AppTheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // City Input
        TextField(
          controller: _cityCtrl,
          decoration: InputDecoration(
            labelText: 'City *',
            hintText: 'e.g. New Delhi, Gurgaon, Bangalore',
            prefixIcon: const Icon(Icons.location_city_outlined, color: AppTheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Project / Society
        TextField(
          controller: _societyCtrl,
          decoration: InputDecoration(
            labelText: 'Project / Society Name',
            hintText: 'e.g. DLF Cyber City, Godrej Woods, ATS Pristine',
            prefixIcon: const Icon(Icons.domain_outlined, color: Color(0xFF64748B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Locality
        TextField(
          controller: _localityCtrl,
          decoration: InputDecoration(
            labelText: 'Locality *',
            hintText: 'e.g. Sector 150, Whitefield, Indirapuram',
            prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFF64748B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Sub-locality / Landmark
        TextField(
          controller: _subLocalityCtrl,
          decoration: InputDecoration(
            labelText: 'Landmark / Sub-locality',
            hintText: 'e.g. Near Metro Station / Next to Fortis Hospital',
            prefixIcon: const Icon(Icons.near_me_outlined, color: Color(0xFF64748B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // House / Flat No (Optional)
        TextField(
          controller: _houseNoCtrl,
          decoration: InputDecoration(
            labelText: 'Flat / House No. & Tower (Optional)',
            hintText: 'Only shared with verified buyers after your approval',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        _buildBenefitTip(
          icon: Icons.shield_outlined,
          title: 'Privacy Protected',
          desc: 'Your exact house number is never displayed publicly without your explicit consent.',
        ),
      ],
    );
  }

  // --- Step 4: Unit Configuration ---
  Widget _buildStep4UnitDetails() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Tell us about your unit',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Specify room counts, floor position, and square footage details.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // BHK Count Chips
        const Text('Bedroom (BHK)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3, 4, 5].map((b) {
            final isSelected = _bhk == b;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text('$b BHK'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _bhk = b),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Bathrooms & Balconies
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bathrooms', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [1, 2, 3, 4].map((bath) {
                      final isSelected = _bathrooms == bath;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _bathrooms = bath),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$bath',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balconies', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [0, 1, 2, 3].map((balc) {
                      final isSelected = _balconies == balc;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _balconies = balc),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$balc',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Floor Picker Sheet Trigger
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Floor Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    'Floor $_propertyFloor of $_totalFloors Total Floors',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openFloorPickerSheet,
                icon: const Icon(Icons.stairs_outlined, size: 16),
                label: const Text('Change Floor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Furnishing Status
        const Text('Furnishing Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: ['Unfurnished', 'Semi-Furnished', 'Fully Furnished'].map((f) {
            final isSelected = _furnishingStatus == f;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(f, textAlign: TextAlign.center),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _furnishingStatus = f),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Carpet & Super Area
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _carpetAreaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Carpet Area *',
                  suffixText: 'sq.ft',
                  hintText: '1050',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _builtUpAreaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Super Area',
                  suffixText: 'sq.ft',
                  hintText: '1250',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openFloorPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        int tempFloor = _propertyFloor;
        int tempTotal = _totalFloors;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Floor Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Property on Floor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      DropdownButton<int>(
                        value: tempFloor,
                        items: List.generate(tempTotal + 1, (i) => i).map((floor) {
                          return DropdownMenuItem(
                            value: floor,
                            child: Text(floor == 0 ? 'Ground Floor' : 'Floor $floor'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => tempFloor = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Floors in Tower:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      DropdownButton<int>(
                        value: tempTotal,
                        items: List.generate(40, (i) => i + 1).map((tot) {
                          return DropdownMenuItem(value: tot, child: Text('$tot Floors'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() {
                              tempTotal = v;
                              if (tempFloor > tempTotal) tempFloor = tempTotal;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _propertyFloor = tempFloor;
                          _totalFloors = tempTotal;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Floor Selection', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Step 5: Pricing & Financials ---
  Widget _buildStep5Pricing() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _intent == 'SELL' ? 'Set your expected price' : 'Set expected monthly rent',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Be realistic with pricing. Overpriced listings take 4x longer to find genuine buyers.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Price Input
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: _intent == 'SELL' ? 'Expected Selling Price (₹) *' : 'Monthly Rent (₹) *',
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
            hintText: _intent == 'SELL' ? '4500000' : '35000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // Live Real-Time Indian Words Converter Display
        if (_priceWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, color: Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _priceWords,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Quick Suggestions
        const Text('Quick Suggestions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: (_intent == 'SELL' ? [3500000, 5000000, 7500000, 10000000, 15000000] : [15000, 25000, 35000, 50000, 75000]).map((amt) {
            return ActionChip(
              label: Text(IndianCurrencyFormatter.toShortIndian(amt)),
              onPressed: () => _priceCtrl.text = amt.toString(),
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Negotiable checkbox
        CheckboxListTile(
          value: _priceNegotiable,
          onChanged: (v) => setState(() => _priceNegotiable = v ?? false),
          title: const Text('Price is negotiable', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: const Text('Attracts 25% more direct buyer enquiries', style: TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primary,
        ),
        const SizedBox(height: 10),

        // Maintenance & Deposit
        if (_intent == 'RENT') ...[
          TextField(
            controller: _depositCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Security Deposit (₹)',
              prefixText: '₹ ',
              hintText: 'e.g. 70000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
        ],

        TextField(
          controller: _maintenanceCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Maintenance Charges / Month (Optional)',
            prefixText: '₹ ',
            hintText: 'e.g. 3000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- Step 6: Availability & Age ---
  Widget _buildStep6Availability() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'When is it available?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Provide availability timeline, age of property, and direction.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Availability Status
        const Text('Available From', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Immediately', 'Within 15 Days', 'Within 30 Days', 'After 2 Months'].map((a) {
            final isSelected = _availability == a;
            return ChoiceChip(
              label: Text(a),
              selected: isSelected,
              onSelected: (_) => setState(() => _availability = a),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF8FAFC),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Construction Status
        SwitchListTile(
          value: _isUnderConstruction,
          onChanged: (v) => setState(() => _isUnderConstruction = v),
          title: const Text('Under Construction Property', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(_isUnderConstruction ? 'Possession expected in future' : 'Ready to Move in immediately', style: const TextStyle(fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppTheme.primary,
        ),
        const SizedBox(height: 16),

        // Age of Construction
        const Text('Age of Construction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['New (< 1 yr)', '1 to 5 Years', '5 to 10 Years', '10+ Years'].map((age) {
            final isSelected = _ageOfProperty == age;
            return ChoiceChip(
              label: Text(age),
              selected: isSelected,
              onSelected: (_) => setState(() => _ageOfProperty = age),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF8FAFC),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Facing
        const Text('Property Facing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['East', 'North', 'North-East', 'West', 'South'].map((fac) {
            final isSelected = _facing == fac;
            return ChoiceChip(
              label: Text(fac),
              selected: isSelected,
              onSelected: (_) => setState(() => _facing = fac),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFFF8FAFC),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 7: Photos & Media ---
  Widget _buildStep7Photos() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Property Photos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                '${_selectedPhotos.length} Added',
                style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Properties with 3+ photos receive 8x more enquiries. Tap photos to include them.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),

        // Sample Photo Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _samplePhotoCatalog.length,
          itemBuilder: (ctx, i) {
            final photo = _samplePhotoCatalog[i];
            final url = photo['url']!;
            final title = photo['title']!;
            final isSelected = _selectedPhotos.contains(url);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPhotos.remove(url);
                  } else {
                    _selectedPhotos.add(url);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Skip / Later option
        TextButton.icon(
          onPressed: _nextStep,
          icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.textSecondary),
          label: const Text('Add or Replace Photos Later', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // --- Step 8: Monetization Tiers ---
  Widget _buildStep8Monetization() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Choose your listing package',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select how you want to promote your property. You can start Free or boost for faster closure.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),

        // Free Plan
        _buildPackageCard(
          id: 'FREE',
          name: 'Free Listing',
          price: '₹ 0',
          originalPrice: null,
          validity: '30 Days Validity',
          badge: 'BASIC',
          badgeColor: const Color(0xFF64748B),
          features: [
            'Standard search visibility',
            'Direct buyer calls & chats',
            'Self-service photo verification',
          ],
        ),
        const SizedBox(height: 14),

        // Diamond Package (Recommended)
        _buildPackageCard(
          id: 'DIAMOND',
          name: 'Diamond Package',
          price: '₹ 4,634',
          originalPrice: '₹ 9,268',
          validity: '120 Days Validity • 50% OFF',
          badge: 'MOST POPULAR',
          badgeColor: AppTheme.primary,
          features: [
            '⭐ "Verified on Site" Trust Badge',
            '🚀 2x Priority search ranking',
            '📞 40 Guaranteed Buyer Contacts',
            '👨‍💼 Dedicated Relationship Manager',
          ],
        ),
        const SizedBox(height: 14),

        // Titanium Package
        _buildPackageCard(
          id: 'TITANIUM',
          name: 'Titanium VIP Package',
          price: '₹ 4,889',
          originalPrice: '₹ 9,778',
          validity: '180 Days Validity • 50% OFF',
          badge: 'MAX LEADS',
          badgeColor: const Color(0xFF4338CA),
          features: [
            '📷 Professional HD Photoshoot included',
            '🔥 Top-of-search placement across city',
            '📞 50 Guaranteed Buyer Contacts',
            '✉️ 1,000 Targeted Email Blasts to active buyers',
          ],
        ),
        const SizedBox(height: 24),

        // Seller Testimonial
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFCBD5E1),
                child: Text('RK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"Found a verified tenant in just 4 days with the Diamond package! Highly recommended."',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.5, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '— Rohit K., Owner (Gurgaon)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard({
    required String id,
    required String name,
    required String price,
    required String? originalPrice,
    required String validity,
    required String badge,
    required Color badgeColor,
    required List<String> features,
  }) {
    final isSelected = _selectedPackage == id;
    return InkWell(
      onTap: () => setState(() => _selectedPackage = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isSelected ? badgeColor : AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 9.5)),
                    ),
                  ],
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                  color: isSelected ? badgeColor : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textPrimary)),
                if (originalPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(validity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ],
            ),
            const Divider(height: 18, color: Color(0xFFF1F5F9)),
            ...features.map((feat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feat, style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- Sticky Bottom Bar ---
  Widget _buildBottomButtonBar() {
    final isLastStep = _currentStep == 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isLastStep ? _submitListing : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isLastStep
                    ? (_selectedPackage == 'FREE' ? 'Post Property for FREE →' : 'Continue with $_selectedPackage →')
                    : 'Continue to Step ${_currentStep + 2} →',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Success Screen ---
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Property Posted Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your $_propertyType in ${_localityCtrl.text.trim().isNotEmpty ? _localityCtrl.text.trim() : _cityCtrl.text.trim()} is now live on Property DilaDo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Package: $_selectedPackage${_createdListingId != null ? ' • Ref: #$_createdListingId' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/my-listings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View in My Listings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  child: const Text('Back to Home', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitTip({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
