/// Mirrors the API's `Listing` row as returned by `GET /listings`.
class MyListing {
  MyListing({
    required this.id,
    required this.title,
    required this.status,
    this.rankScore,
    this.rankScoreUpdatedAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final double? rankScore;
  final DateTime? rankScoreUpdatedAt;
  final DateTime updatedAt;

  factory MyListing.fromJson(Map<String, dynamic> json) {
    return MyListing(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      status: json['status']?.toString() ?? 'ACTIVE',
      rankScore: _readDouble(json['rankScore']),
      rankScoreUpdatedAt: _readDate(json['rankScoreUpdatedAt']),
      updatedAt: _readDate(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

/// Mirrors `GET /listings/:id/visibility`.
class ListingVisibility {
  ListingVisibility({
    required this.listingId,
    required this.rank,
    required this.impressions,
    required this.windowDays,
    required this.freshness,
    required this.computedAt,
  });

  final String listingId;
  final RankSummary rank;
  final ImpressionSummary impressions;
  final int windowDays;
  final VisibilityFreshness freshness;
  final DateTime computedAt;

  factory ListingVisibility.fromJson(Map<String, dynamic> json) {
    final rankRaw = (json['rank'] as Map?)?.cast<String, dynamic>() ?? const {};
    final imprRaw = (json['impressions'] as Map?)?.cast<String, dynamic>() ?? const {};
    final freshRaw = (json['freshness'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ListingVisibility(
      listingId: json['listingId']?.toString() ?? '',
      rank: RankSummary.fromJson(rankRaw),
      impressions: ImpressionSummary.fromJson(imprRaw),
      windowDays: _readInt(json['windowDays']) ?? 30,
      freshness: VisibilityFreshness.fromJson(freshRaw),
      computedAt: _readDate(json['computedAt']) ?? DateTime.now(),
    );
  }
}

class RankSummary {
  RankSummary({required this.score, required this.band, this.updatedAt});
  final double? score;
  /// One of `unscored | low | fair | good | high`.
  final String band;
  final DateTime? updatedAt;

  factory RankSummary.fromJson(Map<String, dynamic> json) {
    return RankSummary(
      score: _readDouble(json['score']),
      band: json['band']?.toString() ?? 'unscored',
      updatedAt: _readDate(json['updatedAt']),
    );
  }
}

class ImpressionSummary {
  ImpressionSummary({
    required this.total,
    required this.last7Days,
    required this.last30Days,
    required this.daily,
  });

  final int total;
  final int last7Days;
  final int last30Days;
  final List<DailyImpression> daily;

  factory ImpressionSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['daily'] as List?) ?? const [];
    return ImpressionSummary(
      total: _readInt(json['total']) ?? 0,
      last7Days: _readInt(json['last7Days']) ?? 0,
      last30Days: _readInt(json['last30Days']) ?? 0,
      daily: list
          .whereType<Map>()
          .map((m) => DailyImpression.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class DailyImpression {
  DailyImpression({required this.date, required this.count});
  /// UTC `YYYY-MM-DD`.
  final String date;
  final int count;

  factory DailyImpression.fromJson(Map<String, dynamic> json) {
    return DailyImpression(
      date: json['date']?.toString() ?? '',
      count: _readInt(json['count']) ?? 0,
    );
  }
}

class VisibilityFreshness {
  VisibilityFreshness({this.latestImpressionDate, required this.todayUtc});
  final String? latestImpressionDate;
  final String todayUtc;

  factory VisibilityFreshness.fromJson(Map<String, dynamic> json) {
    return VisibilityFreshness(
      latestImpressionDate: json['latestImpressionDate']?.toString(),
      todayUtc: json['todayUtc']?.toString() ?? '',
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _readDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
