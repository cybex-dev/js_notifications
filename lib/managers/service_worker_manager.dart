import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:js_notifications/core/core.dart';
import 'package:simple_print/simple_print.dart';
import 'package:web/web.dart' as web;

import '../const/const.dart';
import '../const/sw_events.dart';
import '../core/user_agent.dart';
import '../interop/interop.dart' as interop;
import '../utils/utils.dart';

typedef Consumer<T> = void Function(T t);

/// Manages the plugin's dedicated service worker: registration, lifecycle
/// tracking (install/update/redundant) and the two-way `postMessage` bridge.
///
/// Singleton — a page has a single service worker registration for this
/// plugin, and the manager owns the listeners attached to it. Obtain it via
/// [ServiceWorkerManager.instance], or via the factory constructor to also
/// (re)assign the notification event callbacks:
///
/// ```dart
/// final manager = ServiceWorkerManager(
///   onNotificationTap: _onTap,
///   onNotificationAction: _onAction,
///   onNotificationDismiss: _onDismiss,
/// );
/// await manager.init();
/// ```
///
/// Callbacks passed to the factory overwrite previously assigned ones; omitted
/// (null) callbacks are left untouched, so a later call cannot silently
/// detach existing handlers.
class ServiceWorkerManager {
  static const String tag = 'service_worker_manager';

  /// The Notifications API instance, used to request permission and check permission status
  late final interop.NotificationsAPI _notificationApi;

  /// Completes with the result of the initial (bundled) service worker
  /// registration. Non-null once [init] has been called; awaited internally so
  /// nothing races the automatic registration.
  Future<bool>? _initFuture;

  ServiceWorkerManager._() {
    _notificationApi = interop.NotificationsAPI.instance;
  }

  static final ServiceWorkerManager _instance = ServiceWorkerManager._();

  /// The single [ServiceWorkerManager] for this page.
  static ServiceWorkerManager get instance => _instance;

  /// Returns the singleton [instance], assigning any non-null callbacks.
  factory ServiceWorkerManager({
    Consumer<NotificationActionResult>? onNotificationTap,
    Consumer<NotificationActionResult>? onNotificationAction,
    Consumer<NotificationActionResult>? onNotificationDismiss,
  }) {
    _instance.onNotificationTap = onNotificationTap ?? _instance.onNotificationTap;
    _instance.onNotificationAction = onNotificationAction ?? _instance.onNotificationAction;
    _instance.onNotificationDismiss = onNotificationDismiss ?? _instance.onNotificationDismiss;
    return _instance;
  }

  /// Whether [init] has completed successfully and a service worker is
  /// registered and tracked by this manager.
  bool get isInitialized => _serviceWorker != null;

  /// Whether this browser exposes the Service Worker API. False in insecure
  /// contexts (non-https, non-localhost) and unsupported browsers, in which
  /// case [init] returns false and notifications cannot be shown.
  bool get isSupported => web.window.navigator.has('serviceWorker');

  /// Initialises the manager: registers the bundled service worker, cleans up
  /// legacy registrations, and attaches the event listeners that relay
  /// notification events back to Dart.
  ///
  /// Must be called before any notification can be posted — [postMessage] and
  /// friends await initialisation internally, so calls made while init is
  /// still in flight are queued rather than dropped.
  ///
  /// Returns true when a service worker was registered successfully, false
  /// when service workers are unsupported (see [isSupported]) or registration
  /// failed — failures are logged, never thrown, so plugin registration cannot
  /// break app startup.
  ///
  /// Idempotent: repeat calls return the result of the first call without
  /// re-registering. Use [registerServiceWorker] to (re-)register a custom
  /// worker or scope after initialisation.
  Future<bool> init() {
    return _initFuture ??= _setupServiceWorker().then((registered) {
      if (registered) {
        printDebug("Service worker initialised.", tag: tag);
      }
      return registered;
    }).catchError((e) {
      printDebug("Service worker setup failed: $e", tag: tag);
      return false;
    });
  }

  /// Awaits [init] if it is already running, or runs it on demand. Lets public
  /// entry points work regardless of whether the caller awaited [init] first.
  Future<bool> _ensureInitialized() => init();

  /// Callbacks for notification events
  Consumer<NotificationActionResult>? onNotificationAction;
  Consumer<NotificationActionResult>? onNotificationDismiss;
  Consumer<NotificationActionResult>? onNotificationTap;

  // Current service worker, null if not registered / not ready yet
  web.ServiceWorker? _serviceWorker;

  // The service worker container; kept so registerServiceWorker can
  // re-register after the initial setup.
  web.ServiceWorkerContainer? _container;

  // Custom worker script URL passed to [registerServiceWorker], null while
  // the bundled asset is in use. Lets [updateScope] re-register the same
  // script under a new scope.
  String? _customUrl;

  // This manager's registration — the source of truth for install/update
  // tracking (updatefound, installing/waiting/active workers).
  web.ServiceWorkerRegistration? _registration;

  /// ServiceWorker lifecycle states (ServiceWorkerState enum values).
  static const String _stateActivated = 'activated';
  static const String _stateRedundant = 'redundant';

  /// Event stream providers for service worker events
  static const _messageEvent = web.EventStreamProvider<web.MessageEvent>(SWEvents.message);
  static const _controllerChangeEvent = web.EventStreamProvider<web.Event>(SWEvents.controllerchange);
  static const _stateChangeEvent = web.EventStreamProvider<web.Event>(SWEvents.statechange);
  static const _errorEvent = web.EventStreamProvider<web.Event>(SWEvents.error);
  static const _updateFoundEvent = web.EventStreamProvider<web.Event>(SWEvents.updatefound);

  /// Subscriptions to service worker events
  StreamSubscription<web.MessageEvent>? _serviceWorkerMessageStreamSubscription;
  StreamSubscription<web.Event>? _containerControllerChangeSubscription;
  StreamSubscription<web.Event>? _serviceWorkerStateChangeSubscription;
  StreamSubscription<web.Event>? _serviceWorkerErrorSubscription;
  StreamSubscription<web.Event>? _registrationUpdateFoundSubscription;
  StreamSubscription<web.Event>? _installingWorkerStateChangeSubscription;

  /// Platform-specific limits for notification actions
  static const int platformLimitMac = 2;
  static const int platformLimitLinux = 2;
  static const int platformLimitWin = 3;
  static const int platformLimitDefault = 3;

  /// set the active service worker, detach events from current and attach new event handlers
  void _updateServiceWorker(web.ServiceWorker? value) {
    _serviceWorkerStateChangeSubscription?.cancel();
    _serviceWorkerErrorSubscription?.cancel();
    _serviceWorkerStateChangeSubscription = null;
    _serviceWorkerErrorSubscription = null;

    if (value != null) {
      printDebug("Attaching service worker event listeners (${value.hashCode})");
      _serviceWorkerStateChangeSubscription = _stateChangeEvent.forTarget(value).listen(_onServiceWorkerStateChange);
      _serviceWorkerErrorSubscription = _errorEvent.forTarget(value).listen(_onServiceWorkerError);
    } else {
      printDebug("Service Worker is null");
    }
    _serviceWorker = value;
  }

  /// Set up the plugin's dedicated service worker.
  ///
  /// The worker script ships as a Flutter asset of this package
  /// ([bundledSwAssetPath]) and registers automatically.
  ///
  /// Flutter's SW `flutter_service_worker.js` runs on default scope `/`,
  /// thus `js_notifications` SW runs on it's own set scope which controls no pages.
  ///
  /// Returns false when service workers are unsupported; throws when
  /// registration itself fails (handled by [init]).
  Future<bool> _setupServiceWorker() async {
    printDebug("Setting up service worker");
    // `navigator.serviceWorker` is non-null in package:web — feature-detect
    // instead (absent in insecure contexts and unsupported browsers).
    if (!isSupported) {
      printDebug(
          "Service workers are not supported in this browser or context "
          "(a secure context — https or localhost — is required); notifications are unavailable.",
          tag: tag);
      return false;
    }
    final delegate = web.window.navigator.serviceWorker;
    _container = delegate;

    // attach SW event listeners to respond to incoming messages from SW
    _serviceWorkerMessageStreamSubscription = _messageEvent.forTarget(delegate).listen(_onServiceWorkerContainerMessageEvent);
    _containerControllerChangeSubscription = _controllerChangeEvent.forTarget(delegate).listen(_onServiceWorkerContainerControllerChange);

    // Clean up legacy registrations of a manually copied worker.
    await _unregisterLegacyServiceWorkers(delegate);

    await _register(delegate, _resolveBundledServiceWorkerUrl());
    return true;
  }

  /// Resolves the bundled service worker asset against the document's base
  /// URI, so deployments under a non-root `<base href>` resolve correctly.
  String _resolveBundledServiceWorkerUrl() {
    return Uri.parse(web.document.baseURI).resolve(bundledSwAssetPath).toString();
  }

  /// Registers [url] as this manager's service worker and wires up
  /// registration-level update tracking. When [scope] is null the browser
  /// default (the script's directory) is used.
  Future<void> _register(
    web.ServiceWorkerContainer delegate,
    String url, {
    String? scope,
  }) async {
    printDebug("Registering service worker at '$url'.");
    final web.ServiceWorkerRegistration registration;
    try {
      final promise = scope != null ? delegate.register(url.toJS, web.RegistrationOptions(scope: scope)) : delegate.register(url.toJS);
      registration = await promise.toDart;
    } catch (e) {
      printDebug(e);
      printDebug("Failed to register the js_notifications service worker at '$url'"
          "${scope != null ? " with scope '$scope'" : ""}. "
          "The script is bundled as a Flutter asset of the js_notifications package and should be deployed automatically. "
          "If you are using a custom worker URL via registerServiceWorker(), verify the file exists at the given URL. "
          "If you passed a custom scope outside the script's directory, the server must send a "
          "'Service-Worker-Allowed' header covering that scope (for the bundled asset, any scope broader than "
          "'$bundledSwAssetDirMarker' needs it).");
      rethrow;
    }

    _registration = registration;

    // Track updates to *our* registration: when a new (byte-different) worker
    // ships, `updatefound` fires and the new worker must be adopted once it
    // activates — otherwise `_serviceWorker` keeps pointing at the old,
    // soon-to-be-redundant worker and postMessage goes nowhere until reload.
    _registrationUpdateFoundSubscription?.cancel();
    _registrationUpdateFoundSubscription = _updateFoundEvent.forTarget(registration).listen(_onRegistrationUpdateFound);

    // Fresh install: `active` is null and we adopt the `installing` worker —
    // it is the same object through installing → activated, so the reference
    // stays valid and _onServiceWorkerStateChange observes each transition.
    _updateServiceWorker(registration.active ?? registration.waiting ?? registration.installing);
  }

  /// Unregisters registrations of a manually copied worker at the app's web
  /// root (the pre-bundled-asset setup, registered as
  /// `/js_notifications-sw.js` with scope [defaultScope]).
  ///
  Future<void> _unregisterLegacyServiceWorkers(web.ServiceWorkerContainer delegate) async {
    try {
      final registrations = (await delegate.getRegistrations().toDart).toDart;
      for (final registration in registrations) {
        final worker = registration.active ?? registration.waiting ?? registration.installing;
        final scriptUrl = worker?.scriptURL;
        if (scriptUrl == null) {
          continue;
        }
        final isLegacy = scriptUrl.endsWith("/$jsNotificationsSwJs") && !scriptUrl.contains(bundledSwAssetDirMarker);
        if (isLegacy) {
          printDebug(
              "Unregistering legacy js_notifications service worker at '${registration.scope}' ($scriptUrl). "
              "The service worker is now bundled with the package; the copied file in your web folder can be deleted.",
              tag: tag);
          await registration.unregister().toDart;
        }
      }
    } catch (e) {
      printDebug("Legacy service worker migration check failed: $e", tag: tag);
    }
  }

  /// Re-registers this manager's service worker, replacing the previous
  /// registration (which is unregistered first).
  ///
  /// - [url]: script URL of a custom worker (e.g. a copy of
  ///   `js_notifications-sw.js` extended with app-specific message handling
  ///   for [postAction] payloads). When null, the **bundled** worker asset is
  ///   used — pass only [scope] to keep the bundled worker but register it
  ///   under a custom scope.
  /// - [scope]: registration scope. When null the browser default (the
  ///   script's directory) is used. A scope outside the script's directory
  ///   requires the server to send a `Service-Worker-Allowed` header; for the
  ///   bundled asset (served from `assets/packages/js_notifications/assets/`)
  ///   any broader scope — e.g. `/js_notifications/` — needs that header.
  Future<void> registerServiceWorker({String? url, String? scope}) async {
    // Never race the automatic bundled registration (and initialise on demand
    // if the caller never awaited init()).
    await _ensureInitialized();

    final delegate = _container;
    if (delegate == null) {
      printDebug("Service workers are not supported in this browser; cannot register a service worker.", tag: tag);
      return;
    }

    try {
      await _registration?.unregister().toDart;
    } catch (e) {
      printDebug("Failed to unregister previous service worker: $e", tag: tag);
    }
    _registration = null;

    _customUrl = url;
    await _register(delegate, url ?? _resolveBundledServiceWorkerUrl(), scope: scope);
  }

  /// Re-registers the currently registered worker script (bundled, or the
  /// custom URL last passed to [registerServiceWorker]) under [scope].
  /// Backs the platform interface's `scopeUrl` setter.
  Future<void> updateScope(String scope) {
    return registerServiceWorker(url: _customUrl, scope: scope);
  }

  /// Service Worker Container event listeners
  void _onServiceWorkerContainerControllerChange(web.Event event) {
    // Log only — deliberately NOT adopting `container.controller` here. The
    // controller is the worker controlling the *page*, and this plugin's
    // scope controls no pages, so the controller is never our worker (it is
    // typically Flutter's own flutter_service_worker.js). Adopting it would
    // silently redirect postMessage to a worker that ignores our protocol.
    // Updates to our own worker are tracked via `updatefound`/`statechange`
    // on the registration instead (see _onRegistrationUpdateFound).
    printDebug("Service worker container controller changed: $event", tag: tag);
  }

  /// Registration event listeners
  ///
  /// A new service worker version has started installing on our registration
  /// (browsers check for updates on register()/navigation/every 24h). Watch
  /// its state and adopt it once it activates; if it ends up redundant
  /// (install failed or superseded), stop tracking it.
  void _onRegistrationUpdateFound(web.Event event) {
    final installing = _registration?.installing;
    printDebug("Service worker update found (state: ${installing?.state})", tag: tag);
    if (installing == null) {
      return;
    }
    _trackInstallingWorker(installing);
  }

  void _trackInstallingWorker(web.ServiceWorker worker) {
    _installingWorkerStateChangeSubscription?.cancel();
    _installingWorkerStateChangeSubscription = _stateChangeEvent.forTarget(worker).listen((event) {
      final state = worker.state;
      printDebug("Installing service worker state change: $state", tag: tag);
      if (state == _stateActivated) {
        _installingWorkerStateChangeSubscription?.cancel();
        _installingWorkerStateChangeSubscription = null;
        _updateServiceWorker(worker);
      } else if (state == _stateRedundant) {
        _installingWorkerStateChangeSubscription?.cancel();
        _installingWorkerStateChangeSubscription = null;
      }
    });
  }

  void _onServiceWorkerContainerMessageEvent(web.MessageEvent event) {
    printDebug("Service worker container message event: $event", tag: tag);
    // dart:js_interop delivers `event.data` as an opaque JS value — dartify()
    // + deepCastMap replace dart:html's implicit conversion to a Dart Map.
    final data = event.data.dartify();
    if (data is! Map) {
      printDebug("Ignoring service worker message with non-map payload: $data", tag: tag);
      return;
    }
    final map = deepCastMap(data);
    final result = NotificationActionResult.fromJson(map);
    final type = map["type"];
    if (type == SWEvents.click) {
      /// Custom notification event, not part of the standard Notification API.
      /// Used to describe clicking on a notification.
      /// This may be confused with an empty notification action event.
      /// Sample:
      /// ```js
      /// notification.actions = [
      ///    { action: "", title: "Open Window" },
      ///    { action: "click", title: "Clicked me" },
      /// ];
      /// ```
      ///
      /// The above action with title "Open Window" will be considered a tap action as the service worker does not
      /// distinguish between a normal notification click and a notification action with an empty action string
      /// (see "Open Window" action above).
      if (result.action == null || result.action!.isEmpty) {
        onNotificationTap?.call(result);
      } else {
        onNotificationAction?.call(result);
      }
    } else if (type == SWEvents.close) {
      onNotificationDismiss?.call(result);
    } else {
      throw Exception("Unknown NotificationActionResult type $type");
    }
  }

  /// Service Worker event listeners
  void _onServiceWorkerStateChange(web.Event event) {
    final state = _serviceWorker?.state;
    printDebug("Service worker state change: $state", tag: tag);
    if (state == _stateRedundant) {
      // The worker we hold was replaced (update activated) or discarded —
      // fall back to the registration's current active worker. Usually the
      // updatefound path has already adopted the replacement; this is the
      // safety net for orderings where `redundant` arrives first (adoption
      // is idempotent).
      _updateServiceWorker(_registration?.active);
    }
  }

  void _onServiceWorkerError(web.Event event) {
    printDebug("Service worker error: $event", tag: tag);
  }

  Future<void> postNotification(
    interop.JSNotification notification, {
    Map<String, dynamic>? data,
  }) {
    _checkActionCountLimitation(notification);
    final payload = ServiceWorkerPayload(
      NotificationAction.notification,
      notification: notification,
      data: data,
    );
    return postMessage(payload);
  }

  void _checkActionCountLimitation(interop.JSNotification notification) {
    final actions = notification.options?.actions ?? [];
    if (actions.isEmpty) {
      return;
    }

    if (!kIsWeb) {
      return;
    }

    switch (platformFromUserAgent) {
      case Platform.macos:
        if (actions.length > platformLimitMac) {
          final ignoredActions = actions.sublist(platformLimitMac).map((e) => "'${e.action}'").join(", ");
          printDebug("macOS Notification centre only supports up to 3 actions, ignored the following actions: [$ignoredActions]");
        }
        break;
      case Platform.linux:
        if (actions.length > platformLimitLinux) {
          final ignoredActions = actions.sublist(platformLimitLinux).map((e) => "'${e.action}'").join(", ");
          printDebug("Linux platforms usually supports up to 3 actions, ignored the following actions: [$ignoredActions]");
        }
        break;
      case Platform.windows:
        if (actions.length > platformLimitWin) {
          final ignoredActions = actions.sublist(platformLimitWin).map((e) => "'${e.action}'").join(", ");
          printDebug("Windows 10 Toast Notification only supports up to 3 actions, ignored the following actions: [$ignoredActions]");
        }
      case Platform.unknown:
        // default:
        if (actions.length > platformLimitDefault) {
          final ignoredActions = actions.sublist(platformLimitDefault).map((e) => "'${e.action}'").join(", ");
          printDebug(
              "Could not determine the platform from user agent, most platforms ignore actions beyond 3, ignored the following actions may be ignored: [$ignoredActions]");
        }
        return;
    }
  }

  Future<void> postAction({
    String? id,
    required NotificationAction action,
    Map<String, dynamic>? data,
  }) {
    final payload = ServiceWorkerPayload(action, id: id, data: data);
    return postMessage(payload);
  }

  Future<void> cancelNotification(String id) {
    final payload = ServiceWorkerPayload.cancel(id);
    return postMessage(payload);
  }

  Future<void> cancelAllNotifications() {
    final payload = ServiceWorkerPayload.cancelAll();
    return postMessage(payload);
  }

  Future<void> postMessage(ServiceWorkerPayload payload) {
    return _sendMessage(payload);
  }

  Future<void> _sendMessage(ServiceWorkerPayload payload) async {
    // Messages sent before/while init() completes wait for it rather than
    // being dropped with "No service worker ready".
    await _ensureInitialized();

    final granted = _notificationApi.hasPermission;
    if (!granted) {
      final result = await _notificationApi.requestPermission();
      if (!result) {
        printDebug("Notification permissions denied");
        return;
      }
    }

    final serviceWorker = _serviceWorker;
    if (serviceWorker != null) {
      final Map<String, dynamic> json = payload.toMap();
      // dart:js_interop postMessage takes a JS value — jsify() converts the
      // Dart map (JSON-safe values only) explicitly, where dart:html used to
      // convert implicitly.
      serviceWorker.postMessage(json.jsify());
    } else {
      printDebug("No service worker ready.");
      return;
    }
  }

  /// Detaches all listeners and resets initialisation state. The registered
  /// service worker itself is left in place (it outlives the page); calling
  /// [init] again re-attaches listeners and re-registers.
  Future<void> dispose() async {
    await _serviceWorkerMessageStreamSubscription?.cancel();
    await _containerControllerChangeSubscription?.cancel();
    await _serviceWorkerStateChangeSubscription?.cancel();
    await _serviceWorkerErrorSubscription?.cancel();
    await _registrationUpdateFoundSubscription?.cancel();
    await _installingWorkerStateChangeSubscription?.cancel();

    _serviceWorkerMessageStreamSubscription = null;
    _containerControllerChangeSubscription = null;
    _serviceWorkerStateChangeSubscription = null;
    _serviceWorkerErrorSubscription = null;
    _registrationUpdateFoundSubscription = null;
    _installingWorkerStateChangeSubscription = null;

    _serviceWorker = null;
    _registration = null;
    _container = null;
    // Allow init() to run again after disposal.
    _initFuture = null;
  }
}
