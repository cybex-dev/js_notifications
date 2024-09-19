import 'package:web/web.dart';

import '../../core/serializable.dart';
import 'enums.dart';
import 'js_notification_action.dart';

/// Wrapper object for Notification Options
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/showNotification#options
class JSNotificationOptions implements Serializable {

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions
  final List<JSNotificationAction>? actions;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/badge
  final int? badge;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/body
  final String? body;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/data
  final Map<String, dynamic>? data;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/dir
  final JSNotificationDirection? dir;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/icon
  final String? icon;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/image
  final String? image;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/lang
  final String? lang;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/renotify
  final bool? renotify;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/requireInteraction
  final bool? requireInteraction;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/silent
  final bool? silent;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/tag
  final String? tag;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/timestamp
  final int? timestamp;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/vibrate
  final VibratePattern? vibrate;

  JSNotificationOptions({
    this.actions,
    this.badge,
    this.body,
    this.data,
    this.dir,
    this.icon,
    this.image,
    this.lang,
    this.renotify,
    this.requireInteraction,
    this.silent,
    this.tag,
    this.timestamp,
    this.vibrate,
  });

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};

    if (actions != null) {
      final list = (actions ?? []);
      map["actions"] = list.map((e) => e.toMap()).toList();
    }

    if (badge != null) {
      map["badge"] = badge;
    }

    if (body != null) {
      map["body"] = body;
    }

    if (data != null) {
      map["data"] = data;
    }

    if (dir != null) {
      map["dir"] = dir;
    }

    if (icon != null) {
      map["icon"] = icon;
    }

    if (image != null) {
      map["image"] = image;
    }

    if (lang != null) {
      map["lang"] = lang;
    }

    if (renotify != null) {
      map["renotify"] = renotify;
    }

    if (requireInteraction != null) {
      map["requireInteraction"] = requireInteraction;
    }

    if (silent != null) {
      map["silent"] = silent;
    }

    if (tag != null) {
      map["tag"] = tag;
    }

    if (timestamp != null) {
      map["timestamp"] = timestamp;
    }

    if (vibrate != null) {
      map["vibrate"] = vibrate;
    }

    return map;
  }
}
