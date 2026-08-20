import 'package:dio/dio.dart';

import 'project_models.dart';

class ProjectRepository {
  ProjectRepository(this._dio);
  final Dio _dio;

  Future<List<ProjectSummary>> list({int limit = 20, int offset = 0}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/projects',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load projects',
      );
    }
    final items = (root['data'] as Map)['items'] as List<dynamic>? ?? [];
    return items.map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectDetail> getBySlug(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/projects/$idOrSlug');
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Project not found',
      );
    }
    return ProjectDetail.fromJson(root['data'] as Map<String, dynamic>);
  }

  Future<List<ProjectSummary>> similar(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/projects/$idOrSlug/similar');
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      return const [];
    }
    final items = (root['data'] as Map)['items'] as List<dynamic>? ?? [];
    return items.map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PaymentPlanItem>> paymentPlans(String idOrSlug) async {
    final res = await _dio.get<Map<String, dynamic>>('/projects/$idOrSlug/payment-plans');
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      return const [];
    }
    final items = (root['data'] as Map)['items'] as List<dynamic>? ?? [];
    return items.map((e) => PaymentPlanItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DetailReview>> reviews({
    required String targetType,
    required String targetId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reviews',
      queryParameters: {'targetType': targetType, 'targetId': targetId, 'limit': 20},
    );
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      return const [];
    }
    final items = (root['data'] as Map)['items'] as List<dynamic>? ?? [];
    return items.map((e) => DetailReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addCompare({required String targetType, required String targetId}) async {
    await _dio.post('/compare/items', data: {
      'targetType': targetType,
      'targetId': targetId,
      'deviceKey': 'mobile-demo',
    });
  }
}
