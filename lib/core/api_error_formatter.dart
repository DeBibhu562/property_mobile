import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'network_exceptions.dart';

/// Centralized utility to format and translate any network or API error
/// into a user-friendly [AppNetworkException].
class ApiErrorFormatter {
  ApiErrorFormatter._();

  static AppNetworkException format(Object? error, {String? defaultTitle, String? defaultMessage}) {
    if (error is AppNetworkException) {
      return error;
    }

    if (error is DioException) {
      return _formatDioException(error, defaultTitle: defaultTitle, defaultMessage: defaultMessage);
    }

    if (error is SocketException) {
      return AppNetworkException(
        category: NetworkErrorCategory.serverUnreachable,
        title: 'Connection Refused',
        message: 'Unable to reach the backend server. Please verify your connection or check if the server is running.',
        icon: Icons.wifi_off_rounded,
        technicalDetails: 'SocketException: ${error.message} (OS Error: ${error.osError?.message ?? "unknown"}, port: ${error.port})',
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return AppNetworkException(
        category: NetworkErrorCategory.timeout,
        title: 'Connection Timed Out',
        message: 'The server took too long to respond. Please try again.',
        icon: Icons.timer_outlined,
        technicalDetails: 'TimeoutException: ${error.message}',
        originalError: error,
      );
    }

    if (error is FormatException) {
      return AppNetworkException(
        category: NetworkErrorCategory.badRequest,
        title: 'Invalid Data Format',
        message: 'Received an unexpected response format from the server.',
        icon: Icons.data_object_rounded,
        technicalDetails: 'FormatException: ${error.message}',
        originalError: error,
      );
    }

    final errStr = error?.toString() ?? '';
    if (errStr.contains('Connection refused') ||
        errStr.contains('SocketException') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('Network is unreachable')) {
      return AppNetworkException(
        category: NetworkErrorCategory.serverUnreachable,
        title: 'Server Unreachable',
        message: 'Unable to connect to the server. Please check your internet connection or try again.',
        icon: Icons.cloud_off_rounded,
        technicalDetails: errStr,
        originalError: error,
      );
    }

    return AppNetworkException(
      category: NetworkErrorCategory.unknown,
      title: defaultTitle ?? 'Something Went Wrong',
      message: defaultMessage ?? (errStr.isNotEmpty ? errStr : 'An unexpected error occurred. Please try again.'),
      icon: Icons.error_outline_rounded,
      technicalDetails: errStr,
      originalError: error,
    );
  }

  static AppNetworkException _formatDioException(
    DioException dioErr, {
    String? defaultTitle,
    String? defaultMessage,
  }) {
    final response = dioErr.response;
    final statusCode = response?.statusCode;
    final serverMessage = _extractServerErrorMessage(response?.data);
    final reqPath = dioErr.requestOptions.path;

    // 1. Connection / Network errors (connection refused, no route to host, DNS lookup failure)
    if (dioErr.type == DioExceptionType.connectionError ||
        dioErr.type == DioExceptionType.unknown && _isSocketOrConnectionError(dioErr.error)) {
      final isConnectionRefused = dioErr.message?.contains('Connection refused') == true ||
          dioErr.error?.toString().contains('Connection refused') == true;

      return AppNetworkException(
        category: NetworkErrorCategory.serverUnreachable,
        title: isConnectionRefused ? 'Cannot Reach Server' : 'No Internet Connection',
        message: isConnectionRefused
            ? 'Unable to connect to the backend server. Please verify your connection or ensure the API server is active.'
            : 'Please check your network connection and try again.',
        icon: isConnectionRefused ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
        statusCode: statusCode,
        technicalDetails: '${dioErr.type} on $reqPath: ${dioErr.message ?? dioErr.error}',
        originalError: dioErr,
      );
    }

    // 2. Timeouts
    if (dioErr.type == DioExceptionType.connectionTimeout ||
        dioErr.type == DioExceptionType.sendTimeout ||
        dioErr.type == DioExceptionType.receiveTimeout) {
      return AppNetworkException(
        category: NetworkErrorCategory.timeout,
        title: 'Request Timed Out',
        message: 'The server is taking longer than usual to respond. Please try again.',
        icon: Icons.timer_outlined,
        statusCode: statusCode,
        technicalDetails: '${dioErr.type} on $reqPath after timeout',
        originalError: dioErr,
      );
    }

    // 3. HTTP status code responses
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return AppNetworkException(
            category: NetworkErrorCategory.badRequest,
            title: 'Invalid Request',
            message: serverMessage ?? 'The request could not be processed. Please check your inputs and try again.',
            icon: Icons.info_outline_rounded,
            statusCode: statusCode,
            technicalDetails: 'HTTP 400 on $reqPath: $serverMessage',
            originalError: dioErr,
          );
        case 401:
          return AppNetworkException(
            category: NetworkErrorCategory.unauthorized,
            title: 'Session Expired',
            message: serverMessage ?? 'Your session has expired. Please sign in again to continue.',
            icon: Icons.lock_clock_outlined,
            statusCode: statusCode,
            technicalDetails: 'HTTP 401 Unauthorized on $reqPath',
            originalError: dioErr,
          );
        case 403:
          return AppNetworkException(
            category: NetworkErrorCategory.forbidden,
            title: 'Access Restricted',
            message: serverMessage ?? 'You do not have permission to perform this action.',
            icon: Icons.lock_outline_rounded,
            statusCode: statusCode,
            technicalDetails: 'HTTP 403 Forbidden on $reqPath',
            originalError: dioErr,
          );
        case 404:
          return AppNetworkException(
            category: NetworkErrorCategory.notFound,
            title: 'Not Found',
            message: serverMessage ?? 'The requested information could not be found.',
            icon: Icons.search_off_rounded,
            statusCode: statusCode,
            technicalDetails: 'HTTP 404 on $reqPath',
            originalError: dioErr,
          );
        case 429:
          return AppNetworkException(
            category: NetworkErrorCategory.badRequest,
            title: 'Too Many Requests',
            message: serverMessage ?? 'Too many requests. Please wait a moment and try again.',
            icon: Icons.speed_rounded,
            statusCode: statusCode,
            technicalDetails: 'HTTP 429 Rate Limit on $reqPath',
            originalError: dioErr,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return AppNetworkException(
            category: NetworkErrorCategory.serverError,
            title: 'Server Error',
            message: serverMessage ?? 'The server encountered an issue. Our team has been notified. Please try again shortly.',
            icon: Icons.dns_outlined,
            statusCode: statusCode,
            technicalDetails: 'HTTP $statusCode on $reqPath: $serverMessage',
            originalError: dioErr,
          );
      }
    }

    // 4. Request Cancelled
    if (dioErr.type == DioExceptionType.cancel) {
      return AppNetworkException(
        category: NetworkErrorCategory.unknown,
        title: 'Request Cancelled',
        message: 'The operation was cancelled.',
        icon: Icons.cancel_outlined,
        statusCode: statusCode,
        technicalDetails: 'Cancelled on $reqPath',
        originalError: dioErr,
      );
    }

    // Fallback
    return AppNetworkException(
      category: NetworkErrorCategory.unknown,
      title: defaultTitle ?? 'Unable to Load Data',
      message: serverMessage ?? defaultMessage ?? 'An unexpected error occurred while communicating with the server.',
      icon: Icons.error_outline_rounded,
      statusCode: statusCode,
      technicalDetails: 'DioException ($statusCode): ${dioErr.message}',
      originalError: dioErr,
    );
  }

  static bool _isSocketOrConnectionError(dynamic err) {
    if (err is SocketException) return true;
    final str = err?.toString() ?? '';
    return str.contains('SocketException') ||
        str.contains('Connection refused') ||
        str.contains('Network is unreachable') ||
        str.contains('Failed host lookup');
  }

  static String? _extractServerErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.trim().isNotEmpty) {
      // Avoid raw HTML error pages
      if (data.trim().startsWith('<')) return null;
      return data.trim();
    }
    if (data is Map) {
      final err = data['error'] ?? data['message'] ?? data['msg'];
      if (err is String && err.trim().isNotEmpty) return err.trim();
      if (err is List && err.isNotEmpty) {
        return err.map((e) => e.toString()).join(', ');
      }
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join(', ');
      }
    }
    return null;
  }
}
