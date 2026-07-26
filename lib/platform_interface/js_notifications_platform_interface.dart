import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  /// Completes when the plugin's service worker has been registered and its
  /// event listeners attached.
  ///
  /// Initialisation starts automatically when the plugin registers, so
  /// awaiting this is optional — notifications posted beforehand are queued
  /// until it completes. Await it when you need to know whether notifications
  /// are actually available:
  ///
  /// ```dart
  /// if (await JsNotificationsPlatform.instance.initialize()) {
  ///   // service worker registered — notifications can be shown
  /// }
  /// ```
  ///
  /// Returns false when service workers are unsupported (an insecure context —
  /// neither https nor localhost — or an unsupported browser) or registration
  /// failed. Failures are logged, never thrown. Idempotent.
  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Whether the service worker is registered and ready. See [initialize].
  bool get isInitialized =>
      throw UnimplementedError('isInitialized has not been implemented.');

  /// Updates the scope the plugin's service worker is registered under by
  /// re-registering the currently registered worker script (bundled or
  /// custom) with [value] as its scope. Fire-and-forget — prefer
  /// [registerServiceWorker] to await completion, register a custom worker
  /// script, or both.
  ///
  /// Scope caveat: a scope outside the worker script's directory requires the
  /// server to send a `Service-Worker-Allowed` response header (always the
  /// case for scopes broader than `assets/packages/js_notifications/assets/`
  /// when using the bundled worker).
  set scopeUrl(String value) {
    throw UnimplementedError('scopeUrl has not been implemented.');
  }

  /// Re-registers the plugin's service worker with a custom [url] and/or
  /// [scope], replacing the automatically registered bundled worker.
  ///
  /// - [url]: script URL of a custom worker — e.g. a copy of
  ///   `js_notifications-sw.js` extended with app-specific message handling
  ///   (see [sendAction]). When null, the **bundled** worker asset is used —
  ///   pass only [scope] to keep the bundled worker but register it under a
  ///   custom scope:
  ///
  /// ```dart
  /// // bundled worker, custom scope
  /// await JsNotificationsPlatform.instance
  ///     .registerServiceWorker(scope: "/js_notifications/");
  ///
  /// // custom worker, default scope
  /// await JsNotificationsPlatform.instance
  ///     .registerServiceWorker(url: "/my_notifications-sw.js");
  /// ```
  ///
  /// - [scope]: registration scope. When null the browser default (the
  ///   script's directory) is used. A scope outside the script's directory
  ///   requires the server to send a `Service-Worker-Allowed` response
  ///   header — for the bundled asset (served from
  ///   `assets/packages/js_notifications/assets/`) any broader scope needs
  ///   that header configured on the hosting server.
  Future<void> registerServiceWorker({String? url, String? scope}) {
    throw UnimplementedError(
        'registerServiceWorker() has not been implemented.');
  }

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
    String? badge,
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
    List<int>? vibrate,
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
