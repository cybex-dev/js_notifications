# js_notifications — Internal Documentation

> Generated technical documentation for context-loading and referencing. Reflects the codebase at
> version **0.0.5** (branch `master`, July 2026).

`js_notifications` is a **web-only federated Flutter plugin** that extends the browser
[Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API) beyond what
`dart:html`/`package:web` expose directly — adding **action buttons, images, badges, data payloads,
require-interaction ("heads-up"), silent mode, renotify, RTL direction, vibration patterns** — by
routing all notifications through a dedicated **service worker** (`js_notifications-sw.js`).

| Doc | Contents |
|---|---|
| [overview.md](overview.md) | Purpose, inspiration, platform support, dependency graph, repo layout |
| [architecture.md](architecture.md) | Layering, class responsibilities, lifecycle, data flow diagrams |
| [api-reference.md](api-reference.md) | Every public class/method/stream with behavior notes |
| [service-worker-protocol.md](service-worker-protocol.md) | The JS service worker, message contracts in both directions |
| [example-app.md](example-app.md) | Example app walkthrough, patterns it demonstrates |
| [development-testing-ci.md](development-testing-ci.md) | Local dev, test limitations, CI/CD pipeline, release process |
| [known-issues-quirks.md](known-issues-quirks.md) | Bugs, inconsistencies, dead code, migration debt — **read before modifying** |

## 30-second context load

- **Entry point users should use:** `JsNotificationsPlatform.instance` (set to `JsNotificationsWeb` by Flutter web plugin registration).
- **Core flow:** Dart → `ServiceWorkerManager.postMessage()` → `ServiceWorker.postMessage(json)` → SW `showNotification()`; events come back SW → `clients.postMessage` → `ServiceWorkerContainer.onMessage` → typed broadcast streams (`actionStream`, `dismissStream`, `tapStream`).
- **Setup requirement:** consumers must copy `example/web/js_notifications-sw.js` into their app's `web/` folder — **the filename is hard-coded** (`lib/const/const.dart`).
- **Tap vs action:** an event with an empty/null `action` string is a *tap*; non-empty is an *action button click*. The SW cannot distinguish a body click from an action defined with `action: ""`.
- **State:** in-page cache `Map<String, JSNotification>` keyed by tag (or generated UUID) — only populated via `addNotification()`, *not* `showNotification()` (see known issues).
- **Migration debt:** the codebase mixes deprecated `dart:html` (service worker manager, NotificationsAPI) and modern `package:web` (options/vibrate types). Not WASM-ready.
