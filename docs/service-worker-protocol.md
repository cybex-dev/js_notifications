# Service Worker & Message Protocol

File: `example/web/js_notifications-sw.js` (consumers copy this into their own `web/`).
Registered by `ServiceWorkerManager` as `/js_notifications-sw.js` with
`{scope: '/js_notifications/', type: 'module'}` (scope constant: `lib/const/const.dart`).

Log tag inside the SW is `callkit_sw` (leftover from the original Twilio/CallKit project).

## Why a dedicated service worker

- `Notification` constructed from a page cannot carry `actions`; only
  `ServiceWorkerRegistration.showNotification()` can.
- `notificationclick`/`notificationclose` for SW-shown notifications fire **in the SW**, so events
  must be relayed back to the page(s) via `Client.postMessage`.
- A dedicated file + narrow scope (`/js_notifications/`) avoids clashing with
  `flutter_service_worker.js` (Flutter's own caching SW at root scope) or a
  `firebase-messaging-sw.js`.

## Outbound protocol (page → SW)

`ServiceWorker.postMessage` with a structured-cloned map (`ServiceWorkerPayload.toMap()`):

```jsonc
{
  "action": "notification" | "cancel" | "cancelAll" | "action",  // required, enum .name
  "id": "<tag>",                    // optional — used by cancel
  "notification": {                 // optional — used by notification
    "title": "…",
    "options": {                    // all keys optional, only non-null emitted
      "actions": [{"action": "…", "title": "…", "icon": "…?"}],
      "badge": 0,                   // NB: int in Dart, URL string per Web API — mismatch
      "body": "…",
      "data": { /* arbitrary */ },
      "dir": "auto|ltr|rtl",
      "icon": "url", "image": "url", "lang": "…",
      "renotify": true, "requireInteraction": true, "silent": true,
      "tag": "…", "timestamp": 1710000000000,
      "vibrate": [200, 100, 200]
    }
  },
  "data": { /* arbitrary side-channel, currently unused by SW */ }
}
```

SW `message` handler → `handleMessagePayload`:
- Unknown `action` → silently ignored (validated against `notificationActions` array).
- `notification` → `showNotification(title, options)`:
  - bails silently if `Notification.permission !== 'granted'`
  - `self.registration.showNotification(title, options)` with a `.catch` (which is buggy — see
    known-issues #8: the catch parameter shadows the `error` log helper).
- `cancel` → `getNotifications()`, find by `tag === id`, `.close()`; logs an error if no id given.
- `cancelAll` → close every notification of this registration.
- `action` → explicit no-op (`case "action": // do nothing`). Placeholder hook: apps can extend
  their copy of the SW to react to `sendAction()` payloads.

## Inbound protocol (SW → page)

On `notificationclick` / `notificationclose`, `_handleNotificationResponse` posts to **every**
window client (`clients.matchAll({type: "window", includeUncontrolled: true})`):

```jsonc
{
  "action": "<event.action>",   // "" for body clicks
  "type": "click" | "close",    // which event fired
  "data": { /* notification.data echoed back */ },
  "tag": "<notification.tag>"
}
```

If there are zero clients, it warns and drops the message (no queueing — events while no tab is
open are lost).

Page-side routing (`ServiceWorkerManager._onServiceWorkerContainerMessageEvent`):

| `type` | `action` | Routed to |
|---|---|---|
| `click` | empty / null | `tapStream` |
| `click` | non-empty | `actionStream` |
| `close` | (any) | `dismissStream` |
| other | — | throws `Exception("Unknown NotificationActionResult type …")` |

**Empty-action caveat** (documented in a comment in the manager): an action declared as
`{action: "", title: "Open Window"}` produces a click event indistinguishable from a body tap, so
it lands on `tapStream`. Always give actions non-empty ids.

Note the SW does **not** call `event.notification.close()` on click, does not focus/open a window
(`clients.openWindow`), and does not use `event.waitUntil()` around the async postMessage work —
the browser may in principle terminate the SW before delivery (works in practice; a hardening
opportunity).

## SW/browser event wiring on the Dart side

`SWEvents` (`lib/const/sw_events.dart`) enumerates:
- Container-only: `controllerchange`
- SW-object: `push`, `pushsubscriptionchange`, `sync`, `statechange`, `error`, `install`,
  `activate`, `fetch`, `message`
- Custom message types: `click`, `close`

`ServiceWorkerManager` attaches listeners for nearly all of these to both the container and the
active `ServiceWorker` object, but almost all handlers are `printDebug` no-ops. Several of these
events (`install`, `activate`, `fetch`, `push`, `sync`) only ever fire inside the SW's own global
scope, never on the page-side `ServiceWorker`/`ServiceWorkerContainer` objects — they're
effectively dead listeners (see known-issues #9). The functionally meaningful ones are:

- container `onMessage` → the entire inbound event pipeline
- container `controllerchange` / `activate` handlers → refresh `_serviceWorker` from
  `container.controller`
- SW-object `statechange` → debug visibility of install→activate transitions

## Scope & coexistence notes

- Scope `/js_notifications/` is a sub-scope of root; the SW file itself lives at `/` so the scope
  is legal (scope ⊆ max scope = script directory). It controls no real pages (nothing is served
  under `/js_notifications/`), which is fine — notifications hang off the *registration*, not a
  controlled page. Consequently `container.controller` for the app page is **not** this SW
  (the page is controlled by Flutter's own `flutter_service_worker.js`, if present, at scope `/`).
- `type: 'module'` registration though the SW uses no imports — harmless; matters only for
  browsers without module-SW support (old Firefox).
- The example also contains `firebase-messaging-sw.js` (Twilio-Voice Firebase config, module type,
  registration commented out in `index.html`) — a remnant of FCM push experiments, not part of the
  plugin's operation.
