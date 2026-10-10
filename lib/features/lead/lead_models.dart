class SellerLead {
  const SellerLead({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    this.propertyTitle,
    this.listingTitle,
    this.buyerName,
    this.buyerPhone,
  });

  final String id;
  final String status;
  final String message;
  final String createdAt;
  final String? propertyTitle;
  final String? listingTitle;
  final String? buyerName;
  final String? buyerPhone;

  String get subjectTitle => listingTitle ?? propertyTitle ?? 'Enquiry';

  factory SellerLead.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final listing = json['listing'] as Map<String, dynamic>?;
    final buyer = json['buyer'] as Map<String, dynamic>?;
    return SellerLead(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEW',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      propertyTitle: property?['title']?.toString(),
      listingTitle: listing?['title']?.toString(),
      buyerName: buyer?['name']?.toString(),
      buyerPhone: buyer?['phone']?.toString(),
    );
  }
}

class LeadPage {
  const LeadPage({required this.items, required this.total});

  final List<SellerLead> items;
  final int total;

  factory LeadPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((m) => SellerLead.fromJson(m.cast<String, dynamic>()))
        .toList();
    final total = json['total'] is num ? (json['total'] as num).toInt() : items.length;
    return LeadPage(items: items, total: total);
  }
}

class BuyerLead {
  const BuyerLead({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.listingId,
    required this.listingTitle,
    required this.price,
    required this.locality,
    this.city = 'New Delhi',
    this.imageUrl,
    this.advertiserName,
    this.advertiserPhone,
    this.userNotes,
    this.marketValueEstimate,
  });

  final String id;
  final String status; // 'ACCEPTED', 'REJECTED', 'CONTACTED', 'NEW'
  final String message;
  final String createdAt;
  final String listingId;
  final String listingTitle;
  final String price;
  final String locality;
  final String city;
  final String? imageUrl;
  final String? advertiserName;
  final String? advertiserPhone;
  final String? userNotes;
  final String? marketValueEstimate;

  BuyerLead copyWith({
    String? status,
    String? userNotes,
  }) {
    return BuyerLead(
      id: id,
      status: status ?? this.status,
      message: message,
      createdAt: createdAt,
      listingId: listingId,
      listingTitle: listingTitle,
      price: price,
      locality: locality,
      city: city,
      imageUrl: imageUrl,
      advertiserName: advertiserName,
      advertiserPhone: advertiserPhone,
      userNotes: userNotes ?? this.userNotes,
      marketValueEstimate: marketValueEstimate,
    );
  }

  factory BuyerLead.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>? ?? {};
    final owner = listing['ownerUser'] as Map<String, dynamic>?;
    final images = listing['images'] as List<dynamic>?;
    String? img;
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        img = first['url']?.toString();
      } else if (first is String) {
        img = first;
      }
    }

    final rawPrice = listing['price'];
    String formattedPrice = '₹ 1.25 Cr';
    if (rawPrice is num) {
      final p = rawPrice.toInt();
      if (p >= 10000000) {
        formattedPrice = '₹ ${(p / 10000000).toStringAsFixed(2)} Cr';
      } else if (p >= 100000) {
        formattedPrice = '₹ ${(p / 100000).toStringAsFixed(1)} Lac';
      } else {
        formattedPrice = '₹ $p';
      }
    }

    // Map Prisma LeadStatus (NEW, CONTACTED, CLOSED) to user display status (ACCEPTED, REJECTED, IN REVIEW)
    final rawStatus = (json['status']?.toString() ?? 'NEW').toUpperCase();
    final status = switch (rawStatus) {
      'CONTACTED' || 'ACCEPTED' => 'ACCEPTED',
      'CLOSED' || 'REJECTED' => 'REJECTED',
      _ => 'IN REVIEW',
    };

    return BuyerLead(
      id: json['id']?.toString() ?? '',
      status: status,
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      listingId: (listing['id'] ?? json['listingId'])?.toString() ?? '',
      listingTitle: listing['title']?.toString() ?? 'Luxury Residential Apartment',
      price: formattedPrice,
      locality: listing['locality']?.toString() ?? 'Sector 150',
      city: listing['city']?.toString() ?? 'Noida, Delhi NCR',
      imageUrl: img,
      advertiserName: owner?['name']?.toString() ?? 'Authorized Relationship Manager',
      advertiserPhone: owner?['phone']?.toString() ?? '+91 98112 34567',
      userNotes: json['userNotes']?.toString(),
      marketValueEstimate: '₹ 1.20 - 1.35 Cr (Fair Value)',
    );
  }
}

