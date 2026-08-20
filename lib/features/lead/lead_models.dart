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
