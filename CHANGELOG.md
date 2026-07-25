## Next release

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
