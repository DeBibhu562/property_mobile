import 'package:flutter/foundation.dart';

import 'platform_host_stub.dart'
    if (dart.library.io) 'platform_host_io.dart' as platform_host;

/// Build-time flavor: `flutter run --dart-define=FLAVOR=staging`
/// Optional API override: `--dart-define=API_BASE_URL=https://propertydilado.com/api`
///
/// Release builds default to production unless overridden.
class FlavorConfig {
  FlavorConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const String _apiOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String productionApiBaseUrl = 'https://propertydilado.com/api';

  static const String productionPublicOrigin = 'https://propertydilado.com';

  /// Prefer explicit [API_BASE_URL]. Release builds use production unless overridden.
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) {
      return _apiOverride.replaceAll(RegExp(r'/+$'), '');
    }
    if (kReleaseMode || flavor == 'prod' || flavor == 'production') {
      return productionApiBaseUrl;
    }
    final host = _defaultHost();
    switch (flavor) {
      case 'staging':
        return 'http://$host:4001';
      case 'dev':
      default:
        return 'http://$host:3000';
    }
  }

  /// Origin for relative image/asset URLs (no `/api` suffix).
  static String get publicOrigin {
    if (kReleaseMode || flavor == 'prod' || flavor == 'production') {
      return productionPublicOrigin;
    }
    final base = apiBaseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static String _defaultHost() {
    const androidHint = String.fromEnvironment('ANDROID_EMULATOR', defaultValue: '');
    if (androidHint == '1' || platform_host.isAndroidEmulatorHost) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static bool get isProd =>
      kReleaseMode || flavor == 'prod' || flavor == 'production' || apiBaseUrl == productionApiBaseUrl;
  static bool get isDev => !isProd && flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
}
