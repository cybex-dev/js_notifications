class SWEvents {
  // Service Worker Container Events Only
  static const String controllerchange = "controllerchange";

  // Service Worker Events Only
  static const String push = "push";
  static const String pushsubscriptionchange = "pushsubscriptionchange";
  static const String sync = "sync";

  // Service Worker Container & Service Worker Events
  static const String message = "message";
  static const String statechange = "statechange";
  static const String error = "error";
  static const String install = "install";
  static const String activate = "activate";
  static const String fetch = "fetch";

  // Notification action events, see for more info: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#notification_events
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#click
  static const String click = "click";

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#close
  static const String close = "close";
}