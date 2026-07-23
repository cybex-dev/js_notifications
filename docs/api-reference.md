# API Reference

All public surface, with actual behavior notes (web implementation) rather than just signatures.

## Entry points

### `JsNotificationsPlatform` — `lib/platform_interface/js_notifications_platform_interface.dart`

The abstract contract and the recommended access point:

```dart
final plugin = JsNotificationsPlatform.instance;
```

`instance` defaults to `MethodChannelJsNotifications` (which throws for nearly everything) and is
replaced with `JsNotificationsWeb` by the web plugin registrant. The setter runs
`PlatformInterface.verifyToken`.

### `JsNotifications` — `lib/js_notifications.dart`

```dart
class JsNotifications extends MethodChannelJsNotifications {
  static JsNotificationsPlatform get instance => JsNotificationsPlatform.instance;
}
```

Only a static convenience alias. **Do not instantiate** — an instance is the unimplemented
method-channel version. Use the static `instance` getter (or `JsNotificationsPlatform.instance`
directly, as the README does).

## Methods (contract + web behavior)

| Member | Signature | Web behavior |
|---|---|---|
| `scopeUrl=` | `set scopeUrl(String)` | Sets a *static* field used for SW scope. Ineffective after registration (see known-issues #3). |
| `getPlatformVersion` | `Future<String?>` | Returns `window.navigator.userAgent`. |
| `isSupported` | `bool get` | `Notification.supported` (dart:html). |
| `hasPermissions` | `bool get` | `Notification.permission == 'granted'`, try/catch → false. |
| `requestPermissions` | `Future<bool>` | `Notification.requestPermission() == 'granted'`; false if unsupported or on error. |
| `showNotification` | `Future<void> showNotification(String title, {actions, badge, body, data, dir, icon, image, lang, renotify, requireInteraction, silent, tag, timestamp, vibrate})` | Builds `JSNotificationOptions` + `JSNotification`, posts to SW. **Does not insert into the local cache** (unlike `addNotification`). Same `tag` replaces the existing OS notification. |
| `addNotification` | `Future<void> addNotification(JSNotification)` | Caches under `options.tag ?? Uuid().v4()`, then posts to SW. Generated UUID is only the *cache key* — it is not written into the notification's tag (see known-issues #5). |
| `dismissNotification` | `Future<void> dismissNotification({required String id})` | Removes from cache (debug log if absent), sends `cancel` payload; SW closes the notification whose **tag** equals `id`. |
| `clearNotifications` | `Future<void>` | Clears cache, sends `cancelAll`; SW closes everything under the registration. |
| `sendAction` | `Future<void> sendAction(Map<String, dynamic> data, {String? id})` | Posts a payload with action `action`. The SW's handler for it is an explicit no-op — placeholder for app-custom SW logic. |
| `getNotificationTags` | `Future<List<String>>` | Keys of the in-page cache (async only for interface symmetry). |
| `getNotification` | `Future<JSNotification?> getNotification(String tag)` | Cache lookup. |
| `getAllNotifications` | `Future<List<JSNotification>>` | Cache values. Reflects only `addNotification`-created entries this page session. |
| `dispose` | `Future<void>` | Web: cancels the internal dismiss-stream subscription only (SW manager listeners are *not* detached — its own `dispose()` exists but is never called). |

## Streams

All lazily-created **broadcast** streams of `NotificationActionResult`:

| Stream | Fires when |
|---|---|
| `actionStream` | SW `click` event with a **non-empty** `action` — i.e. an action button was pressed. |
| `tapStream` | SW `click` event with empty/absent `action` — notification body tapped, **or** an action explicitly defined with `action: ""` (indistinguishable at the SW level). |
| `dismissStream` | SW `close` event — user dismissed it, or it was closed programmatically via `dismissNotification`/`clearNotifications`. |

Caveat: because controllers are created on first getter access and the forwarders use
`_xStream?.add(...)`, events arriving **before** the first access to a given stream getter are
silently dropped (dismissStream is safe — the plugin itself touches it at construction).

## Model classes (`lib/interop/`)

### `JSNotification`
Immutable `{String title, JSNotificationOptions? options}`. `copyWith`, `copyWithSelf`,
`toMap() → {title, options?}`.

### `JSNotificationOptions`
Immutable holder of all option fields; `toMap()` emits only non-null fields.
Fields: `actions: List<JSNotificationAction>?`, `badge: int?` (**typed wrong — should be a URL
string**, see known-issues #6), `body`, `data: Map<String,dynamic>?`, `dir: JSNotificationDirection?`
(serialized as `.name`), `icon`, `image`, `lang`, `renotify: bool?`, `requireInteraction: bool?`,
`silent: bool?`, `tag`, `timestamp: int?` (epoch ms), `vibrate: web.VibratePattern?`.

### `JSNotificationAction`
`{String action, String title, String? icon}` with factories:
- `JSNotificationAction.fromTitle(title, {transformToLowerCase = true})` → action = lowercased title
- `JSNotificationAction.fromAction(action, {capitalize = true})` → title = capitalized action
  (uses `String.capitalize()` from `lib/utils/utils.dart`)
- `JSNotificationAction.simpleWithIcon(title, icon)` → action == title

### `JSNotificationDirection`
`enum { auto, ltr, rtl }` — serialized via `.name` (0.0.4 fixed a bad `toString()` conversion).

### `NotificationActionResult` (`lib/core/`)
Inbound event: `{String? action, Map<String,dynamic>? data, String? tag}`.
`fromJson` is defensive (type-checks each key). Implements `==`/`hashCode` — note `data` is
compared with Map identity, so two results with equal-but-distinct maps are unequal.

### `ServiceWorkerPayload` (`lib/core/`)
Outbound envelope `{NotificationAction action, String? id, JSNotification? notification, Map? data}`
with factories `.cancel(id)` and `.cancelAll()`. `toMap()` emits `action` as enum `.name`.

### `NotificationAction`
`enum { cancelAll, cancel, notification, action }` — must stay in sync with the SW's
`notificationActions = ["cancel", "cancelAll", "notification", "action"]` list.

## Support classes

- **`NotificationsAPI`** (`lib/interop/notifications_api/notification_api.dart`) — singleton over
  `dart:html Notification` statics; all methods try/catch → false with debug logging.
- **`ServiceWorkerManager`** (`lib/managers/service_worker_manager.dart`) — see
  [architecture.md](architecture.md); public API: constructor, three `Consumer` callbacks,
  `postNotification`, `postAction`, `cancelNotification`, `cancelAllNotifications`, `postMessage`,
  `dispose`, platform-limit constants.
- **`platformFromUserAgent`** (`lib/core/user_agent.dart`) — `Platform { macos, windows, linux, unknown }`
  from substring checks on lowercased `navigator.userAgent` (`'mac'`, `'win'`, `'linux'` — in that
  order).
- **`SWEvents`** (`lib/const/sw_events.dart`) — string constants for SW/container event names plus
  the custom message `type`s `click` and `close`.
- **`StringExtension.capitalize()`** (`lib/utils/utils.dart`).
- **`Serializable`** (`lib/core/serializable.dart`) — `Map<String, dynamic> toMap()`.

## Usage snippets (canonical, from README/example)

```dart
final plugin = JsNotificationsPlatform.instance;

// permission
final ok = await plugin.requestPermissions();

// simple
plugin.showNotification("Test Notification", tag: "test");

// interactive, sticky
plugin.showNotification(
  "Oh no!",
  body: "…",
  tag: "inquisition",
  icon: "https://…/img.jpg",
  actions: [
    JSNotificationAction(action: "dismiss", title: "Whatever"),
    JSNotificationAction(action: "unexpected", title: "Didn't expect that"),
  ],
  requireInteraction: true,
);

// events
plugin.actionStream.listen((e) { /* e.action, e.tag, e.data */ });
plugin.tapStream.listen((e) { /* body taps */ });
plugin.dismissStream.listen((e) { /* closes */ });

// dismissal
plugin.dismissNotification(id: "test");
plugin.clearNotifications();
```
