import 'package:web/web.dart' as web;
import 'dart:js_interop'; //For .toDart support on JSPromise
import 'package:simple_print/simple_print.dart';

class NotificationsAPI {
  static const tag = 'notifications_api';

  NotificationsAPI._();

  static final NotificationsAPI _instance = NotificationsAPI._();

  static NotificationsAPI get instance => _instance;

  //package:web/web.dart do not have the supported value as dart:html
  //https://api.dart.dev/dart-html/Notification/supported.html
  //If permission has any value, it is "supported"
  bool get isSupported => web.Notification.permission.isNotEmpty;

  Future<bool> requestPermission() async {
    try {
      if (!isSupported) {
        printDebug("Notifications not supported", tag: tag);
        return false;
      }
      final perm = await web.Notification.requestPermission().toDart;
      return (perm.toString() == "granted");
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

  String? get permission {
    try {
      return web.Notification.permission;
    } catch (e) {
      printDebug("Failed to query notifications permission", tag: tag);
      printDebug(e);
      return null;
    }
  }
}
