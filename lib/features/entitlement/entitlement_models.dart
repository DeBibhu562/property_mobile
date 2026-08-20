/// Mirrors `MeService.MeEntitlementsResponse` in the API. New limit keys land
/// in the API first (validated by JSON schema) and are surfaced here lazily,
/// so we keep `limits` as a raw map and pull strongly-typed accessors off it.
class MeEntitlements {
  MeEntitlements({
    required this.scope,
    required this.tier,
    required this.area,
    required this.planCode,
    required this.source,
    required this.limits,
    required this.usage,
    required this.upgradeUrl,
    required this.resolvedAt,
  });

  final EntitlementScope scope;
  final String? tier;
  final String? area;
  final String? planCode;
  final String source;
  final Map<String, dynamic> limits;
  final EntitlementUsage usage;
  final String upgradeUrl;
  final String resolvedAt;

  bool get isFree => tier == null;

  int? get maxActiveListings => _readInt(limits['maxActiveListings']);
  int? get maxImagesPerListing => _readInt(limits['maxImagesPerListing']);
  int? get featuredListingSlots => _readInt(limits['featuredListingSlots']);
  int? get maxLeadsPerMonth => _readInt(limits['maxLeadsPerMonth']);
  int? get maxSearchesPerDay => _readInt(limits['maxSearchesPerDay']);
  bool? get canExportLeads => _readBool(limits['canExportLeads']);
  bool? get prioritySupport => _readBool(limits['prioritySupport']);

  factory MeEntitlements.fromJson(Map<String, dynamic> json) {
    final scopeRaw = (json['scope'] as Map?)?.cast<String, dynamic>() ?? const {};
    final usageRaw = (json['usage'] as Map?)?.cast<String, dynamic>() ?? const {};
    final limitsRaw = (json['limits'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MeEntitlements(
      scope: EntitlementScope(
        agencyId: scopeRaw['agencyId']?.toString(),
        userId: scopeRaw['userId']?.toString(),
      ),
      tier: json['tier']?.toString(),
      area: json['area']?.toString(),
      planCode: json['planCode']?.toString(),
      source: json['source']?.toString() ?? 'default',
      limits: Map<String, dynamic>.from(limitsRaw),
      usage: EntitlementUsage(activeListings: _readInt(usageRaw['activeListings']) ?? 0),
      upgradeUrl: json['upgradeUrl']?.toString() ?? '',
      resolvedAt: json['resolvedAt']?.toString() ?? '',
    );
  }
}

class EntitlementScope {
  EntitlementScope({this.agencyId, this.userId});
  final String? agencyId;
  final String? userId;
}

class EntitlementUsage {
  EntitlementUsage({required this.activeListings});
  final int activeListings;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}
