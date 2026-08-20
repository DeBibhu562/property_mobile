import 'package:dio/dio.dart';

import 'admin_models.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<List<ModerationProperty>> moderationQueue({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/properties/moderation-queue',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final root = res.data ?? {};
    if (root['success'] != true) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load moderation queue',
      );
    }
    final data = root['data'];
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((m) => ModerationProperty.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> approveProperty(String propertyId) async {
    await _dio.patch<Map<String, dynamic>>(
      '/admin/property/$propertyId/status',
      data: {'status': 'APPROVED'},
    );
  }

  Future<void> rejectProperty(String propertyId) async {
    await _dio.patch<Map<String, dynamic>>(
      '/admin/property/$propertyId/status',
      data: {'status': 'REJECTED'},
    );
  }
}
