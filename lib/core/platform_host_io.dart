import 'dart:io' show Platform;

/// Android emulator reaches the host machine via 10.0.2.2.
bool get isAndroidEmulatorHost => Platform.isAndroid;
