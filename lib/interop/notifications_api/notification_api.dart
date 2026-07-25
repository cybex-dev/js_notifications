import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;
import 'package:simple_print/simple_print.dart';

class NotificationsAPI {
  static const tag = 'notifications_api';

  NotificationsAPI._();

  static final NotificationsAPI _instance = NotificationsAPI._();

  static NotificationsAPI get instance => _instance;

  /// Whether the browser exposes the Notification API.
  ///
  /// `package:web` has no equivalent of dart:html's `Notification.supported`;
  /// feature-detect the global instead.
  bool get isSupported => web.window.has('Notification');

  Future<bool> requestPermission() async {
    try {
      if (!isSupported) {
        printDebug("Notifications not supported", tag: tag);
        return false;
      }
      final perm = (await web.Notification.requestPermission().toDart).toDart;
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to request notifications permission", tag: tag);
      printDebug(e);
      return false;
    }
  }

  bool get hasPermission {
    try {
      final perm = web.Notification.permission;
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to query notifications permission", tag: tag);
      printDebug(e);
      return false;
    }
  }
}
