# Known Issues, Quirks & Technical Debt

Observed during a full code review at v0.0.5. **Read before modifying the package.** Ordered
roughly by user impact. "Bug" = behaves contrary to its evident intent; "Quirk" = surprising but
arguably by design; "Debt" = works, but should be cleaned up.

## 1. Bug — `showNotification()` never populates the notification cache
`JsNotificationsWeb.showNotification` builds the `JSNotification` and posts it to the SW directly,
skipping `_addNotification`. Only `addNotification()` writes to the `_notifications` map. Result:
`getNotification`, `getAllNotifications`, `getNotificationTags` return nothing for notifications
created via the (primary, README-documented) `showNotification` path. The CHANGELOG 0.0.3 claim
"notification accessors ... via caching" only holds for `addNotification` users.
Fix direction: route both through a shared code path that caches by tag (and actually assigns the
generated tag — see #5).

## 2. Quirk — pre-listener events are dropped
Stream controllers are created lazily in the getters, and the internal forwarders use
`_actionStream?.add(...)` etc. If a click/tap event arrives before app code first touches
`actionStream`/`tapStream`, it is silently discarded. `dismissStream` is exempt only because the
plugin's own constructor subscribes to it. Apps should subscribe early (as the example does in
`initState`). Fix direction: instantiate all three controllers eagerly in the constructor.

## 3. Quirk/bug — `scopeUrl` setter is effectively dead
`_scopeUrl` is a *static* field consumed once when `ServiceWorkerManager` is constructed — which
happens inside the private constructor during plugin registration, i.e. before any user code runs.
Setting `JsNotificationsPlatform.instance.scopeUrl = ...` afterwards changes the static but nothing
re-registers the SW. There is also no way to change the SW *filename* (`js_notifications-sw.js`,
hard-coded in `lib/const/const.dart`).

## 4. Bug — instantiating `JsNotifications()` yields a broken object
`class JsNotifications extends MethodChannelJsNotifications` — a constructed instance throws
`UnimplementedError` for everything on web. It exists only for its static
`instance` alias. Should probably be a non-constructible facade (private constructor) or re-export.

## 5. Bug — generated UUID cache key doesn't match any real tag
`addNotification` with no `options.tag` caches under `Uuid().v4()` but posts the notification
*without* a tag. The SW's `cancelNotification` matches on `notification.tag`, so
`dismissNotification(id: <that uuid>)` can never close it; the dismiss-event eviction also won't
match (SW reports `tag: undefined`/empty). Untagged notifications are therefore unmanageable and
leak in the cache. Fix direction: write the generated tag into the options before posting
(README implies this was the intent: "provide a tag or one will be generated").

## 6. Bug — `badge` typed as `int?`
Per the Web API, `badge` is a **URL string** (monochrome badge image). Dart models/type it as
`int?` throughout (`JSNotificationOptions`, `showNotification` params). A numeric badge is passed
to `showNotification` options where browsers expect a string URL — at best ignored. (Not to be
confused with the Badging API `navigator.setAppBadge(int)`.)

## 7. Quirk — action-count constants disagree with their own warnings
`platformLimitMac = 2` while the macOS warning text says "only supports up to 3 actions";
`platformLimitLinux = 2` while the Linux text says "usually supports up to 3". README says macOS 2
(+auto "Settings") and Windows/Linux 3. Warnings are debug-only and nothing is truncated.
(Style note: the `Platform.windows` case has no explicit `break` — fine in Dart 3, where switch
statement cases implicitly break, but inconsistent with the neighboring cases.)

## 8. Bug (JS) — error-logging shadow in the SW
In `js_notifications-sw.js`:
```js
self.registration.showNotification(title, options).catch((error) => {
    error('Error showing notification', error);   // `error` is the caught value, not the log fn
});
```
The catch parameter shadows the `error()` helper — if `showNotification` ever rejects, this handler
itself throws `TypeError: error is not a function`. Rename the parameter (e.g. `err`).
Also `warn()` logs `message` as an array (`console.warn(tag, message)` without spread).

## 9. Debt — dead/no-op event listeners on the Dart side
`ServiceWorkerManager` attaches `install`, `activate`, `fetch`, `push`, `pushsubscriptionchange`,
`sync` listeners to the page-side `ServiceWorker` object and `install`/`activate`/`fetch`/
`statechange` to the container — none of these events dispatch on those objects (they fire inside
the SW's own global scope, or in the case of container events, don't exist). Only container
`message`, `controllerchange` and SW-object `statechange`/`error` matter. Harmless but noisy;
also `_onServiceWorkerPush` logs "Service worker state change" (copy-paste label).

## 10. Quirk — `_updateServiceWorker` from `controllerchange` can adopt the wrong SW
On `controllerchange`/container-`activate` the manager re-points `_serviceWorker` at
`container.controller` — but the page is typically controlled by **Flutter's own**
`flutter_service_worker.js` (scope `/`), not `js_notifications-sw.js` (scope `/js_notifications/`,
controls no pages). If a controller change fires (e.g. Flutter SW update), subsequent
`postMessage` calls go to the *Flutter* service worker, which ignores them — notifications stop
working until reload. In the common happy path nothing fires and the initially registered worker
(`registration.active ?? registration.installing`) keeps being used.
Related: if the SW is freshly `installing` at registration time, messages posted before activation
may be delivered to a not-yet-active worker.

## 11. Quirk — permission prompt as a side effect of sending
`_sendMessage` lazily calls `requestPermission()` on every post if not granted. Convenient, but
browsers require a user gesture for the prompt; sends from non-gesture contexts (e.g. the timer
tick) will auto-deny/ignore in modern Chrome. Apps should call `requestPermissions()` explicitly
up front (README does).

## 12. Debt — dart:html ↔ package:web split (WASM blocker)
`service_worker_manager.dart` and `notification_api.dart` (and `example/lib/main.dart`) use
deprecated **`dart:html`**; `js_notification_options.dart`, `js_notifications_web.dart`,
`user_agent.dart` use **`package:web`**. `dart:html` is deprecated and incompatible with
`dart2wasm`; full migration to `package:web` + `dart:js_interop` is the single biggest
modernization task. Note `VibratePattern` in the public API comes from `package:web` while the
mechanism sending it (`dart:html postMessage`) structured-clones the raw Dart map — the `vibrate`
value is passed through `toMap()` unconverted (a `JSAny` wrapper in a Dart map — verify
serialization if vibration ever matters; it's likely broken through structured clone).

## 13. Debt — `dispose()` incomplete & never invoked
`JsNotificationsWeb.dispose` cancels only the internal dismiss subscription; it neither closes the
three StreamControllers nor calls `serviceWorkerManager.dispose()` (which itself exists and
detaches everything). Nothing in the plugin lifecycle calls dispose on web (plugins live for the
page lifetime), so this is latent.

## 14. Losses by design (document to consumers)
- SW → page events are dropped when **no window client exists** (notification clicked after tab
  closed: the `warn` fires in SW console, app never learns). No queueing/`clients.openWindow`.
- The in-page cache resets on reload while OS notifications persist — cache ≠ truth; the SW-side
  `registration.getNotifications()` is the truth but is only used for cancel, never exposed to Dart.
- All open tabs receive every event (multi-tab duplication of `actionStream` handling).
- An action with `action: ""` is reported as a *tap*, not an action (SW cannot distinguish).

## 15. Misc small stuff
- SW log tag is `callkit_sw`; the SW's `log()` helper is commented out.
- `firebase-messaging-sw.js` + `.firebaserc`/Firebase config in the example are remnants of the
  Twilio-Voice origin; unrelated to plugin function (the web API key there is a public web config,
  standard for Firebase, but ideally shouldn't ship in this repo's example).
- `test/js_notifications_test.dart` imports `package:web/src/dom/vibration.dart` (private `src/`
  path).
- `NotificationActionResult.==` compares `data` maps by identity — equal payloads ≠ equal results.
- `ServiceWorkerManager` stores `_notificationApi` but `JsNotificationsWeb` also holds its own
  `notificationsAPI` reference (same singleton; fine, just redundant).
- README's "Creating a notification" snippet uses JS-style object syntax inside a Dart call
  (`{ body: 'Body', … }`) — not valid Dart; copy-pasters will hit compile errors. Also README
  installation snippet says `^0.0.3` while the package is at 0.0.5.
- `example/web/index.html` keeps the commented-out manual firebase SW registration block.
