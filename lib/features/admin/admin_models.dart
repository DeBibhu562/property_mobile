class ModerationProperty {
  const ModerationProperty({
    required this.id,
    required this.title,
    required this.city,
    required this.locality,
    required this.status,
    required this.price,
    this.ownerName,
    required this.bhk,
    required this.createdAt,
    required this.rejectedImagesCount,
    required this.imagesCount,
  });

  final String id;
  final String title;
  final String city;
  final String locality;
  final String status;
  final int price;
  final String? ownerName;
  final int bhk;
  final DateTime createdAt;
  final int rejectedImagesCount;
  final int imagesCount;

  factory ModerationProperty.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final images = json['images'] as List<dynamic>? ?? const [];
    final rejectedCount = images.where((img) {
      if (img is Map) {
        return img['verificationStatus'] == 'REJECTED';
      }
      return false;
    }).length;

    return ModerationProperty(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      price: json['price'] is num ? (json['price'] as num).toInt() : 0,
      ownerName: owner?['name']?.toString(),
      bhk: json['bhk'] is num ? (json['bhk'] as num).toInt() : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      rejectedImagesCount: rejectedCount,
      imagesCount: images.length,
    );
  }
}
