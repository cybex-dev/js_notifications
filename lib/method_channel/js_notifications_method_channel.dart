import 'package:flutter/services.dart';
import 'package:js_notifications/core/notification_action_result.dart';
import 'package:web/web.dart';

import '../platform_interface/js_notifications_platform_interface.dart';
import '../interop/interop.dart' as interop;

/// An implementation of [JsNotificationsPlatform] that uses method channels.
class MethodChannelJsNotifications extends JsNotificationsPlatform {
  /// The method channel used to interact with the native platform.
  final methodChannel = const MethodChannel('js_notifications');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> addNotification(interop.JSNotification notification) {
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
  Future<void> showNotification(String title,
      {List<interop.JSNotificationAction>? actions,
      int? badge,
      String? body,
      Map<String, dynamic>? data,
      interop.JSNotificationDirection? dir,
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
  Future<void> sendAction(Map<String, dynamic> data, {String? id}) {
    // TODO: implement sendAction
    throw UnimplementedError();
  }

  @override
  Stream<NotificationActionResult> get actionStream =>
      throw UnimplementedError();

  @override
  Stream<NotificationActionResult> get dismissStream =>
      throw UnimplementedError();

  @override
  Stream<NotificationActionResult> get tapStream => throw UnimplementedError();

  @override
  set scopeUrl(String value) {
    // TODO: implement scopeUrl
  }

  @override
  Future<List<interop.JSNotification>> getAllNotifications() {
    // TODO: implement getAllNotifications
    throw UnimplementedError();
  }

  @override
  Future<interop.JSNotification?> getNotification(String tag) {
    // TODO: implement getNotification
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getNotificationTags() {
    // TODO: implement getNotificationTags
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    // TODO: implement dispose
    throw UnimplementedError();
  }
}
