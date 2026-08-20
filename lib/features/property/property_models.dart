import '../../core/flavor_config.dart';

String resolveImageUrl(String? url) {
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
  if (url.startsWith('/')) {
    return '$base$url';
  }
  return '$base/$url';
}

class PropertyItem {
  final String id;
  final String title;
  final int price;
  final int bhk;
  final String city;
  final String locality;
  final bool isFeatured;
  final bool isVerified;
  final int? builtUpArea;
  final bool isUnderConstruction;
  final String? imageUrl;
  final String? ownerName;
  final String? listingType;

  const PropertyItem({
    required this.id,
    required this.title,
    required this.price,
    required this.bhk,
    required this.city,
    this.locality = '',
    this.isFeatured = false,
    this.isVerified = false,
    this.builtUpArea,
    this.isUnderConstruction = false,
    this.imageUrl,
    this.ownerName,
    this.listingType,
  });

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final fromImages = images.isNotEmpty ? resolveImageUrl(images.first['url']?.toString()) : '';
    final fromField = resolveImageUrl(json['imageUrl']?.toString());
    final imageUrl = fromField.isNotEmpty
        ? fromField
        : (fromImages.isNotEmpty ? fromImages : null);
    final listingType = json['listingType']?.toString();
    final propertyType = json['type']?.toString();
    return PropertyItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : int.tryParse('${json['price']}') ?? 0,
      bhk: (json['bhk'] is num) ? (json['bhk'] as num).toInt() : int.tryParse('${json['bhk']}') ?? 0,
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      isFeatured: json['isFeatured'] == true || json['planTier'] == 'PLATINUM',
      isVerified: json['isVerified'] == true,
      builtUpArea: (json['builtUpArea'] is num) ? (json['builtUpArea'] as num).toInt() : null,
      isUnderConstruction: json['isUnderConstruction'] == true,
      imageUrl: imageUrl,
      ownerName: json['owner']?['name']?.toString() ??
          json['ownerName']?.toString() ??
          json['agencyName']?.toString(),
      listingType: listingType ?? propertyType,
    );
  }

  /// Compact headline for list cards (BHK for homes; area/type for commercial/PG).
  String get cardHeadline {
    final place = locality.isNotEmpty ? locality : city;
    final lt = (listingType ?? '').toUpperCase();
    if (lt == 'COMMERCIAL') {
      final area = builtUpArea != null && builtUpArea! > 0 ? '$builtUpArea sq.ft. ' : '';
      return '${area}Commercial${place.isNotEmpty ? ' · $place' : ''}';
    }
    if (lt == 'PG') {
      return 'PG / Co-living${place.isNotEmpty ? ' · $place' : ''}';
    }
    if (bhk > 0) {
      return '$bhk BHK${place.isNotEmpty ? ' $place' : ''}';
    }
    return title;
  }
}

class PropertyDetail {
  final String id;
  final String title;
  final String description;
  final int price;
  final int bhk;
  final String city;
  final String locality;
  final bool isVerified;
  final List<PropertyImage> images;
  final String ownerName;
  final String? ownerPhone;
  final String? ownerRole;

  // Key Highlights
  final int? bathrooms;
  final int? balconies;
  final int? builtUpArea;
  final int? plotArea;
  final int? totalFloors;
  final int? propertyFloor;
  final String? facing;
  final int? ageOfProperty;

  // Property type & status
  final String? listingType;        // RESIDENTIAL / COMMERCIAL / PG / PLOT / LAND
  final String? propertyType;       // SALE / RENT
  final String? propertySubType;    // Apartment / Villa / Builder Floor
  final bool isUnderConstruction;
  final String? furnishingStatus;   // derived from subType or custom

  // Price breakdown
  final int? maintenanceFees;
  final bool priceNegotiable;
  final bool allInclusivePrice;
  final bool taxExcluded;

  // Amenities & quality
  final List<String> amenities;
  final List<String> highlights;
  final double? lqsScore;
  final String? ownershipType;
  final int? parkingCount;
  final String? waterSupply;
  final bool powerBackup;
  final String? projectId;
  final String? projectSlug;
  final String? projectName;
  final String? agencyName;

  const PropertyDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.bhk,
    required this.city,
    required this.locality,
    required this.isVerified,
    required this.images,
    required this.ownerName,
    this.ownerPhone,
    this.ownerRole,
    this.bathrooms,
    this.balconies,
    this.builtUpArea,
    this.plotArea,
    this.totalFloors,
    this.propertyFloor,
    this.facing,
    this.ageOfProperty,
    this.listingType,
    this.propertyType,
    this.propertySubType,
    this.isUnderConstruction = false,
    this.furnishingStatus,
    this.maintenanceFees,
    this.priceNegotiable = false,
    this.allInclusivePrice = false,
    this.taxExcluded = false,
    this.amenities = const [],
    this.highlights = const [],
    this.lqsScore,
    this.ownershipType,
    this.parkingCount,
    this.waterSupply,
    this.powerBackup = false,
    this.projectId,
    this.projectSlug,
    this.projectName,
    this.agencyName,
  });

  factory PropertyDetail.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] as List<dynamic>? ?? [])
        .map((e) => PropertyImage.fromJson(e as Map<String, dynamic>))
        .toList();
    final structured = (json['listingAmenities'] as List<dynamic>? ?? [])
        .map((e) => (e as Map)['name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final amenitiesList = structured.isNotEmpty
        ? structured
        : (json['amenities'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty && !e.contains(':'))
            .toList();
    final highlights = (json['highlights'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final ownerUser = json['ownerUser'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>?;
    final agency = json['agency'] as Map<String, dynamic>?;
    final project = json['project'] as Map<String, dynamic>?;
    return PropertyDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : 0,
      bhk: (json['bhk'] is num) ? (json['bhk'] as num).toInt() : 0,
      city: json['city']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      images: imgs,
      ownerName: owner?['name']?.toString() ??
          ownerUser?['name']?.toString() ??
          agency?['name']?.toString() ??
          'Owner',
      ownerPhone: owner?['phone']?.toString() ?? ownerUser?['phone']?.toString(),
      ownerRole: owner?['role']?.toString() ?? ownerUser?['role']?.toString(),
      bathrooms: (json['bathrooms'] is num) ? (json['bathrooms'] as num).toInt() : null,
      balconies: (json['balconies'] is num) ? (json['balconies'] as num).toInt() : null,
      builtUpArea: (json['builtUpArea'] is num) ? (json['builtUpArea'] as num).toInt() : null,
      plotArea: (json['plotArea'] is num) ? (json['plotArea'] as num).toInt() : null,
      totalFloors: (json['totalFloors'] is num) ? (json['totalFloors'] as num).toInt() : null,
      propertyFloor: (json['propertyFloor'] is num) ? (json['propertyFloor'] as num).toInt() : null,
      facing: json['facing']?.toString(),
      ageOfProperty: (json['ageOfProperty'] is num) ? (json['ageOfProperty'] as num).toInt() : null,
      listingType: json['listingType']?.toString(),
      propertyType: json['type']?.toString(),
      propertySubType: json['propertySubType']?.toString(),
      isUnderConstruction: json['isUnderConstruction'] == true,
      furnishingStatus: json['furnishingStatus']?.toString(),
      maintenanceFees: (json['maintenanceFees'] is num) ? (json['maintenanceFees'] as num).toInt() : null,
      priceNegotiable: json['priceNegotiable'] == true,
      allInclusivePrice: json['allInclusivePrice'] == true,
      taxExcluded: json['taxExcluded'] == true,
      amenities: amenitiesList,
      highlights: highlights,
      lqsScore: (json['lqsScore'] is num) ? (json['lqsScore'] as num).toDouble() : null,
      ownershipType: json['ownershipType']?.toString(),
      parkingCount: (json['parkingCount'] is num) ? (json['parkingCount'] as num).toInt() : null,
      waterSupply: json['waterSupply']?.toString(),
      powerBackup: json['powerBackup'] == true,
      projectId: project?['id']?.toString(),
      projectSlug: project?['slug']?.toString(),
      projectName: project?['name']?.toString(),
      agencyName: agency?['name']?.toString(),
    );
  }
}

class PropertyImage {
  final String id;
  final String url;
  final String? section;
  final String? verificationStatus;

  const PropertyImage({
    required this.id,
    required this.url,
    this.section,
    this.verificationStatus,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id']?.toString() ?? '',
      url: resolveImageUrl(json['url']?.toString()),
      section: json['section']?.toString(),
      verificationStatus: json['verificationStatus']?.toString(),
    );
  }
}

class PropertySearchPage {
  final List<PropertyItem> items;
  final int total;

  const PropertySearchPage({required this.items, required this.total});
}
