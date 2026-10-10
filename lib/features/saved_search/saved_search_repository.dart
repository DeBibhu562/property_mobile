import 'package:dio/dio.dart';

import 'saved_search_models.dart';

class SavedSearchRepository {
  SavedSearchRepository(this._dio);

  final Dio _dio;

  Future<List<SavedSearchItem>> listSavedSearches({CancelToken? cancelToken}) async {
    final res = await _dio.get<dynamic>(
      '/me/saved-searches',
      cancelToken: cancelToken,
    );
    final root = res.data;
    if (root is Map && root['success'] == true && root['data'] is List) {
      return (root['data'] as List)
          .whereType<Map>()
          .map((e) => SavedSearchItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      message: root is Map ? root['error']?.toString() ?? 'Failed to load saved searches' : 'Failed to load saved searches',
    );
  }
}
