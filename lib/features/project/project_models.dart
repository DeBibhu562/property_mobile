import '../../core/flavor_config.dart';

String _resolveUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) {
    var resolved = url;
    if (resolved.contains('localhost:3000')) {
      resolved = resolved.replaceAll('http://localhost:3000', FlavorConfig.apiBaseUrl);
    }
    if (resolved.contains('127.0.0.1:3000')) {
      resolved = resolved.replaceAll('http://127.0.0.1:3000', FlavorConfig.apiBaseUrl);
    }
    return resolved;
  }
  final base = FlavorConfig.apiBaseUrl;
  return url.startsWith('/') ? '$base$url' : '$base/$url';
}

class ProjectSummary {
  final String id;
  final String name;
  final String slug;
  final String builder;
  final String city;
  final String locality;
  final String? coverImageUrl;
  final int? minPrice;
  final int? maxPrice;
  final List<String> bhkLabels;
  final String? status;

  const ProjectSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.builder,
    required this.city,
    required this.locality,
    this.coverImageUrl,
    this.minPrice,
    this.maxPrice,
    this.bhkLabels = const [],
    this.status,
  });

  String get locationLabel {
    final parts = [locality, city].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as List<dynamic>? ?? const [];
    String? cover = json['coverImageUrl']?.toString();
    if ((cover == null || cover.isEmpty) && media.isNotEmpty) {
      cover = (media.first as Map)['url']?.toString();
    }
    final bhks = (json['configs'] as List<dynamic>? ?? const [])
        .map((c) => c is Map ? c['bhk'] : null)
        .whereType<num>()
        .map((b) => '${b.toInt()} BHK')
        .toSet()
        .toList()
      ..sort();
    return ProjectSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      builder: json['builder']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      coverImageUrl: _resolveUrl(cover),
      minPrice: (json['minPrice'] is num) ? (json['minPrice'] as num).toInt() : null,
      maxPrice: (json['maxPrice'] is num) ? (json['maxPrice'] as num).toInt() : null,
      bhkLabels: bhks,
      status: json['status']?.toString(),
    );
  }
}

class ProjectDetail {
  final String id;
  final String name;
  final String slug;
  final String builder;
  final String city;
  final String locality;
  final String? address;
  final String? description;
  final String? about;
  final String? highlightsSummary;
  final String status;
  final int avgRateSqft;
  final int? minPrice;
  final int? maxPrice;
  final String? reraId;
  final String? tourVideoUrl;
  final String? virtualTourUrl;
  final String? coverImageUrl;
  final List<String> highlightTitles;
  final List<Map<String, String>> amenities;
  final List<Map<String, dynamic>> floorPlans;
  final List<Map<String, dynamic>> pois;
  final List<Map<String, String>> faqs;
  final List<String> galleryUrls;
  final List<Map<String, String>> brochures;
  final int? totalTowers;
  final int? totalUnits;
  final DateTime? possessionDate;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>> paymentPlans;
  final List<String> bhkLabels;

  const ProjectDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.builder,
    required this.city,
    required this.locality,
    this.address,
    this.description,
    this.about,
    this.highlightsSummary,
    required this.status,
    required this.avgRateSqft,
    this.minPrice,
    this.maxPrice,
    this.reraId,
    this.tourVideoUrl,
    this.virtualTourUrl,
    this.coverImageUrl,
    this.highlightTitles = const [],
    this.amenities = const [],
    this.floorPlans = const [],
    this.pois = const [],
    this.faqs = const [],
    this.galleryUrls = const [],
    this.brochures = const [],
    this.totalTowers,
    this.totalUnits,
    this.possessionDate,
    this.latitude,
    this.longitude,
    this.paymentPlans = const [],
    this.bhkLabels = const [],
  });

  String get locationLabel {
    final parts = [locality, city].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? [])
        .map((e) => _resolveUrl((e as Map)['url']?.toString()))
        .where((u) => u.isNotEmpty)
        .toList();
    final cover = _resolveUrl(json['coverImageUrl']?.toString());
    final gallery = [
      if (cover.isNotEmpty) cover,
      ...media.where((u) => u != cover),
    ];
    final bhks = (json['configs'] as List<dynamic>? ?? const [])
        .map((c) => c is Map ? c['bhk'] : null)
        .whereType<num>()
        .map((b) => '${b.toInt()} BHK')
        .toSet()
        .toList()
      ..sort();
    DateTime? possession;
    final rawPoss = json['possessionDate']?.toString();
    if (rawPoss != null && rawPoss.isNotEmpty) {
      possession = DateTime.tryParse(rawPoss);
    }
    return ProjectDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      builder: json['builder']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      about: json['about']?.toString(),
      highlightsSummary: json['highlightsSummary']?.toString(),
      status: json['status']?.toString() ?? '',
      avgRateSqft: (json['avgRateSqft'] is num) ? (json['avgRateSqft'] as num).toInt() : 0,
      minPrice: (json['minPrice'] is num) ? (json['minPrice'] as num).toInt() : null,
      maxPrice: (json['maxPrice'] is num) ? (json['maxPrice'] as num).toInt() : null,
      reraId: json['reraId']?.toString(),
      tourVideoUrl: json['tourVideoUrl']?.toString(),
      virtualTourUrl: json['virtualTourUrl']?.toString(),
      coverImageUrl: cover.isEmpty ? null : cover,
      highlightTitles: (json['highlights'] as List<dynamic>? ?? [])
          .map((e) => (e as Map)['title']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((e) => {
                'category': (e as Map)['category']?.toString() ?? 'General',
                'name': e['name']?.toString() ?? '',
              })
          .where((e) => (e['name'] ?? '').isNotEmpty)
          .toList(),
      floorPlans: (json['floorPlans'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      pois: (json['pois'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      faqs: (json['faqs'] as List<dynamic>? ?? [])
          .map((e) => {
                'question': (e as Map)['question']?.toString() ?? '',
                'answer': e['answer']?.toString() ?? '',
              })
          .toList(),
      galleryUrls: gallery,
      brochures: (json['brochures'] as List<dynamic>? ?? [])
          .map((e) => {
                'title': (e as Map)['title']?.toString() ?? 'Brochure',
                'url': e['url']?.toString() ?? '',
              })
          .toList(),
      totalTowers: (json['totalTowers'] is num) ? (json['totalTowers'] as num).toInt() : null,
      totalUnits: (json['totalUnits'] is num) ? (json['totalUnits'] as num).toInt() : null,
      possessionDate: possession,
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : null,
      paymentPlans: (json['paymentPlans'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      bhkLabels: bhks,
    );
  }
}

class DetailReview {
  final String id;
  final String name;
  final int rating;
  final String? title;
  final String body;

  const DetailReview({
    required this.id,
    required this.name,
    required this.rating,
    required this.body,
    this.title,
  });

  factory DetailReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map?;
    return DetailReview(
      id: json['id']?.toString() ?? '',
      name: user?['name']?.toString() ?? 'User',
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : 0,
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? '',
    );
  }
}

class PaymentPlanItem {
  final int? configBhk;
  final int emiAmount;
  final int tenureYears;
  final double interestRate;

  const PaymentPlanItem({
    this.configBhk,
    required this.emiAmount,
    required this.tenureYears,
    required this.interestRate,
  });

  factory PaymentPlanItem.fromJson(Map<String, dynamic> json) {
    return PaymentPlanItem(
      configBhk: (json['configBhk'] is num) ? (json['configBhk'] as num).toInt() : null,
      emiAmount: (json['emiAmount'] is num) ? (json['emiAmount'] as num).toInt() : 0,
      tenureYears: (json['tenureYears'] is num) ? (json['tenureYears'] as num).toInt() : 30,
      interestRate: (json['interestRate'] is num) ? (json['interestRate'] as num).toDouble() : 7.5,
    );
  }
}
