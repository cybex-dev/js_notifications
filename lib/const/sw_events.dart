class SWEvents {
  // Service Worker Container Events
  static const String controllerchange = "controllerchange";

  // Service Worker Registration Events
  /// Fires on a [ServiceWorkerRegistration] when a new (byte-different)
  /// worker begins installing — the hook for detecting service worker updates.
  static const String updatefound = "updatefound";

  // Service Worker Container & Service Worker Events
  static const String message = "message";
  static const String statechange = "statechange";
  static const String error = "error";

  // Notification action events, see for more info: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#notification_events
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#click
  static const String click = "click";

  /// See: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API#close
  static const String close = "close";
}
