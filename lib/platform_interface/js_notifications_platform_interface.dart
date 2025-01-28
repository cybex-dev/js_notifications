import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:web/web.dart' as web;

import '../core/core.dart';
import '../interop/interop.dart' as interop;
import '../method_channel/js_notifications_method_channel.dart';

abstract class JsNotificationsPlatform extends PlatformInterface {
  /// Constructs a JsNotificationsPlatform.
  JsNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static JsNotificationsPlatform _instance = MethodChannelJsNotifications();

  /// The default instance of [JsNotificationsPlatform] to use.
  ///
  /// Defaults to [MethodChannelJsNotifications].
  static JsNotificationsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JsNotificationsPlatform] when
  /// they register themselves.
  static set instance(JsNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  set scopeUrl(String value);

  Future<String?> getPlatformVersion();

  /// Convenience method checking browser notification support,
  /// wrapper for dart's native JS notification [Notification.supported]
  bool get isSupported;

  /// Convenience method checking browser notification support,
  /// wrapper for Dart's native JS notification [Notification.permission]
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/permission_static
  bool get hasPermissions;

  /// Convenience method checking browser notification support,
  /// wrapper for Dart's native JS notification [Notification.requestPermission()].
  /// Returns [true] if response matches 'granted'.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission_static
  Future<bool> requestPermissions();

  /// Send notification with [interop.JSNotification] to service worker
  Future<void> addNotification(interop.JSNotification notification);

  /// Send notification with customizable parameters to service worker
  Future<void> showNotification(
    String title, {
    List<interop.JSNotificationAction>? actions,
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
    web.VibratePattern? vibrate,
  });

  /// Dismiss notification with ID
  Future<void> dismissNotification({required String id});

  /// Clear all notifications
  Future<void> clearNotifications();

  /// Send action to service worker
  Future<void> sendAction(Map<String, dynamic> data, {String? id});

  /// Get all notification tags
  Future<List<String>> getNotificationTags();

  /// Get notification by tag
  Future<interop.JSNotification?> getNotification(String tag);

  /// Get all notifications
  Future<List<interop.JSNotification>> getAllNotifications();

  /// Stream broadcasting notification click events with associated data & action
  Stream<NotificationActionResult> get actionStream;

  /// Stream broadcasting notification close events with associated data
  Stream<NotificationActionResult> get dismissStream;

  /// Stream broadcasting notification tap events with associated data
  Stream<NotificationActionResult> get tapStream;

  Future<void> dispose();
}
