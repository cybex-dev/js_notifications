/// Filename of the service worker script.
const String jsNotificationsSwJs = "js_notifications-sw.js";

/// Base-href-relative path where Flutter serves the service worker script
/// bundled with this package as an asset (declared in this package's
/// pubspec.yaml). Deployed automatically with every consuming app — no manual
/// copying required.
const String bundledSwAssetPath =
    "assets/packages/js_notifications/assets/$jsNotificationsSwJs";

/// Marker used to distinguish the bundled service worker registration from a
/// legacy (manually copied) registration when both script URLs end in
/// [jsNotificationsSwJs].
const String bundledSwAssetDirMarker = "assets/packages/js_notifications/";

/// Scope used by legacy registrations, where the service worker was manually
/// copied to the app's web root. Retained for migration/unregistration of old
/// registrations. The bundled service worker uses its default scope (the
/// asset directory) — scope is irrelevant to this plugin as the worker never
/// controls pages; notifications hang off the registration itself.
const String defaultScope = "/js_notifications/";
