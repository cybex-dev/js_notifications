import 'package:web/web.dart';

enum Platform {
  macos,
  windows,
  linux,
  unknown,
}

Platform get platformFromUserAgent {
  final userAgent = window.navigator.userAgent.toLowerCase();
  if (userAgent.contains('mac')) {
    return Platform.macos;
  } else if (userAgent.contains('win')) {
    return Platform.windows;
  } else if (userAgent.contains('linux')) {
    return Platform.linux;
  } else {
    return Platform.unknown;
  }
}
