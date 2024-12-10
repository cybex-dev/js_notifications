import '../../core/serializable.dart';
import 'js_notification_options.dart';

/// Wrapper object for Notification sent to Service Worker
class JSNotification implements Serializable {

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/title
  final String title;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/showNotification#options
  final JSNotificationOptions? options;

  const JSNotification(this.title, [this.options]);

  JSNotification copyWithSelf(JSNotification other) {
    return JSNotification(
      other.title,
      other.options,
    );
  }

  JSNotification copyWith({String? title, JSNotificationOptions? options}) {
    return JSNotification(
      title ?? this.title,
      options ?? this.options,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "title": title,
    };
    if (options != null) {
      map["options"] = options!.toMap();
    }
    return map;
  }
}
