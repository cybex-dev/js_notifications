import 'package:flutter_test/flutter_test.dart';
import 'package:js_notifications/core/notification_action_result.dart';
import 'package:js_notifications/interop/interop.dart';
import 'package:js_notifications/js_notifications_web.dart';
import 'package:js_notifications/platform_interface/js_notifications_platform_interface.dart';
import 'package:js_notifications/method_channel/js_notifications_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web/src/dom/vibration.dart';

class MockJsNotificationsPlatform
    with MockPlatformInterfaceMixin
    implements JsNotificationsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> addNotification(JSNotification notification) {
    // TODO: implement addNotification
    throw UnimplementedError();
  }

  @override
  Future<void> clearNotifications() {
    // TODO: implement clearNotifications
    throw UnimplementedError();
  }

  @override
  Future<void> dismissNotification({required String id}) {
    // TODO: implement dismissNotification
    throw UnimplementedError();
  }

  @override
  Future<void> showNotification(String title,
      {List<JSNotificationAction>? actions,
      int? badge,
      String? body,
      Map<String, dynamic>? data,
      JSNotificationDirection? dir,
      String? icon,
      String? image,
      String? lang,
      bool? renotify,
      bool? requireInteraction,
      bool? silent,
      String? tag,
      int? timestamp,
      VibratePattern? vibrate}) {
    // TODO: implement showNotification
    throw UnimplementedError();
  }

  @override
  // TODO: implement hasPermissions
  bool get hasPermissions => throw UnimplementedError();

  @override
  // TODO: implement isSupported
  bool get isSupported => throw UnimplementedError();

  @override
  Future<bool> requestPermissions() {
    // TODO: implement requestPermissions
    throw UnimplementedError();
  }

  @override
  Future<void> sendAction(Map<String, dynamic> data, {String? id}) {
    // TODO: implement sendAction
    throw UnimplementedError();
  }

  @override
  // TODO: implement notificationClick
  Stream<NotificationActionResult> get actionStream =>
      throw UnimplementedError();

  @override
  // TODO: implement notificationClose
  Stream<NotificationActionResult> get dismissStream =>
      throw UnimplementedError();

  @override
  // TODO: implement notificationTap
  Stream<NotificationActionResult> get tapStream => throw UnimplementedError();

  @override
  set scopeUrl(String value) {
    // TODO: implement scopeUrl
  }

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  Future<List<JSNotification>> getAllNotifications() {
    // TODO: implement getAllNotifications
    throw UnimplementedError();
  }

  @override
  Future<JSNotification?> getNotification(String tag) {
    // TODO: implement getNotification
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getNotificationTags() {
    // TODO: implement getNotificationTags
    throw UnimplementedError();
  }
}

void main() {
  final JsNotificationsPlatform initialPlatform =
      JsNotificationsPlatform.instance;

  test('$MethodChannelJsNotifications is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJsNotifications>());
  });

  test('getPlatformVersion', () async {
    JsNotificationsPlatform jsNotificationsPlugin =
        JsNotificationsPlatform.instance;
    MockJsNotificationsPlatform fakePlatform = MockJsNotificationsPlatform();
    JsNotificationsPlatform.instance = fakePlatform;

    expect(await jsNotificationsPlugin.getPlatformVersion(), '42');
  });
}
