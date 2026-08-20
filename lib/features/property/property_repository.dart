import 'package:dio/dio.dart';

import 'property_models.dart';

class PropertyRepository {
  PropertyRepository(this._dio);

  final Dio _dio;

  static String _mapSort(String sortBy) {
    switch (sortBy) {
      case 'latest':
        return 'latest';
      case 'rank':
        return 'rank';
      default:
        return 'relevance';
    }
  }

  Future<PropertySearchPage> searchProperties({
    required int offset,
    required int limit,
    String? q,
    int? bhk,
    int? maxPrice,
    String? city,
    String? type,
    String? listingType,
    String sortBy = 'relevance',
  }) async {
    // Fold unsupported filters into `q` until listing search DTO exposes them.
    final queryParts = <String>[
      if (q != null && q.isNotEmpty) q,
      if (city != null && city.isNotEmpty) city,
      if (bhk != null) '$bhk BHK',
      if (maxPrice != null) 'under $maxPrice',
    ];
    final searchQ = queryParts.isEmpty ? null : queryParts.join(' ');

    final res = await _dio.get<Map<String, dynamic>>(
      '/search/listings',
      queryParameters: {
        'from': offset,
        'limit': limit,
        'sort': _mapSort(sortBy),
        if (searchQ != null) 'q': searchQ,
        if (type != null && type.isNotEmpty) 'type': type,
        if (listingType != null && listingType.isNotEmpty) 'listingType': listingType,
      },
    );
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Search failed',
      );
    }
    final data = root['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => PropertyItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] is num) ? (data['total'] as num).toInt() : int.tryParse('${data['total']}') ?? items.length;
    return PropertySearchPage(items: items, total: total);
  }

  Future<PropertyDetail> getProperty(String id) async {
    DioException? last;
    for (final path in ['/listings/$id', '/properties/$id']) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(path);
        final root = res.data ?? {};
        if (root['success'] == true && root['data'] is Map<String, dynamic>) {
          return PropertyDetail.fromJson(root['data'] as Map<String, dynamic>);
        }
        last = DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: root['error']?.toString() ?? 'Not found',
        );
      } on DioException catch (e) {
        last = e;
      }
    }
    throw last ??
        DioException(
          requestOptions: RequestOptions(path: '/listings/$id'),
          message: 'Not found',
        );
  }

  Future<Map<String, dynamic>> getPropertyQuality(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/properties/$id/quality');
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load property quality',
      );
    }
    return root['data'] as Map<String, dynamic>;
  }

  Future<List<PropertyItem>> similar(String id, {int limit = 8}) async {
    for (final path in ['/listings/$id/similar', '/properties/$id/similar']) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          path,
          queryParameters: {'limit': limit},
        );
        final root = res.data ?? {};
        if (root['success'] == true && root['data'] is Map<String, dynamic>) {
          final items = (root['data'] as Map)['items'] as List<dynamic>? ?? [];
          return items.map((e) => PropertyItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      } on DioException {
        continue;
      }
    }
    return const [];
  }
}
