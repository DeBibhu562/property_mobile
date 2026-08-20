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

  // Data matching the search-portal service fallback
  final List<String> _popularCities = ['New Delhi', 'Mumbai', 'Bengaluru', 'Noida', 'Gurgaon', 'Hyderabad'];

  final List<String> _allCities = [
    'Abohar', 'Abu Dhabi', 'Agartala', 'Agra', 'Ahmednagar', 'Ajmer', 'Akola', 'Alappuzha', 'Aligarh', 'Allahabad',
    'Ambala', 'Amravati', 'Amritsar', 'Anand', 'Anantapur',
    'Bengaluru', 'Bhopal', 'Bhubaneswar', 'Bhuj', 'Bikaner',
    'Chhattarpur', 'Chennai', 'Coimbatore', 'Cuttack',
    'Dehradun', 'Delhi NCR', 'Dwarka', 'Dhanbad',
    'Erode', 'Eluru',
    'Gurgaon', 'Gachibowli', 'Gwalior',
    'Hyderabad', 'Howrah', 'Hubli',
    'Indore', 'Imphal', 'Itanagar',
    'Jaipur', 'Jalandhar', 'Jammu', 'Jamshedpur', 'Jhansi',
    'Kolkata', 'Kochi', 'Kanpur', 'Karnal', 'Kharagpur',
    'Ludhiana', 'Lucknow', 'Latur',
    'Mumbai', 'Madurai', 'Mangaluru', 'Meerut', 'Mysuru',
    'New Delhi', 'Noida', 'Nagpur', 'Nashik',
    'Ooty', 'Ongole',
    'Pune', 'Patna', 'Panchkula', 'Panaji',
    'Raipur', 'Ranchi', 'Rajkot', 'Rohtak',
    'Saket', 'Surat', 'Shimla', 'Srinagar', 'Siliguri',
    'Thane', 'Tirupati', 'Trichy', 'Trivandrum',
    'Udaipur', 'Ujjain',
    'Vadodara', 'Varanasi', 'Vijayawada', 'Visakhapatnam',
    'Wakad', 'Warangal',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchSelection = ref.watch(searchSelectionProvider);
    final intentLabel = searchSelection.intent == 'RENT' ? 'Rent' : 'Buy';

    // Filter cities based on search query or letter selection
    final filteredCities = _allCities.where((c) {
      if (_searchQuery.isNotEmpty) {
        return c.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return c.startsWith(_selectedLetter);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Faint cool background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header with Back Button and Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                    onPressed: () {
                      ref.read(searchSelectionProvider.notifier).clear();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Where do you want to $intentLabel?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose a city which can be changed later',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Type city here...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic_none, color: Color(0xFF6366F1)), // Purple mic
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Listening for voice search...')),
                      );
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Use Current Location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: InkWell(
                onTap: () {
                  ref.read(searchSelectionProvider.notifier).setCity('New Delhi');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.my_location_outlined, color: Color(0xFF6366F1), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Use my current location',
                        style: TextStyle(
                          color: Color(0xFF6366F1), // Purple
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Conditional display: popular cities are hidden during active query
            if (_searchQuery.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Popular Cities',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _popularCities.map((city) {
                    return InkWell(
                      onTap: () {
                        ref.read(searchSelectionProvider.notifier).setCity(city);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_city, size: 16, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Text(
                              city,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Search in other cities section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _searchQuery.isEmpty ? 'Search in 330+ other cities' : 'Search results',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 12),

            // Alphabet row
            if (_searchQuery.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  height: 48,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: 26,
                    itemBuilder: (context, index) {
                      final char = String.fromCharCode(65 + index); // A-Z
                      final isSelected = char == _selectedLetter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedLetter = char;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent, // Indigo-50
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              char,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // City list directory (Two columns)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4, // Adjust for text height
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 4,
                ),
                itemCount: filteredCities.length,
                itemBuilder: (context, index) {
                  final city = filteredCities[index];
                  return InkWell(
                    onTap: () {
                      ref.read(searchSelectionProvider.notifier).setCity(city);
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        city,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
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
    );
  }
}
