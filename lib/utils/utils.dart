extension StringExtension on String {
  String capitalize() {
    if (length == 0) return this;
    if (length == 1) return toUpperCase();
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Recursively converts a map produced by `dart:js_interop`'s `dartify()`
/// (typed `Map<Object?, Object?>`) into the `Map<String, dynamic>` shape used
/// throughout the plugin. Nested maps and lists are converted as well.
Map<String, dynamic> deepCastMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), deepCastValue(value)));
}

/// See [deepCastMap].
dynamic deepCastValue(dynamic value) {
  if (value is Map) return deepCastMap(value);
  if (value is List) return value.map(deepCastValue).toList();
  return value;
}
