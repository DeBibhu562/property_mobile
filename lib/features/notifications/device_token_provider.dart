/// Source of the platform-native push token (FCM for Android/iOS, web push
/// endpoint for Web). The auth flow injects this via Riverpod so the registration
/// service stays decoupled from `firebase_messaging` — operators wire the real
/// implementation by:
///
///   1. Adding `firebase_messaging: ^15.x` to `apps/mobile/pubspec.yaml`.
///   2. Dropping `google-services.json` into `android/app/` and
///      `GoogleService-Info.plist` into `ios/Runner/`.
///   3. Calling `await Firebase.initializeApp(...)` in `main.dart`.
///   4. Replacing the provider binding in `core/providers.dart` with a
///      `FirebaseDeviceTokenProvider` that calls `FirebaseMessaging.instance
///      .getToken()` (and `getAPNSToken()` on iOS).
///
/// Until then `StubDeviceTokenProvider` returns null and the rest of the
/// registration pipeline simply no-ops cleanly — the app builds and runs
/// without any Firebase native config.

/// Server-side enum mirror. The `wireName` is what the API expects in JSON;
/// matches `apps/api/prisma/schema.prisma` `DevicePlatform`.
enum DevicePlatform {
  fcmAndroid('FCM_ANDROID'),
  fcmIos('FCM_IOS'),
  web('WEB');

  const DevicePlatform(this.wireName);

  final String wireName;
}

class DeviceTokenInfo {
  const DeviceTokenInfo({
    required this.token,
    required this.platform,
    this.appVersion,
  });

  /// FCM registration token / web-push endpoint identifier.
  final String token;
  final DevicePlatform platform;

  /// Optional client app version, e.g. `"1.4.2+87"`. Carried only for logs.
  final String? appVersion;
}

abstract class DeviceTokenProvider {
  /// Returns the current device's push token, or `null` when notifications
  /// aren't available (permission denied, no Firebase config, dev environment).
  ///
  /// MUST NOT throw — registration callers treat null and exceptions
  /// indistinguishably, but a non-throwing contract makes the call sites
  /// simpler and avoids accidental crashes during login.
  Future<DeviceTokenInfo?> currentToken();
}

/// Default binding when Firebase isn't configured. Always returns null so the
/// `DeviceRegistrationService` short-circuits — keeps the build green and the
/// auth flow functional in dev / CI / preview without Firebase setup.
class StubDeviceTokenProvider implements DeviceTokenProvider {
  const StubDeviceTokenProvider();

  @override
  Future<DeviceTokenInfo?> currentToken() async => null;
}
