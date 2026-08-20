import 'package:flutter/material.dart';

/// Global keys so Dio interceptors can navigate / show snackbars without BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();
