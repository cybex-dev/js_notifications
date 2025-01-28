import 'dart:async';
//ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js_notifications/interop/interop.dart';
import 'package:js_notifications/js_notifications_web.dart';
import 'package:js_notifications/platform_interface/js_notifications_platform_interface.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _jsNotificationsPlugin = JsNotificationsPlatform.instance;
  final stopWatchTimer = StopWatchTimer();
  StreamSubscription<int>? _stopWatchTimerListener;
  final _boldTextStyle = const TextStyle(fontWeight: FontWeight.bold);
  bool _stopwatchSilent = false;

  static const _notificationTagStopwatch = "stopwatch";
  static const _notificationActionStopwatchStart = "stopwatch_start";
  static const _notificationActionStopwatchPause = "stopwatch_pause";
  static const _notificationActionStopwatchStop = "stopwatch_stop";

  static const _notificationActionStopwatchSilent = "stopwatch_silent";
  static const _notificationActionStopwatchHeadsUp = "stopwatch_headsup";

  static const _notificationActionDismiss = "dismiss";

  @override
  void initState() {
    super.initState();
    _jsNotificationsPlugin.actionStream.listen((event) {
      switch (event.action) {
        case "unexpected":
          {
            _sendBasicNotification("I know, neither did they.");
            break;
          }
        case _notificationActionDismiss:
          {
            if (event.tag == "inquisition") {
              _sendBasicNotification("Wey, you're next...");
            }
            break;
          }
        case "general_kenobi":
          {
            _sendGrievousConversation();
            break;
          }
        case "confused":
          {
            _sendBasicNotification("Go watch Star Wars, now!",
                tag: "star_wars_channel");
            break;
          }
        case "kill_him":
          {
            _sendBasicNotification("Good good, now go watch Star Wars!",
                tag: "star_wars_channel");
            break;
          }
        case "watch_star_wars":
          {
            _sendBasicNotification("Sure, click here to watch it.",
                tag: "rick_roll");
            break;
          }

        case _notificationActionStopwatchStart:
          {
            _startTimerNotification();
            break;
          }

        case _notificationActionStopwatchPause:
          {
            _pauseTimerNotification();
            _onSecondTimerTick();
            break;
          }

        case _notificationActionStopwatchStop:
          {
            _stopTimerNotification();
            _onSecondTimerTick();
            break;
          }

        case _notificationActionStopwatchSilent:
          {
            setState(() {
              _stopwatchSilent = true;
            });
            break;
          }

        case _notificationActionStopwatchHeadsUp:
          {
            setState(() {
              _stopwatchSilent = false;
            });
            break;
          }

        default:
          {
            if (event.tag == "rick_roll") {
              openNewWindow("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
            } else if (event.tag == "star_wars_channel") {
              openNewWindow("https://www.youtube.com/@StarWars");
            }
          }
      }
    });
    _jsNotificationsPlugin.dismissStream.listen((event) {
      switch (event.tag) {
        case "data-notification":
          {
            _sendBasicNotification("Dismissed data notification", tag: "");
            break;
          }
        case "grievous":
          {
            _sendBasicNotification(
                "My disappointment is immeasurable and my day is ruined.",
                tag: "ruined");
            break;
          }
      }
    });
  }

  void _onSecondTimerTick() {
    final formattedCallTime = StopWatchTimer.getDisplayTime(
        stopWatchTimer.rawTime.value,
        milliSecond: false);
    if (kDebugMode) {
      print("Timer: $formattedCallTime");
    }
    _jsNotificationsPlugin.showNotification(
      "Timer",
      body: formattedCallTime,
      tag: _notificationTagStopwatch,
      requireInteraction: !_stopwatchSilent,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      icon: "icons/call.png",
      silent: _stopwatchSilent,
      actions: [
        if (stopWatchTimer.isRunning) ...[
          const JSNotificationAction(
              action: _notificationActionStopwatchPause, title: "Pause"),
          const JSNotificationAction(
              action: _notificationActionStopwatchStop, title: "Stop"),
        ] else ...[
          const JSNotificationAction(
              action: _notificationActionStopwatchStart, title: "Start"),
          const JSNotificationAction(
              action: _notificationActionDismiss, title: "Dismiss"),
        ],
        if (_stopwatchSilent)
          const JSNotificationAction(
              action: _notificationActionStopwatchHeadsUp, title: "Heads Up")
        else
          const JSNotificationAction(
              action: _notificationActionStopwatchSilent, title: "Silence"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text("Test Notification", style: _boldTextStyle),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _sendBasicNotification("Test Notification",
                            tag: "test");
                      },
                      child: const Text("Test Notification"),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        _dismissBasicNotification();
                      },
                      child: const Text("Dismiss Test Notification"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Data Notification", style: _boldTextStyle),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _sendDataNotification();
                  },
                  child: const Text("Data Notification"),
                ),
                const SizedBox(height: 24),
                Text("Custom Notifications", style: _boldTextStyle),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _sendSpanishInquisition();
                      },
                      child: const Text("Expect the unexpected."),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        _sendGrievous();
                      },
                      child: const Text("Star Wars"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                // Control timer notification
                Text("Timer Notification", style: _boldTextStyle),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _startTimerNotification();
                      },
                      child: const Icon(Icons.play_arrow),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _pauseTimerNotification();
                      },
                      child: const Icon(Icons.pause),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _stopTimerNotification();
                      },
                      child: const Icon(Icons.stop),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showTimerNotification();
                  },
                  child: const Text("Show Timer Notification"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _hideTimerNotification();
                  },
                  child: const Text("Hide Timer Notification"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _clearAllNotifications();
              },
              child: const Text("Clear All"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDataNotification(
      {String? id, String? title, String? body, Map<String, dynamic>? data}) {
    final id0 = id ?? "data-notification";
    final title0 = title ?? "Data Notification";
    final body0 = body ?? "A notification with some data too";
    final data0 = {
      "string": "string",
      "1": 1,
      "false": false,
      "1.1": 1.1,
      'c': 'c',
      '[]': [],
      '{}': {},
      if (data != null) ...data,
    };

    return _jsNotificationsPlugin.showNotification(title0,
        body: body0, data: data0, tag: id0);
  }

  Future<void> _sendBasicNotification(String title, {String? tag}) {
    return _jsNotificationsPlugin.showNotification(title, tag: tag);
  }

  Future<void> _dismissBasicNotification() {
    return _jsNotificationsPlugin.dismissNotification(id: "test");
  }

  Future<void> _sendSpanishInquisition() {
    return _jsNotificationsPlugin.showNotification(
      "Oh no!",
      body:
          "Subverted expectations result in expected unexpected expectations. Anyway, check the icon...",
      tag: "inquisition",
      icon: "https://pbs.twimg.com/media/CtCG_f4WcAAJY-1.jpg",
      actions: [
        const JSNotificationAction(action: "dismiss", title: "Whatever"),
        const JSNotificationAction(
            action: "unexpected", title: "Didn't expect that"),
      ],
      requireInteraction: true,
    );
  }

  Future<void> _sendGrievous() {
    return _jsNotificationsPlugin.showNotification(
      "Obiwan Kenobi",
      tag: "grievous",
      body: "Hello there. How do you respond?",
      icon:
          "https://www.liveabout.com/thmb/F5lfgFptU9DNTDCT-xNEtot0lQ0=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/EP2-IA-60435_R_8x10-56a83bea3df78cf7729d314a.jpg",
      actions: [
        const JSNotificationAction(
            action: "general_kenobi", title: "General Kenobi"),
        const JSNotificationAction(action: "confused", title: "I'm confused"),
      ],
      requireInteraction: true,
    );
  }

  Future<void> _sendGrievousConversation() {
    return _jsNotificationsPlugin.showNotification(
      "Grievous",
      tag: "grievous_2",
      body: "You acknowledge he is a bold one. What do you do?",
      icon:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvS2A_Sb7z7dXcrPVscT0FeCdFO7IM88U2vg&s",
      actions: [
        const JSNotificationAction(action: "kill_him", title: "Kill Him"),
        const JSNotificationAction(
            action: "watch_star_wars", title: "Watch Star Wars"),
      ],
      requireInteraction: true,
    );
  }

  void _clearAllNotifications() {
    _jsNotificationsPlugin.clearNotifications();
  }

  void openNewWindow(String url) {
    html.window.open(url, "", 'noopener,noreferrer');
  }

  Future<void> _showTimerNotification() {
    return _jsNotificationsPlugin.showNotification(
      "Timer",
      tag: _notificationTagStopwatch,
      actions: [
        const JSNotificationAction(title: "Start", action: "stopwatch_start"),
        const JSNotificationAction(title: "Dismiss", action: "dismiss"),
      ],
      requireInteraction: true,
    );
  }

  void _startTimerNotification() {
    _stopWatchTimerListener ??=
        stopWatchTimer.secondTime.listen((_) => _onSecondTimerTick());
    _stopwatchSilent = false;
    stopWatchTimer.onStartTimer();
  }

  void _pauseTimerNotification() {
    stopWatchTimer.onStopTimer();
  }

  void _stopTimerNotification() {
    stopWatchTimer.onResetTimer();
  }

  void _hideTimerNotification() {
    stopWatchTimer.onStopTimer();
    _jsNotificationsPlugin.dismissNotification(id: _notificationTagStopwatch);
  }
}
