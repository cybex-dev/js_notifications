import 'package:js_notifications/method_channel/js_notifications_method_channel.dart';
import 'package:js_notifications/platform_interface/js_notifications_platform_interface.dart';

class JsNotifications extends MethodChannelJsNotifications {
  static JsNotificationsPlatform get instance => JsNotificationsPlatform.instance;
}