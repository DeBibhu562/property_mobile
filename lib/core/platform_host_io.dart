import 'dart:io' show Platform;

/// True when building for or running on Android dev host (10.0.2.2).
bool get isAndroidEmulatorHost {
  const hint = String.fromEnvironment('ANDROID_EMULATOR', defaultValue: '');
  if (hint == '0' || hint == 'false') return false;
  return Platform.isAndroid;
}

/// Whether this is a physical Android device (not web/desktop).
bool get isAndroidDevice => Platform.isAndroid;
