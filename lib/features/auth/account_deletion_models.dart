class AccountDeletionPolicy {
  final String confirmation;
  final bool deletesImmediately;
  final String? webUrl;
  final String? supportEmail;
  final String? api;
  final List<String> removes;
  final List<String> retains;

  const AccountDeletionPolicy({
    this.confirmation = 'DELETE',
    this.deletesImmediately = true,
    this.webUrl,
    this.supportEmail,
    this.api,
    this.removes = const [],
    this.retains = const [],
  });

  factory AccountDeletionPolicy.fromJson(Map<String, dynamic> json) {
    final rawRemoves = json['removes'];
    final rawRetains = json['retains'];

    return AccountDeletionPolicy(
      confirmation: (json['confirmation']?.toString().trim().isNotEmpty == true)
          ? json['confirmation'].toString().trim()
          : 'DELETE',
      deletesImmediately: json['deletesImmediately'] != false,
      webUrl: json['webUrl']?.toString(),
      supportEmail: json['supportEmail']?.toString() ?? 'support@propertydilado.com',
      api: json['api']?.toString(),
      removes: rawRemoves is List
          ? rawRemoves.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      retains: rawRetains is List
          ? rawRetains.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'confirmation': confirmation,
        'deletesImmediately': deletesImmediately,
        'webUrl': webUrl,
        'supportEmail': supportEmail,
        'api': api,
        'removes': removes,
        'retains': retains,
      };
}

class AccountDeletionResult {
  final bool deleted;
  final String? deletedAt;
  final int? listingsWithdrawn;

  const AccountDeletionResult({
    required this.deleted,
    this.deletedAt,
    this.listingsWithdrawn,
  });

  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) {
    final withdrawnRaw = json['listingsWithdrawn'];
    return AccountDeletionResult(
      deleted: json['deleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      listingsWithdrawn: withdrawnRaw is num ? withdrawnRaw.toInt() : null,
    );
  }
}
