import 'package:flutter/foundation.dart';

void printDebug(dynamic message, [String? tag]) {
  if (kDebugMode) {
    String m = (tag != null) ? '[$tag] $message' : message;
    print(m);
  }
}