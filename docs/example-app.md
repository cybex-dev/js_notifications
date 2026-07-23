# Example App Walkthrough

Location: `example/` — a Flutter web app doubling as the demo & the deployment target for
Firebase Hosting (project `js-notifications-web`, see [development-testing-ci.md](development-testing-ci.md)).

Extra dependency: `stop_watch_timer ^3.2.1` (drives the live "timer notification" demo).

## What it demonstrates (`example/lib/main.dart`)

A single `StatefulWidget` (`MyApp`) with buttons exercising every plugin feature. Uses
`JsNotificationsPlatform.instance` directly and `dart:html` for `window.open`.

### 1. Basic notifications
- **Test Notification** button → `showNotification("Test Notification", tag: "test")`.
- **Dismiss Test Notification** → `dismissNotification(id: "test")` — shows tag-based dismissal.

### 2. Data notifications
- **Data Notification** → notification with a `data` map containing strings, ints, bools, doubles,
  lists, and nested maps — verifies arbitrary JSON round-trips through the SW and comes back on
  events. Dismissing it triggers a follow-up notification from `dismissStream`.

### 3. Interactive, chained conversations (actionStream routing)
- **"Expect the unexpected"** (Spanish Inquisition) — remote HTTPS icon, 2 actions
  (`dismiss` / `unexpected`), `requireInteraction: true`. Clicking `unexpected` sends a follow-up;
  clicking `dismiss` while `tag == "inquisition"` sends a different follow-up (shows action + tag
  combination handling).
- **Star Wars** flow — a multi-step notification conversation: `grievous` →
  (`general_kenobi` action) → `grievous_2` → (`kill_him`/`watch_star_wars`) → follow-ups with tag
  `star_wars_channel` / `rick_roll`. The `default` case of the action switch inspects `event.tag`
  and opens YouTube URLs via `window.open` — demonstrating **tap/uncategorized action → open URL**.
- Dismissing `grievous` triggers a "disappointment" notification via `dismissStream` (dismiss
  handling per tag).

### 4. Live-updating "timer" notification (the flagship pattern)
Stopwatch controls (play/pause/stop buttons + notification action buttons):

- Every second tick re-issues `showNotification("Timer", tag: "stopwatch", …)` with the elapsed
  time as `body` — **same tag ⇒ in-place replacement**, giving a continuously updating
  notification (the call-timer use case this package was built for).
- Action buttons are **state-dependent**: running ⇒ `Pause`/`Stop`; stopped ⇒ `Start`/`Dismiss`;
  plus a `Silence`/`Heads Up` toggle flipping `silent` and `requireInteraction` on subsequent
  updates.
- Notification actions drive app state symmetrically with in-app buttons (both call the same
  `_startTimerNotification`/`_pauseTimerNotification`/`_stopTimerNotification`).
- Uses `timestamp: DateTime.now().millisecondsSinceEpoch` and a local asset icon
  (`icons/call.png` from `example/web/icons/`).

### 5. Clear all
- **Clear All** → `clearNotifications()`.

## Web assets (`example/web/`)

- `js_notifications-sw.js` — **the canonical service worker consumers copy** (see
  [service-worker-protocol.md](service-worker-protocol.md)).
- `firebase-messaging-sw.js` — leftover FCM experiment (module SW initializing Firebase
  `twilio-voice-web` app); its registration in `index.html` is commented out. Not required.
- `index.html` — stock Flutter bootstrap; nothing plugin-specific (the plugin registers its SW
  itself at runtime).
- `manifest.json` — stock PWA manifest.
- `icons/` — standard Flutter icons plus `call.png` / `multiply.png` used by demos.

## Tests in the example

- `example/integration_test/plugin_integration_test.dart` — single `getPlatformVersion` smoke test
  (asserts non-empty user agent).
- `example/test/widget_test.dart` — stock scaffold test (not meaningful).

## Patterns worth reusing

1. **Tag-replacement live updates** (timer) — re-show with same tag rather than dismiss+show.
2. **State machines via actions** — switch on `event.action` in one central `actionStream`
   listener; use constants for tags/action ids.
3. **Tag-scoped dismiss handling** — switch on `event.tag` in `dismissStream`.
4. **Conditional action sets** — build the `actions` list from current app state with collection-if.
