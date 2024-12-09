import '../../core/serializable.dart';
import '../../utils/utils.dart';

/// Wrapper object for NotificationAction
class JSNotificationAction implements Serializable {
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#action
  final String action;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#title
  final String title;

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notification/actions#icon
  final String? icon;

  const JSNotificationAction({required this.action, required this.title, this.icon});

  factory JSNotificationAction.fromTitle(String title, {bool transformToLowerCase = true}) {
    final action = transformToLowerCase ? title.toLowerCase() : title;
    return JSNotificationAction(action: action, title: title);
  }

  factory JSNotificationAction.fromAction(String action, {bool capitalize = true}) {
    final title = capitalize ? action.capitalize() : action;
    return JSNotificationAction(action: action, title: title);
  }

  factory JSNotificationAction.simpleWithIcon(String title, String icon) =>
      JSNotificationAction(action: title, title: title, icon: icon);

  JSNotificationAction copyWithSelf(JSNotificationAction other) {
    return JSNotificationAction(
      action: other.action,
      title: other.title,
      icon: other.icon,
    );
  }

  JSNotificationAction copyWith({String? action, String? title, String? icon}) {
    return JSNotificationAction(
      action: action ?? this.action,
      title: title ?? this.title,
      icon: icon ?? this.icon,
    );
  }

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
