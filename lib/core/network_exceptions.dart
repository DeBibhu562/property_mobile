import 'package:flutter/material.dart';

enum NetworkErrorCategory {
  noInternet,
  serverUnreachable,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  badRequest,
  unknown,
}

/// A structured, user-friendly representation of an API or network failure.
class AppNetworkException implements Exception {
  final NetworkErrorCategory category;
  final String title;
  final String message;
  final IconData icon;
  final int? statusCode;
  final String? technicalDetails;
  final dynamic originalError;

  const AppNetworkException({
    required this.category,
    required this.title,
    required this.message,
    required this.icon,
    this.statusCode,
    this.technicalDetails,
    this.originalError,
  });

  bool get isConnectionIssue =>
      category == NetworkErrorCategory.noInternet ||
      category == NetworkErrorCategory.serverUnreachable ||
      category == NetworkErrorCategory.timeout;

  @override
  String toString() => message;
}
