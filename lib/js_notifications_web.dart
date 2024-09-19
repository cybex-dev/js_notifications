// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js_notifications/const/const.dart';
import 'package:js_notifications/interop/interop.dart' as interop;
import 'package:js_notifications/managers/service_worker_manager.dart';
import 'package:web/web.dart' as web;

import 'core/core.dart';
import 'platform_interface/js_notifications_platform_interface.dart';

/// A web implementation of the JsNotificationsPlatform of the JsNotifications plugin.
class JsNotificationsWeb extends JsNotificationsPlatform {
  late final ServiceWorkerManager serviceWorkerManager;
  late final interop.NotificationsAPI notificationsAPI;

  StreamController<NotificationActionResult>? _dismissStream;
  StreamController<NotificationActionResult>? _actionStream;

  static String _scopeUrl = defaultScope;

  /// Constructs a JsNotificationsWeb
  JsNotificationsWeb._() {
    _setup();
  }

  static void registerWith(Registrar registrar) {
    JsNotificationsPlatform.instance = JsNotificationsWeb._();
  }

  void _setup() {
    serviceWorkerManager = ServiceWorkerManager(
        onNotificationAction: _onNotificationAction,
        onNotificationDismiss: (t) => _onNotificationDismiss,
        scopeUrl: _scopeUrl);
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
    return serviceWorkerManager.postNotification(notification);
  }

  @override
  Future<void> clearNotifications() {
    return serviceWorkerManager.cancelAllNotifications();
  }

  @override
  Future<void> dismissNotification({required String id}) {
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
}
