import 'package:dio/dio.dart';

import 'lead_models.dart';

class LeadRepository {
  LeadRepository(this._dio);

  final Dio _dio;

  Future<String> submitListingLead({
    required String listingId,
    required String message,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/listings/$listingId/leads',
      data: {
        'message': message,
      },
    );
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Could not send lead',
      );
    }
    final data = root['data'] as Map<String, dynamic>;
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      throw DioException(requestOptions: res.requestOptions, response: res, message: 'Invalid response');
    }
    return id;
  }

  Future<LeadPage> sellerLeads({int limit = 20, int offset = 0}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/leads/seller',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final root = res.data ?? {};
    if (root['success'] != true || root['data'] is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: root['error']?.toString() ?? 'Failed to load leads',
      );
    }
    return LeadPage.fromJson(root['data'] as Map<String, dynamic>);
  }

  Future<void> updateLeadStatus(String leadId, String status) async {
    await _dio.patch<Map<String, dynamic>>(
      '/leads/$leadId/status',
      data: {'status': status},
    );
  }

  Future<List<BuyerLead>> buyerLeads({int limit = 20, int offset = 0}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/leads/buyer',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final root = res.data ?? {};
      final data = root['data'] is Map<String, dynamic>
          ? root['data'] as Map<String, dynamic>
          : root;
      final rawItems = data['items'] as List<dynamic>? ?? [];
      return rawItems
          .whereType<Map>()
          .map((m) => BuyerLead.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
