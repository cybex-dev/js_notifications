import 'core.dart';

class NotificationActionResult implements Serializable {
  final String? tag;
  final String? action;
  final Map<String, dynamic>? data;

  const NotificationActionResult(this.action, this.data, this.tag);

  factory NotificationActionResult.fromJson(Map<String, dynamic> json) {
    String? tag;
    String? action;
    Map<String, dynamic>? data;

    if (json.containsKey("tag") && json["tag"] is String) {
      tag = json["tag"];
    }
    if (json.containsKey("action") && json["action"] is String) {
      action = json["action"];
    }
    if (json.containsKey("data") && json["data"] is Map) {
      final map = Map<String, dynamic>.from(json["data"]);
      data = map;
    }

    return NotificationActionResult(action, data, tag);
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    if (action != null) {
      map["action"] = action;
    }
    if (data != null) {
      map["data"] = data;
    }
    if (tag != null) {
      map["tag"] = tag;
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationActionResult &&
          runtimeType == other.runtimeType &&
          tag == other.tag &&
          action == other.action &&
          data == other.data;

  @override
  int get hashCode => tag.hashCode ^ action.hashCode ^ data.hashCode;
}
