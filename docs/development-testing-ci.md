# Development, Testing & CI

## Local development

- Run the example: `cd example && flutter run -d chrome`. The plugin registers its SW automatically;
  Chrome DevTools → Application → Service Workers to inspect `js_notifications-sw.js`
  (scope `/js_notifications/`).
- Debug logging: all internal logging goes through `simple_print`'s `printDebug` with app tag
  `js_notifications` and per-class tags (`service_worker_manager`, `notifications_api`) — visible
  in debug builds only.
- SW iteration gotcha: browsers cache service workers. After editing `js_notifications-sw.js`, use
  DevTools "Update on reload" / "Unregister", or bump the file, otherwise the old worker keeps
  running (`registration.active ?? registration.installing` picks up whatever is there).
- Lints: stock `flutter_lints` v3 via `analysis_options.yaml`. Keep `flutter analyze` clean —
  CHANGELOG shows lint-fix releases; CI runs analyze as a gate.

## Testing (current state: minimal, mostly blocked)

From `NOTES.md`: tests requiring the plugin's real behavior can't run because **no service worker
is registered in the test environment** — `flutter test --platform chrome` runs against a page
without SW registration completing, so anything that touches `ServiceWorkerManager` breaks. The
author flags this as future work.

What exists:

- `test/js_notifications_test.dart`
  - asserts the default `JsNotificationsPlatform.instance` is `MethodChannelJsNotifications`
  - a `getPlatformVersion` test using a `MockJsNotificationsPlatform`
    (`MockPlatformInterfaceMixin`) — note it swaps in `JsNotificationsWeb.protected()` *after*
    capturing the instance, so it effectively tests the mock; the `protected()` factory exists for
    this test's benefit. Imports `package:web/src/dom/vibration.dart` directly (a `src/` import —
    fragile).
- `test/js_notifications_method_channel_test.dart` — sets up a mock method-channel handler; the
  actual assertions are commented out (an `addNotification`/`getNotification` round-trip draft).
- `example/integration_test/plugin_integration_test.dart` — `getPlatformVersion` non-empty check;
  can run on chrome via `flutter drive`/integration_test tooling.

Practical guidance for adding tests:
- Pure-model tests (serialization of `JSNotificationOptions.toMap()`, `NotificationActionResult.fromJson`,
  `ServiceWorkerPayload`, action factories, `capitalize()`, platform sniffing with injected UA)
  need no SW and are the low-hanging fruit — none exist today.
- `ServiceWorkerManager` would need the SW-container dependency injected/fakeable to be testable;
  today it reads `html.window.navigator.serviceWorker` directly in its constructor.

## CI/CD — `.github/workflows/flutter-prod.yml`

Trigger: push to **`prod`** branch (and manual `workflow_dispatch`). Flutter **3.27.4** stable,
cached via `subosito/flutter-action@v2`.

1. **build_and_test** job: checkout → `flutter pub get` → `flutter analyze` →
   ~~`flutter test --coverage`~~ **tests are skipped** (`echo "Ignoring tests for now."` — consistent
   with NOTES.md).
2. **deploy-example-web** job (needs #1): `flutter config --enable-web` →
   `cd example; flutter build web --release --target=lib/main.dart --output=build/web` → upload
   artifact `web-build` → deploy to **Firebase Hosting**, project `js-notifications-web`, live
   channel, via `FirebaseExtended/action-hosting-deploy@v0` with
   `secrets.FIREBASE_SERVICE_ACCOUNT_JS_NOTIFICATIONS_WEB`.

Repo also carries `firebase.json` / `.firebaserc` for that hosting setup.

Branch model implied: development on `master`, deploy/release from `prod`.

## Release process (pub.dev)

Version in `pubspec.yaml` (currently 0.0.5); recent git history shows the pattern:
`fix/feat commits` → `docs: update CHANGELOG` → `chore: version bump 0.0.x`. Publishing is manual
(`flutter pub publish`) — no CI publishing workflow exists.

## GitHub hygiene

- Issue templates: bug report & feature request (`.github/ISSUE_TEMPLATE/`).
- PR template present.
- License: see `LICENSE` at repo root.
