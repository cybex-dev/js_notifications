import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:js_notifications/method_channel/js_notifications_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelJsNotifications platform = MethodChannelJsNotifications();
  const MethodChannel channel = MethodChannel('js_notifications');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // test('addNotification', () async {
  //   final n = JSNotification("Hello", JSNotificationOptions(tag: "hey"));
  //   await platform.addNotification(n);
  //   final nn = await platform.getNotification("hey");
  //   expect(nn, isNotNull);
  // });
}
