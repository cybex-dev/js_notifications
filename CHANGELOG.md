## Next release

* **Zero-setup service worker**: `js_notifications-sw.js` now ships as a bundled Flutter asset of
  the package (deployed at `assets/packages/js_notifications/assets/`) and is registered
  automatically — manually copying the file into your app's `web/` folder is no longer required.
  Existing copied files can be deleted; legacy registrations are unregistered automatically on
  startup.
* Service worker URL now resolves against the document base URI, fixing deployments under a
  non-root `<base href>`.
* `ServiceWorkerManager` is now a singleton (`ServiceWorkerManager.instance`, or the factory
  constructor to assign event callbacks) — a page has one service worker registration, and the
  manager owns the listeners attached to it.
* Service worker setup moved out of the `ServiceWorkerManager` constructor into an explicit,
  idempotent `init()`. The plugin calls it automatically on registration and exposes
  `initialize()` (returns whether the worker registered) and `isInitialized`. Notifications
  posted before initialisation completes now wait for it instead of being dropped with
  "No service worker ready".
* Added `registerServiceWorker({url, scope})` — replace the bundled worker with a custom script
  (e.g. custom `sendAction` handling), register the bundled worker under a custom scope, or both.
  The `scopeUrl` setter now works (previously ineffective): it re-registers the current worker
  under the new scope. Note: scopes outside the worker script's directory require a
  `Service-Worker-Allowed` response header from the server.
* Fixed service worker script bugs: error-logger shadowing in the `showNotification` catch
  handler, `console.warn` argument spreading; renamed SW log tag `callkit_sw` →
  `js_notifications_sw`.
* **WebAssembly support**: full migration off deprecated `dart:html` to `package:web` +
  `dart:js_interop` — the package now compiles with `flutter build web --wasm`.
* **BREAKING**: `badge` is now `String?` — the URL of the monochrome badge image, per the Web
  API's `Notification.badge` (previously mistyped as `int?`, which browsers ignored; not to be
  confused with the numeric Badging API, `navigator.setAppBadge`).
* **BREAKING**: `vibrate` is now `List<int>?` (previously
  `web.VibratePattern?`); `package:web` types no longer appear in the public API.
* **BREAKING**: minimum Flutter version raised to 3.22 (stable WASM toolchain floor).
* Internal: service worker event wiring now uses `EventStreamProvider` subscriptions; removed
  ~10 dead no-op event listeners that never fired on page-side objects.
* Note: under the WASM runtime, integral JS numbers in notification `data` payloads may be
  delivered back to Dart as `double` — treat round-tripped numbers as `num`.

## 0.0.5

* Fix `NotificationAPI` late init
* Updated docs

## 0.0.4

* Fix `JsNotificationDirection`'s `toString()` conversion 
* Added `auto` to `JSNotificationDirection`

## 0.0.3+3

* Updated docs
* Fix linting

## 0.0.3+2

* Updated docs

* ## 0.0.3+1

* Updated docs

## 0.0.3

* Added notification accessors and notification getters (via caching)
* Fixed notification on tap stream not triggering

## 0.0.2

* Added notification tap stream
* Added factory constructors, helpers for `JSNotification`, `JSNotificationOptions` and `JSNotificationAction`

## 0.0.1

* Initial release
