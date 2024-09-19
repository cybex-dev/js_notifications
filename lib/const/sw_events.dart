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

  // Notification action events
  static const String click = "click";
  static const String close = "close";
}