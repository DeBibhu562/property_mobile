class SavedSearchItem {
  const SavedSearchItem({
    required this.id,
    required this.name,
    required this.query,
    this.notifyEnabled = true,
  });

  final String id;
  final String name;
  final Map<String, dynamic> query;
  final bool notifyEnabled;

  factory SavedSearchItem.fromJson(Map<String, dynamic> json) {
    final queryRaw = json['query'];
    return SavedSearchItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Saved search',
      query: queryRaw is Map ? Map<String, dynamic>.from(queryRaw) : const {},
      notifyEnabled: json['notifyEnabled'] != false,
    );
  }

  String get subtitle {
    final q = query['q']?.toString();
    if (q != null && q.isNotEmpty) return q;
    final parts = <String>[
      if (query['scope'] != null) query['scope'].toString(),
      if (query['type'] != null) query['type'].toString(),
    ];
    return parts.isEmpty ? 'Tap to run this search' : parts.join(' · ');
  }
}
