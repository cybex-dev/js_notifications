# Architecture

## Layering (federated plugin pattern)

The package follows the standard Flutter *federated plugin* shape, though only the web endorsement
exists:

```
┌─────────────────────────────────────────────────────────────┐
│ App code                                                    │
│   uses JsNotificationsPlatform.instance                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│ JsNotificationsPlatform (abstract, PlatformInterface)       │
│   platform_interface/js_notifications_platform_interface.dart│
│   - static instance (token-verified setter)                 │
│   - defaults to MethodChannelJsNotifications                │
└───────┬─────────────────────────────────┬───────────────────┘
        │ (non-web default)               │ (web, via registerWith)
┌───────▼───────────────────┐   ┌─────────▼───────────────────┐
│ MethodChannelJsNotifications│  │ JsNotificationsWeb          │
│ MethodChannel('js_notifications')│ js_notifications_web.dart │
│ Only getPlatformVersion works; │ │  - in-page notification cache│
│ everything else throws         │ │  - 3 broadcast streams      │
│ UnimplementedError             │ │  - delegates to ↓           │
└────────────────────────────┘   └─────────┬───────────────────┘
                                           │
                                 ┌─────────▼───────────────────┐
                                 │ ServiceWorkerManager        │
                                 │ managers/service_worker_manager.dart│
                                 │  - registers /js_notifications-sw.js│
                                 │  - postMessage bridge (both ways)   │
                                 │  - permission gate per send         │
                                 │  - action-count platform warnings   │
                                 └─────────┬───────────────────┘
                                           │ postMessage JSON
                                 ┌─────────▼───────────────────┐
                                 │ js_notifications-sw.js (JS) │
                                 │  - showNotification          │
                                 │  - cancel / cancelAll        │
                                 │  - notificationclick/close → │
                                 │    clients.postMessage back  │
                                 └─────────────────────────────┘
```

Supporting layers:

- **interop/** — pure-Dart immutable wrapper models mirroring the Web Notification API shapes
  (`JSNotification`, `JSNotificationOptions`, `JSNotificationAction`, `JSNotificationDirection`),
  each `Serializable` (`toMap()`), plus the `NotificationsAPI` singleton wrapping
  `dart:html Notification` statics (`supported`, `permission`, `requestPermission()`).
- **core/** — transport envelope (`ServiceWorkerPayload`), command enum (`NotificationAction`:
  `cancelAll | cancel | notification | action`), inbound event model
  (`NotificationActionResult`), `Serializable` interface, user-agent platform sniffing.
- **const/** — `jsNotificationsSwJs = "js_notifications-sw.js"`, `defaultScope = "/js_notifications/"`,
  and `SWEvents` string constants for every SW/container event name.

## Object lifecycle & registration

1. Flutter web plugin registrant calls `JsNotificationsWeb.registerWith(Registrar)` at startup,
   which assigns `JsNotificationsPlatform.instance = JsNotificationsWeb._()`.
2. The private constructor:
   - `setAppTag("js_notifications")` (simple_print global tag)
   - `_setup()` → constructs `ServiceWorkerManager` with the three event callbacks and the static
     `_scopeUrl` (default `/js_notifications/`)
   - `_startEventListeners()` → subscribes to its own `dismissStream` to evict dismissed
     notifications from the `_notifications` cache (this also lazily instantiates the dismiss
     StreamController).
3. `ServiceWorkerManager` constructor grabs `NotificationsAPI.instance` and runs
   `_setupServiceWorker()` (async, fire-and-forget):
   - reads `html.window.navigator.serviceWorker` (bails with a debug log if absent)
   - attaches container-level listeners (`onMessage` stream + `controllerchange`, `statechange`,
     `error`, `install`, `activate`, `fetch` via addEventListener)
   - `register("/js_notifications-sw.js", {scope: '/js_notifications/', type: 'module'})`;
     on failure logs a "did you copy the file?" hint and rethrows
   - `_updateServiceWorker(registration.active ?? registration.installing)` — detaches listeners
     from any previous SW object and attaches a large set to the new one (`message`, `statechange`,
     `error`, `install`, `activate`, `fetch`, `push`, `pushsubscriptionchange`, `sync` — mostly
     debug-log no-ops; see known-issues about which of these can actually fire on a
     `ServiceWorker` object from the page).
4. On `controllerchange`/container `activate`, the active worker reference is refreshed from
   `serviceWorkerContainer.controller`.

## Outbound data flow (Dart → SW)

`showNotification(...)` / `addNotification(...)` / `dismissNotification` / `clearNotifications` /
`sendAction`:

1. Build a `ServiceWorkerPayload` — `{action: <enum name>, id?, notification?: {title, options?}, data?}`.
2. `ServiceWorkerManager._sendMessage`:
   - permission gate: if `Notification.permission != 'granted'`, `requestPermission()` first;
     abort (debug log) if denied.
   - if `_serviceWorker == null` → debug log "No service worker ready.", silently dropped.
   - else `serviceWorker.postMessage(payload.toMap())` (structured-clone of the Dart map).
3. SW `message` handler routes on `action`:
   - `notification` → `self.registration.showNotification(title, options)`
   - `cancel` → find by tag among `registration.getNotifications()`, `.close()`
   - `cancelAll` → close all
   - `action` → no-op placeholder

`postNotification` also runs `_checkActionCountLimitation` first: user-agent sniffing
(`Platform.macos/windows/linux/unknown`) and debug-warns about actions beyond per-platform limits
(mac 2, linux 2, windows 3, unknown 3). Warning only — nothing is stripped.

## Inbound data flow (SW → Dart)

1. Browser fires `notificationclick` / `notificationclose` in the SW.
2. SW builds `{action, type: 'click'|'close', data, tag}` from the event and broadcasts it to every
   window client (`clients.matchAll({type:'window', includeUncontrolled:true})` → `postMessage`).
3. Page-side, `ServiceWorkerContainer.onMessage` → `_onServiceWorkerContainerMessageEvent`:
   - parse into `NotificationActionResult(action, data, tag)`
   - `type == 'click'` and empty/null `action` → **tapStream** (body click)
   - `type == 'click'` with non-empty action → **actionStream** (button click)
   - `type == 'close'` → **dismissStream**
   - anything else → `throw Exception("Unknown NotificationActionResult type ...")`
4. `JsNotificationsWeb` forwards into lazily-created **broadcast** StreamControllers. The
   dismiss listener also evicts the tag from the `_notifications` cache.

Note that SW→page messages reach *all* window clients (every open tab of the app), and inbound
events are delivered regardless of whether the notification originated from this page/session.

## State model

- `JsNotificationsWeb._notifications: Map<String, JSNotification>` — an **in-page mirror**, not the
  browser's actual notification list. Keyed by `options.tag` or a fresh `Uuid().v4()` when untagged.
  Populated **only** by `addNotification()`; `showNotification()` bypasses it (see known-issues).
  Read by `getNotificationTags()/getNotification(tag)/getAllNotifications()`. Evicted on dismiss
  events. Lost on page reload (the actual OS notifications may persist).
- `_scopeUrl` is a **static** field with an instance setter; effectively fixed to the default
  because the manager is constructed during plugin registration before user code can set it
  (see known-issues).

## Design patterns in use

- PlatformInterface token verification (`plugin_platform_interface`) against rogue implementations.
- Singletons: `NotificationsAPI.instance`; `JsNotificationsWeb` is a de-facto singleton via
  `registerWith` (though the constructor isn't guarded; `protected()` factory exists for tests).
- Immutable model objects + `copyWith`/`copyWithSelf` + `toMap()` (`Serializable`).
- Broadcast streams for events; `Consumer<T> = void Function(T)` typedef callbacks between
  `ServiceWorkerManager` and `JsNotificationsWeb`.
- Debug-only logging through `simple_print`'s `printDebug` with per-class `tag`s.
