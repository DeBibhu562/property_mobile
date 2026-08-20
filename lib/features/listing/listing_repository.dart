import 'package:dio/dio.dart';

import 'listing_models.dart';

class ListingRepository {
  ListingRepository(this._dio);

  final Dio _dio;

  Future<List<MyListing>> myListings() async {
    final res = await _dio.get<Map<String, dynamic>>('/listings');
    final root = res.data ?? const {};
    if (root['success'] != true || root['data'] is! List) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load listings',
      );
    }
    return (root['data'] as List)
        .whereType<Map>()
        .map((m) => MyListing.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<MyListing> createListing(Map<String, dynamic> payload) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/listings',
      data: payload,
    );
    final root = res.data ?? const {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to create listing',
      );
    }
    return MyListing.fromJson(root['data'] as Map<String, dynamic>);
  }

  Future<ListingVisibility> visibility(String listingId) async {
    final res = await _dio.get<Map<String, dynamic>>('/listings/$listingId/visibility');
    final root = res.data ?? const {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load visibility',
      );
    }
    return ListingVisibility.fromJson(root['data'] as Map<String, dynamic>);
  }
}
