# Overview

## What it is

`js_notifications` (pub: `js_notifications`, v0.0.5) is a Flutter **web-only plugin** providing an
extended wrapper over the browser Notifications API. Plain Dart web notifications
(`dart:html Notification` / `package:web`) only surface title, body and icon; this package unlocks
the full `ServiceWorkerRegistration.showNotification()` option set:

- **actions** (buttons with `action` id, `title`, optional `icon`)
- **image**, **badge**, **icon**
- **data** (arbitrary `Map<String, dynamic>` payload echoed back on events)
- **tag** (dedup/replace semantics; same tag replaces the previous notification)
- **requireInteraction** ("heads-up"/sticky notifications)
- **silent**, **renotify**, **lang**, **dir** (ltr/rtl/auto), **timestamp**, **vibrate**

The trick: notifications with actions can *only* be created from a service worker registration —
`new Notification(...)` throws for actions. Hence the package ships its own service worker
(`js_notifications-sw.js`) and does all show/close/event-handling through it.

## Why it exists (inspiration)

Built by Charles Dyason (`cybex-dev`) originally in the context of a Twilio Voice web project
(traces remain: the SW's log tag is `callkit_sw`, and the example folder contains a
`firebase-messaging-sw.js` pointing at a `twilio-voice-web` Firebase project). The generic need:
call-style interactive notifications (answer/decline buttons, ongoing-call timers) on Flutter web.

## Platform support

- **Web only.** `pubspec.yaml` declares `platforms: web:` with `pluginClass: JsNotificationsWeb`,
  `fileName: js_notifications_web.dart`. There is no Android/iOS/desktop implementation; the
  `MethodChannelJsNotifications` fallback throws `UnimplementedError` for everything except
  `getPlatformVersion`.
- OS-level rendering differences (documented in README with screenshots in `images/`):
  - **macOS**: max 2 actions, text-only, browser adds a "Settings" third item; icon not shown while
    hovering to reveal actions.
  - **Windows**: max 3 actions, fully customizable (Win10 toast).
  - **Linux**: usually max 3, depends on distro/DE.
  - Action overflow is *warned* about (via user-agent sniffing in `ServiceWorkerManager._checkActionCountLimitation`)
    but not truncated — the browser/OS silently drops extras.

## Dependencies

```
flutter, flutter_web_plugins (SDK)
web ^1.1.0                     # modern JS interop types (VibratePattern, window.navigator)
plugin_platform_interface ^2.1.8
uuid ^4.5.1                    # generated tags for untagged notifications (addNotification only)
simple_print ^0.0.1+2          # printDebug logging w/ app tag "js_notifications"
```

Dart SDK `>=3.4.0 <4.0.0`, Flutter `>=3.3.0`. Lints: `flutter_lints ^3.0.0` (stock
`package:flutter_lints/flutter.yaml`, no customizations).

## Repository layout

```
lib/
├── js_notifications.dart            # thin entry: class JsNotifications (see quirks)
├── js_notifications_web.dart        # JsNotificationsWeb — the real web implementation
├── platform_interface/
│   └── js_notifications_platform_interface.dart  # abstract JsNotificationsPlatform
├── method_channel/
│   └── js_notifications_method_channel.dart      # default (non-web) impl, ~all UnimplementedError
├── managers/
│   └── service_worker_manager.dart  # SW registration, event wiring, postMessage bridge
├── interop/
│   ├── interop.dart                 # barrel
│   ├── js_notification/             # JSNotification, JSNotificationOptions,
│   │                                #   JSNotificationAction, JSNotificationDirection
│   └── notifications_api/           # NotificationsAPI singleton (permission/support checks)
├── core/                            # Serializable, ServiceWorkerPayload,
│   │                                #   NotificationAction enum, NotificationActionResult,
│   └── user_agent.dart              # Platform enum from navigator.userAgent
├── const/
│   ├── const.dart                   # SW filename + default scope constants
│   └── sw_events.dart               # SWEvents string constants
└── utils/utils.dart                 # String.capitalize() extension

example/                             # full demo app (see example-app.md)
├── lib/main.dart
└── web/js_notifications-sw.js       # ← THE service worker consumers must copy
images/                              # README screenshots per OS
test/                                # minimal (see development-testing-ci.md)
.github/workflows/flutter-prod.yml   # CI: analyze + deploy example to Firebase Hosting
firebase.json / .firebaserc          # Firebase Hosting config for the example
NOTES.md                             # note on why tests can't run (SW required)
```

## Consumer setup (from README)

1. Add `js_notifications` to `pubspec.yaml`.
2. **Copy `js_notifications-sw.js` from the example into the app's `web/` directory** — the name
   must match exactly (`js_notifications-sw.js`); registration path is hard-coded as
   `/js_notifications-sw.js` with scope `/js_notifications/` and `type: 'module'`.
3. Use `JsNotificationsPlatform.instance` (do **not** construct `JsNotifications()` — see
   known-issues).
4. Call `requestPermissions()` before or rely on lazy permission request on first send.

## Version history (CHANGELOG condensed)

- **0.0.5** — fixed `NotificationsAPI` late-init bug; docs.
- **0.0.4** — fixed `JSNotificationDirection.toString()`; added `auto` direction.
- **0.0.3(+1..3)** — notification accessors/getters via in-page caching; fixed tap stream not firing; docs/linting.
- **0.0.2** — tap stream; factory helpers on `JSNotification*` classes.
- **0.0.1** — initial release.
