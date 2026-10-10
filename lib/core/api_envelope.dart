import 'package:dio/dio.dart';

/// Unwrap `{ success: true, data: ... }` from NestJS responses.
T unwrapApiData<T>(
  Response<dynamic> res, {
  required T Function(Map<String, dynamic> data) parse,
}) {
  final root = res.data;
  if (root is! Map) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      message: 'Invalid response shape',
    );
  }
  if (root['success'] != true) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      message: root['error']?.toString() ?? 'Request failed',
    );
  }
  final data = root['data'];
  if (data is Map<String, dynamic>) {
    return parse(data);
  }
  if (data is List && T == List<dynamic>) {
    return data as T;
  }
  throw DioException(
    requestOptions: res.requestOptions,
    response: res,
    message: 'Missing data envelope',
  );
}

/// Best-effort unwrap; returns null when envelope is missing or unsuccessful.
Map<String, dynamic>? tryUnwrapData(dynamic root) {
  if (root is! Map) return null;
  if (root['success'] == true && root['data'] is Map) {
    return Map<String, dynamic>.from(root['data'] as Map);
  }
  if (root['data'] is Map) {
    return Map<String, dynamic>.from(root['data'] as Map);
  }
  if (root is Map<String, dynamic>) return root;
  return null;
}
