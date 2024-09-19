import 'dart:async';
import 'dart:html' as html;

import 'package:js_notifications/core/core.dart';

import '../const/const.dart';
import '../core/notification_action.dart';
import '../core/notification_payload.dart';
import '../interop/interop.dart' as interop;
import '../utils/utils.dart';
import '../const/sw_events.dart';

typedef Consumer<T> = void Function(T t);

class ServiceWorkerManager {
  static const String TAG = 'service_worker_manager';

  late final interop.NotificationsAPI _notificationApi;

  late final String _scope;

  ServiceWorkerManager({this.onNotificationAction, this.onNotificationDismiss, required String scopeUrl}){
    _scope = scopeUrl;
    _notificationApi = interop.NotificationsAPI.instance;
    _setupServiceWorker();
  }

  Consumer<NotificationActionResult>? onNotificationAction;
  Consumer<NotificationActionResult>? onNotificationDismiss;

  html.ServiceWorkerContainer? _webServiceWorkerContainerDelegate;

  html.ServiceWorker? _serviceWorker;

  StreamSubscription<html.Event>? _serviceWorkerErrorSubscription;
  StreamSubscription<html.MessageEvent>? _serviceWorkerMessageStreamSubscription;

  // set the active service worker, detach events from current and attach new event handlers
  void _updateServiceWorker(html.ServiceWorker? value) {
    if (_serviceWorker != null) {
      _detachServiceWorkerEvents(_serviceWorker!);
    }
    if (value != null) {
      _attachServiceWorkerEvents(value);
    }
    if (value == null) {
      printDebug("Service Worker is null");
    }
    _serviceWorker = value;
  }

  /// Grab service worker for current URL
  /// We cannot have conflicting server workers, this will require us to use our own scope or hook
  /// into the primary service worker provided by Flutter
  void _setupServiceWorker() async {
    printDebug("Setting up service worker");
    _webServiceWorkerContainerDelegate = html.window.navigator.serviceWorker;
    if (_webServiceWorkerContainerDelegate == null) {
      printDebug("No service worker found.", TAG);
      return;
    }

    final delegate = _webServiceWorkerContainerDelegate!;

    // attach SW event listeners to respond to incoming messages from SW
    _attachServiceWorkerContainerEvents(delegate);

    // final registration = await delegate.getRegistration(scope);
    final options = {'scope': _scope, 'type': 'module'};

    printDebug("Registering service worker at '/$jsNotificationsSwJs'.");
    final registration = await delegate.register("/$jsNotificationsSwJs", options).catchError((e) {
      printDebug(e);
      printDebug("Failed to register $jsNotificationsSwJs, please make sure you copied over $jsNotificationsSwJs into your project\'s web folder e.g. root_project/web/$jsNotificationsSwJs");
      throw e;
    });

    _updateServiceWorker(registration.active ?? registration.installing);
  }

  void _attachServiceWorkerEvents(html.ServiceWorker serviceWorker) {
    printDebug("Attaching service worker event listeners (${serviceWorker.hashCode})");
    _serviceWorkerErrorSubscription = serviceWorker.onError.listen(_onServiceWorkerErrorEvent);
    serviceWorker.addEventListener(SWEvents.message, _onServiceWorkerMessage);
    serviceWorker.addEventListener(SWEvents.statechange, _onServiceWorkerStateChange);
    serviceWorker.addEventListener(SWEvents.error, _onServiceWorkerError);
    serviceWorker.addEventListener(SWEvents.install, _onServiceWorkerInstall);
    serviceWorker.addEventListener(SWEvents.activate, _onServiceWorkerActivate);
    serviceWorker.addEventListener(SWEvents.fetch, _onServiceWorkerFetch);
    serviceWorker.addEventListener(SWEvents.push, _onServiceWorkerPush);
    serviceWorker.addEventListener(SWEvents.pushsubscriptionchange, _onServiceWorkerPushSubscriptionChange);
    serviceWorker.addEventListener(SWEvents.sync, _onServiceWorkerSync);
  }

  void _detachServiceWorkerEvents(html.ServiceWorker serviceWorker) {
    printDebug("Detaching service worker event listeners (${serviceWorker.hashCode})");
    serviceWorker.removeEventListener(SWEvents.message, _onServiceWorkerMessage);
    serviceWorker.removeEventListener(SWEvents.statechange, _onServiceWorkerStateChange);
    serviceWorker.removeEventListener(SWEvents.error, _onServiceWorkerError);
    serviceWorker.removeEventListener(SWEvents.install, _onServiceWorkerInstall);
    serviceWorker.removeEventListener(SWEvents.activate, _onServiceWorkerActivate);
    serviceWorker.removeEventListener(SWEvents.fetch, _onServiceWorkerFetch);
    serviceWorker.removeEventListener(SWEvents.push, _onServiceWorkerPush);
    serviceWorker.removeEventListener(SWEvents.pushsubscriptionchange, _onServiceWorkerPushSubscriptionChange);
    serviceWorker.removeEventListener(SWEvents.sync, _onServiceWorkerSync);
  }

  void _attachServiceWorkerContainerEvents(html.ServiceWorkerContainer serviceWorkerContainer) {
    printDebug("Attaching service worker container event listeners (${serviceWorkerContainer.hashCode})");
    _serviceWorkerMessageStreamSubscription = serviceWorkerContainer.onMessage.listen(_onServiceWorkerContainerMessageEvent);
    serviceWorkerContainer.addEventListener(SWEvents.controllerchange, _onServiceWorkerContainerControllerChange);
    serviceWorkerContainer.addEventListener(SWEvents.statechange, _onServiceWorkerContainerStateChange);
    serviceWorkerContainer.addEventListener(SWEvents.error, _onServiceWorkerContainerError);
    serviceWorkerContainer.addEventListener(SWEvents.install, _onServiceWorkerContainerInstall);
    serviceWorkerContainer.addEventListener(SWEvents.activate, _onServiceWorkerContainerActivate);
    serviceWorkerContainer.addEventListener(SWEvents.fetch, _onServiceWorkerContainerFetch);
  }

  void _detachServiceWorkerContainerEvents(html.ServiceWorkerContainer serviceWorkerContainer) {
    printDebug("Detaching service worker container event listeners (${serviceWorkerContainer.hashCode})");
    _serviceWorkerMessageStreamSubscription?.cancel();
    serviceWorkerContainer.removeEventListener(SWEvents.controllerchange, _onServiceWorkerContainerControllerChange);
    serviceWorkerContainer.removeEventListener(SWEvents.statechange, _onServiceWorkerContainerStateChange);
    serviceWorkerContainer.removeEventListener(SWEvents.error, _onServiceWorkerContainerError);
    serviceWorkerContainer.removeEventListener(SWEvents.install, _onServiceWorkerContainerInstall);
    serviceWorkerContainer.removeEventListener(SWEvents.activate, _onServiceWorkerContainerActivate);
    serviceWorkerContainer.removeEventListener(SWEvents.fetch, _onServiceWorkerContainerFetch);
  }

  /// Service Worker Container event listeners
  void _onServiceWorkerContainerControllerChange(html.Event event) {
    printDebug("Service worker container controller changed: $event", TAG);
    _updateServiceWorker(_webServiceWorkerContainerDelegate?.controller);
  }

  void _onServiceWorkerContainerStateChange(html.Event event) {
    printDebug("Service worker container state change: $event", TAG);
  }

  void _onServiceWorkerContainerError(html.Event event) {
    printDebug("Service worker container error: $event", TAG);
  }

  void _onServiceWorkerContainerInstall(html.Event event) {
    printDebug("Service worker container install: $event", TAG);
  }

  void _onServiceWorkerContainerActivate(html.Event event) {
    printDebug("Service worker container activate: $event", TAG);
    _updateServiceWorker(_webServiceWorkerContainerDelegate?.controller);
  }

  void _onServiceWorkerContainerFetch(html.Event event) {
    printDebug("Service worker container fetch: $event", TAG);
  }

  void _onServiceWorkerContainerMessageEvent(html.MessageEvent event) {
    printDebug("Service worker container message event: $event", TAG);
    final map = Map<String, dynamic>.from(event.data);
    final action = NotificationActionResult.fromJson(map);
    final type = map["type"];
    if(type == SWEvents.click) {
      onNotificationAction?.call(action);
    } else if (type == SWEvents.close) {
      onNotificationDismiss?.call(action);
    } else {
      throw Exception("Unknown NotificationActionResult type $type");
    }
  }

  /// Service Worker event listeners
  void _onServiceWorkerMessage(html.Event event) {
    printDebug("Service worker message: $event", TAG);
  }

  void _onServiceWorkerStateChange(html.Event event) {
    printDebug("Service worker state change: ${_serviceWorker?.state}", TAG);
  }

  void _onServiceWorkerError(html.Event event) {
    printDebug("Service worker error: $event", TAG);
  }

  void _onServiceWorkerErrorEvent(html.Event event) {
    printDebug("Service worker error event: $event", TAG);
  }

  void _onServiceWorkerInstall(html.Event event) {
    printDebug("Service worker install: $event", TAG);
  }

  void _onServiceWorkerActivate(html.Event event) {
    printDebug("Service worker activate: $event", TAG);
  }

  void _onServiceWorkerFetch(html.Event event) {
    printDebug("Service worker fetch: $event", TAG);
  }

  void _onServiceWorkerPush(html.Event event) {
    printDebug("Service worker state change: $event", TAG);
  }

  void _onServiceWorkerPushSubscriptionChange(html.Event event) {
    printDebug("Service worker push subscription change: $event", TAG);
  }

  void _onServiceWorkerSync(html.Event event) {
    printDebug("Service worker sync: $event", TAG);
  }

  Future<void> postNotification(
    interop.JSNotification notification, {
    Map<String, dynamic>? data,
  }) {
    final payload = ServiceWorkerPayload(
      NotificationAction.notification,
      notification: notification,
      data: data,
    );
    return postMessage(payload);
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

    if (_serviceWorker != null) {
      Map<String, dynamic> json = payload.toMap();
      _serviceWorker!.postMessage(json);
    } else {
      printDebug("No service worker ready.");
      return;
    }
  }

  Future<void> dispose() async {
    if (_serviceWorker != null) {
      _detachServiceWorkerEvents(_serviceWorker!);
    }
    if (_webServiceWorkerContainerDelegate != null) {
      _detachServiceWorkerContainerEvents(_webServiceWorkerContainerDelegate!);
    }
    await _serviceWorkerErrorSubscription?.cancel();
  }
}
