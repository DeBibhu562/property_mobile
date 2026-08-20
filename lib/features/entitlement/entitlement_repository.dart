import 'package:dio/dio.dart';

import 'entitlement_models.dart';

class EntitlementRepository {
  EntitlementRepository(this._dio);

  final Dio _dio;

  Future<MeEntitlements> getMyEntitlements() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/entitlements');
    final root = res.data ?? const {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load entitlements',
      );
    }
    return MeEntitlements.fromJson(root['data'] as Map<String, dynamic>);
  }
}
