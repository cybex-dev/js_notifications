import 'dart:html';

import 'package:simple_print/simple_print.dart';

class NotificationsAPI {
  static const tag = 'notifications_api';

  NotificationsAPI._();

  static final NotificationsAPI _instance = NotificationsAPI._();

  static NotificationsAPI get instance => _instance;

  bool get isSupported => Notification.supported;

  Future<bool> requestPermission() async {
    try {
      if (!isSupported) {
        printDebug("Notifications not supported", tag: tag);
        return false;
      }
      final perm = await Notification.requestPermission();
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to request notifications permission", tag: tag);
      printDebug(e);
      return false;
    }
  }

  bool get hasPermission {
    try {
      final perm = Notification.permission;
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to query notifications permission", tag: tag);
      printDebug(e);
      return false;
    }
  }
}
