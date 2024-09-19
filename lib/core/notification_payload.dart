import '../interop/interop.dart';
import 'notification_action.dart';
import 'serializable.dart';

class ServiceWorkerPayload implements Serializable {
  final String? id;
  final NotificationAction action;
  final JSNotification? notification;
  final Map<String, dynamic>? data;

  ServiceWorkerPayload(this.action, {this.id, this.notification, this.data});

  factory ServiceWorkerPayload.cancel(String id) {
    return ServiceWorkerPayload(NotificationAction.cancel, id: id);
  }

  factory ServiceWorkerPayload.cancelAll() {
    return ServiceWorkerPayload(NotificationAction.cancelAll);
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "action": action.name,
    };
    if (id != null) {
      map["id"] = id!;
    }
    if (notification != null) {
      map["notification"] = notification!.toMap();
    }
    if (data != null) {
      map["data"] = data;
    }
    return map;
  }
}