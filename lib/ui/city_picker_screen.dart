import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLetter = 'A';
  String _searchQuery = '';

  final List<Map<String, String>> _popularCities = [
    {'name': 'New Delhi', 'state': 'Delhi NCR', 'image': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Gurgaon', 'state': 'Haryana', 'image': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Noida', 'state': 'Uttar Pradesh', 'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Mumbai', 'state': 'Maharashtra', 'image': 'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Bengaluru', 'state': 'Karnataka', 'image': 'https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&w=400&q=80'},
    {'name': 'Hyderabad', 'state': 'Telangana', 'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80'},
  ];

  final List<String> _allCities = [
    'Abohar', 'Agartala', 'Agra', 'Ahmedabad', 'Ahmednagar', 'Ajmer', 'Akola', 'Alappuzha', 'Aligarh', 'Allahabad',
    'Ambala', 'Amravati', 'Amritsar', 'Anand', 'Anantapur', 'Aurangabad',
    'Bengaluru', 'Bhopal', 'Bhubaneswar', 'Bhuj', 'Bikaner', 'Bilaspur',
    'Chandigarh', 'Chennai', 'Coimbatore', 'Cuttack',
    'Dehradun', 'Delhi NCR', 'Dhanbad', 'Dwarka',
    'Erode', 'Eluru',
    'Faridabad', 'Gandhinagar', 'Ghaziabad', 'Greater Noida', 'Gurgaon', 'Gwalior',
    'Hyderabad', 'Howrah', 'Hubli',
    'Indore', 'Imphal', 'Itanagar',
    'Jaipur', 'Jalandhar', 'Jammu', 'Jamshedpur', 'Jhansi', 'Jodhpur',
    'Kolkata', 'Kochi', 'Kanpur', 'Karnal', 'Kozhikode',
    'Ludhiana', 'Lucknow', 'Latur',
    'Mumbai', 'Madurai', 'Mangaluru', 'Meerut', 'Mysuru',
    'Nagpur', 'Nashik', 'Navi Mumbai', 'New Delhi', 'Noida',
    'Patna', 'Panchkula', 'Panaji', 'Panipat', 'Pune',
    'Raipur', 'Ranchi', 'Rajkot', 'Rohtak',
    'Saket', 'Surat', 'Shimla', 'Srinagar', 'Siliguri',
    'Thane', 'Thrissur', 'Tirupati', 'Trichy', 'Trivandrum',
    'Udaipur', 'Ujjain',
    'Vadodara', 'Varanasi', 'Vijayawada', 'Visakhapatnam',
    'Warangal', 'Yamunanagar',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCity(String city) {
    ref.read(searchSelectionProvider.notifier).setCity(city);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final searchSelection = ref.read(searchSelectionProvider);
    if (searchSelection.previousCity != null && searchSelection.previousCity!.isNotEmpty) {
      ref.read(searchSelectionProvider.notifier).setCity(searchSelection.previousCity);
    } else {
      ref.read(searchSelectionProvider.notifier).setIntent(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchSelection = ref.watch(searchSelectionProvider);
    final intentLabel = searchSelection.intent == 'RENT' ? 'Rent' : 'Buy';

    final filteredCities = _allCities.where((c) {
      if (_searchQuery.isNotEmpty) {
        return c.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return c.startsWith(_selectedLetter);
    }).toList();

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
            onPressed: _handleClose,
          ),
          title: Text(
            'Select City to $intentLabel',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
          ),
        ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search city or state...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
              ),
            ),

            // Use Current Location Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: InkWell(
                onTap: () => _selectCity('Delhi NCR'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.my_location_rounded, color: Color(0xFF4F46E5), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Use my current location (Delhi NCR)',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Popular Metros Section
            if (_searchQuery.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  'Popular Metros',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularCities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final item = _popularCities[idx];
                    final cityName = item['name']!;
                    final stateName = item['state']!;
                    final img = item['image']!;

                    return InkWell(
                      onTap: () => _selectCity(cityName),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(img),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.45),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cityName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              stateName,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Alphabet Selector
            if (_searchQuery.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Explore All Cities (300+)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 26,
                  itemBuilder: (context, index) {
                    final char = String.fromCharCode(65 + index);
                    final isSelected = char == _selectedLetter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedLetter = char),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            char,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // City List Grid
            Expanded(
              child: filteredCities.isEmpty
                  ? const Center(
                      child: Text('No cities match your search', style: TextStyle(color: Color(0xFF94A3B8))),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _selectCity(city),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_city_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      city,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
