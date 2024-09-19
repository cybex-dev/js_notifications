import 'dart:html';

import 'package:js_notifications/utils/utils.dart';

class NotificationsAPI {
  static const String TAG = 'notifications_api';

  NotificationsAPI._();

  static final NotificationsAPI _instance = NotificationsAPI._();

  static NotificationsAPI get instance => _instance;

  bool get isSupported => Notification.supported;

  Future<bool> requestPermission() async {
    try {
      if(!isSupported) {
        printDebug("Notifications not supported", TAG);
        return false;
      }
      final perm = await Notification.requestPermission();
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to request notifications permission", TAG);
      printDebug(e);
      return false;
    }
  }

  bool get hasPermission {
    try {
      final perm = Notification.permission;
      return (perm == "granted");
    } catch (e) {
      printDebug("Failed to query notifications permission", TAG);
      printDebug(e);
      return false;
    }
  }
}