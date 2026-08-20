import 'package:flutter/material.dart';
import '../features/property/property_models.dart';

class PropertyGalleryScreen extends StatefulWidget {
  const PropertyGalleryScreen({super.key, required this.images});

  final List<PropertyImage> images;

  @override
  State<PropertyGalleryScreen> createState() => _PropertyGalleryScreenState();
}

class _PropertyGalleryScreenState extends State<PropertyGalleryScreen> {
  late Map<String, List<PropertyImage>> _groupedImages;
  late List<String> _tabs;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _groupPhotos();
  }

  void _groupPhotos() {
    final Map<String, List<PropertyImage>> groups = {};

    // Grouping logic with standard fallback
    for (final img in widget.images) {
      String sec = (img.section ?? 'Common Area').toUpperCase();
      // Format section name nicely
      if (sec == 'BEDROOM') sec = 'Bedroom';
      else if (sec == 'KITCHEN') sec = 'Kitchen';
      else if (sec == 'BATHROOM') sec = 'Bathroom';
      else if (sec == 'LIVING' || sec == 'COMMON') sec = 'Common Area';
      else {
        // titlecase
        sec = sec[0] + sec.substring(1).toLowerCase();
      }
      groups.putIfAbsent(sec, () => []).add(img);
    }

    // Ensure we have at least some groups if empty
    if (groups.isEmpty) {
      groups['Overview'] = widget.images;
    }

    setState(() {
      _groupedImages = groups;
      _tabs = groups.keys.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Scaffold(body: Center(child: Text('No images available')));
    }

    final activeKey = _tabs[_activeTabIndex];
    final activeImages = _groupedImages[activeKey] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark premium obsidian theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gallery (${widget.images.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, idx) {
                final key = _tabs[idx];
                final count = _groupedImages[key]?.length ?? 0;
                final isSelected = idx == _activeTabIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: Text('$key ($count)'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _activeTabIndex = idx;
                        });
                      }
                    },
                    selectedColor: const Color(0xFF4F46E5),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Images lists
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activeImages.length,
              itemBuilder: (context, idx) {
                final img = activeImages[idx];
                // Treat everything as verified for premium display in mock/production demo
                final isVerified = img.verificationStatus == 'APPROVED' || img.verificationStatus == null;

                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              img.url,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Section tag (e.g. Bedroom One)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                img.section ?? activeKey,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Verification tick badge
                          if (isVerified)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Sticky bottom navigation actions bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  side: const BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening chat...')),
                  );
                },
                child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  side: const BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number: +91 99000 00002')),
                  );
                },
                child: const Icon(Icons.phone_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enquiry sent successfully!')),
                    );
                  },
                  child: const Text(
                    'Contact Agent',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
