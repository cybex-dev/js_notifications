// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js_notifications/const/const.dart';
import 'package:js_notifications/interop/interop.dart' as interop;
import 'package:js_notifications/managers/service_worker_manager.dart';
import 'package:simple_print/simple_print.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

import 'core/core.dart';
import 'platform_interface/js_notifications_platform_interface.dart';

export 'interop/interop.dart'
    show
        JSNotification,
        JSNotificationOptions,
        JSNotificationAction,
        JSNotificationDirection;

/// A web implementation of the JsNotificationsPlatform of the JsNotifications plugin.
class JsNotificationsWeb extends JsNotificationsPlatform {
  final Map<String, interop.JSNotification> _notifications = {};
  late StreamSubscription<NotificationActionResult> _dismissSubscription;

  late final ServiceWorkerManager serviceWorkerManager;
  late final interop.NotificationsAPI notificationsAPI;

  StreamController<NotificationActionResult>? _dismissStream;
  StreamController<NotificationActionResult>? _actionStream;
  StreamController<NotificationActionResult>? _tapStream;

  static String _scopeUrl = defaultScope;

  /// Constructs a JsNotificationsWeb
  JsNotificationsWeb._() {
    setAppTag("js_notifications");
    _setup();
    _startEventListeners();
  }

  @visibleForTesting
  factory JsNotificationsWeb.protected() => JsNotificationsWeb._();

  static void registerWith(Registrar registrar) {
    JsNotificationsPlatform.instance = JsNotificationsWeb._();
  }

  void _setup() {
    serviceWorkerManager = ServiceWorkerManager(
      onNotificationTap: _onNotificationTap,
      onNotificationAction: _onNotificationAction,
      onNotificationDismiss: _onNotificationDismiss,
      scopeUrl: _scopeUrl,
    );
  }

  void _startEventListeners() {
    _dismissSubscription = dismissStream.listen((event) {
      _notifications.remove(event.tag);
    });
  }

  void _onNotificationTap(NotificationActionResult e) {
    _tapStream?.add(e);
  }

  void _onNotificationAction(NotificationActionResult e) {
    _actionStream?.add(e);
  }

  void _onNotificationDismiss(NotificationActionResult e) {
    _dismissStream?.add(e);
  }

  @override
  set scopeUrl(String value) {
    _scopeUrl = value;
  }

  @override
  Future<void> addNotification(interop.JSNotification notification) {
    final id = notification.options?.tag ?? const Uuid().v4();
    _addNotification(id, notification);
    return serviceWorkerManager.postNotification(notification);
  }

  @override
  Future<void> clearNotifications() {
    _notifications.clear();
    return serviceWorkerManager.cancelAllNotifications();
  }

  /// Dismiss notification with ID
  @override
  Future<void> dismissNotification({required String id}) {
    final notification = _notifications.remove(id);
    if (notification == null) {
      printDebug('Notification with id $id not found');
    }
    return serviceWorkerManager.cancelNotification(id);
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  bool get hasPermissions => notificationsAPI.hasPermission;

  @override
  bool get isSupported => notificationsAPI.isSupported;

  @override
  Future<bool> requestPermissions() {
    return notificationsAPI.requestPermission();
  }

  @override
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
  }) {
    final options = interop.JSNotificationOptions(
      actions: actions,
      badge: badge,
      body: body,
      data: data,
      dir: dir,
      icon: icon,
      image: image,
      lang: lang,
      renotify: renotify,
      requireInteraction: requireInteraction,
      silent: silent,
      tag: tag,
      timestamp: timestamp,
      vibrate: vibrate,
    );
    final notification = interop.JSNotification(title, options);
    return serviceWorkerManager.postNotification(notification);
  }

  @override
  Future<void> sendAction(Map<String, dynamic> data, {String? id}) {
    return serviceWorkerManager.postAction(
      action: NotificationAction.action,
      data: data,
      id: id,
    );
  }

  @override
  Stream<NotificationActionResult> get actionStream {
    _actionStream ??= StreamController<NotificationActionResult>.broadcast();
    return _actionStream!.stream;
  }

  @override
  Stream<NotificationActionResult> get dismissStream {
    _dismissStream ??= StreamController<NotificationActionResult>.broadcast();
    return _dismissStream!.stream;
  }

  @override
  Stream<NotificationActionResult> get tapStream {
    _tapStream ??= StreamController<NotificationActionResult>.broadcast();
    return _tapStream!.stream;
  }

  @override
  Future<List<String>> getNotificationTags() async {
    return _notifications.keys.toList();
  }

  @override
  Future<interop.JSNotification?> getNotification(String tag) async {
    return _notifications[tag];
  }

  @override
  Future<List<interop.JSNotification>> getAllNotifications() async {
    return _notifications.values.toList();
  }

  void _addNotification(String id, interop.JSNotification notification) {
    _notifications[id] = notification;
  }

  @override
  Future<void> dispose() async {
    await _dismissSubscription.cancel();
  }
}
