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

class ServiceWorkerManager {
  static const String tag = 'service_worker_manager';

  /// The Notifications API instance, used to request permission and check permission status
  late final interop.NotificationsAPI _notificationApi;

  /// The scope URL for the service worker. See https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerContainer/register#scope
  late final String _scope;

  ServiceWorkerManager({
    this.onNotificationTap,
    this.onNotificationAction,
    this.onNotificationDismiss,
    required String scopeUrl,
  }) {
    _scope = scopeUrl;
    _notificationApi = interop.NotificationsAPI.instance;
    _setupServiceWorker();
  }

  /// Callbacks for notification events
  Consumer<NotificationActionResult>? onNotificationAction;
  Consumer<NotificationActionResult>? onNotificationDismiss;
  Consumer<NotificationActionResult>? onNotificationTap;

  // Current service worker, null if not registered / not ready yet
  web.ServiceWorker? _serviceWorker;

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

  /// Grab service worker for current URL
  /// We cannot have conflicting server workers, this will require us to use our own scope or hook
  /// into the primary service worker provided by Flutter
  void _setupServiceWorker() async {
    printDebug("Setting up service worker");
    // `navigator.serviceWorker` is non-null in package:web — feature-detect
    // instead (absent in insecure contexts and unsupported browsers).
    if (!web.window.navigator.has('serviceWorker')) {
      printDebug("No service worker found.", tag: tag);
      return;
    }
    final delegate = web.window.navigator.serviceWorker;

    // attach SW event listeners to respond to incoming messages from SW
    _serviceWorkerMessageStreamSubscription = _messageEvent.forTarget(delegate).listen(_onServiceWorkerContainerMessageEvent);
    _containerControllerChangeSubscription = _controllerChangeEvent.forTarget(delegate).listen(_onServiceWorkerContainerControllerChange);

    final options = web.RegistrationOptions(scope: _scope, type: 'module');

    printDebug("Registering service worker at '/$jsNotificationsSwJs'.");
    final web.ServiceWorkerRegistration registration;
    try {
      registration = await delegate.register("/$jsNotificationsSwJs".toJS, options).toDart;
    } catch (e) {
      printDebug(e);
      printDebug(
          "Failed to register $jsNotificationsSwJs, please make sure you copied over $jsNotificationsSwJs into your project's web folder e.g. root_project/web/$jsNotificationsSwJs");
      rethrow;
    }

    _registration = registration;

    // Track updates to *our* registration: when a new (byte-different) worker
    // ships, `updatefound` fires and the new worker must be adopted once it
    // activates — otherwise `_serviceWorker` keeps pointing at the old,
    // soon-to-be-redundant worker and postMessage goes nowhere until reload.
    _registrationUpdateFoundSubscription =
        _updateFoundEvent.forTarget(registration).listen(_onRegistrationUpdateFound);

    // Fresh install: `active` is null and we adopt the `installing` worker —
    // it is the same object through installing → activated, so the reference
    // stays valid and _onServiceWorkerStateChange observes each transition.
    _updateServiceWorker(registration.active ?? registration.waiting ?? registration.installing);
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
    _installingWorkerStateChangeSubscription =
        _stateChangeEvent.forTarget(worker).listen((event) {
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

  Future<void> dispose() async {
    await _serviceWorkerMessageStreamSubscription?.cancel();
    await _containerControllerChangeSubscription?.cancel();
    await _serviceWorkerStateChangeSubscription?.cancel();
    await _serviceWorkerErrorSubscription?.cancel();
    await _registrationUpdateFoundSubscription?.cancel();
    await _installingWorkerStateChangeSubscription?.cancel();
  }
}
