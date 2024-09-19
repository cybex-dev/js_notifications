import '../../core/serializable.dart';

/// Wrapper object for NotificationAction
class JSNotificationAction implements Serializable {

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#action
  final String action;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#title
  final String title;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#icon
  final String? icon;

  JSNotificationAction({required this.action, required this.title, this.icon});

  @override
  Map<String, dynamic> toMap() {
    final map = {
      "action": action,
      "title": title,
    };

    if (icon != null) {
      map['icon'] = icon!;
    }

    return map;
  }
}
