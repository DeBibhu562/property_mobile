import 'platform_host_stub.dart'
    if (dart.library.io) 'platform_host_io.dart' as platform_host;

/// Build-time flavor: `flutter run --dart-define=FLAVOR=staging`
/// Optional API override: `--dart-define=API_BASE_URL=https://your-api`
///
/// Docker Flutter web: `--dart-define=API_BASE_URL=http://localhost:3000`
class FlavorConfig {
  FlavorConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const String _apiOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Prefer explicit [API_BASE_URL]. Otherwise:
  /// - Android emulator → `10.0.2.2` (host loopback)
  /// - iOS simulator / desktop / web → `127.0.0.1`
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) {
      return _apiOverride.replaceAll(RegExp(r'/+$'), '');
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

  static String _defaultHost() {
    const androidHint = String.fromEnvironment('ANDROID_EMULATOR', defaultValue: '');
    if (androidHint == '1' || platform_host.isAndroidEmulatorHost) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static bool get isDev => flavor == 'dev';
  static bool get isStaging => flavor == 'staging';
}
