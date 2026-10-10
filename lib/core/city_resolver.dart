/// Maps UI city labels to API/DB city names used by search endpoints.
class CityResolver {
  CityResolver._();

  static const _delhiNcrFallbacks = ['New Delhi', 'Gurgaon', 'Noida'];

  /// Primary city param for a single API call.
  static String primary(String? city) {
    final trimmed = (city ?? 'New Delhi').trim();
    if (trimmed.isEmpty) return 'New Delhi';
    if (_isDelhiNcr(trimmed)) return 'New Delhi';
    return trimmed;
  }

  /// Ordered candidates when the UI shows a regional label (e.g. Delhi NCR).
  static List<String> candidates(String? city) {
    final trimmed = (city ?? 'New Delhi').trim();
    if (trimmed.isEmpty) return const ['New Delhi'];
    if (_isDelhiNcr(trimmed)) return _delhiNcrFallbacks;
    return [trimmed];
  }

  static bool _isDelhiNcr(String city) {
    final lower = city.toLowerCase();
    return lower == 'delhi ncr' ||
        lower == 'delhi-ncr' ||
        lower == 'ncr' ||
        lower.contains('delhi ncr');
  }
}
