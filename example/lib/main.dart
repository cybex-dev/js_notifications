import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
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
  final _boldTextStyle = TextStyle(fontWeight: FontWeight.bold);
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
            _sendBasicNotification("Go watch Star Wars, now!", tag: "star_wars_channel");
            break;
          }
        case "kill_him":
          {
            _sendBasicNotification("Good good, now go watch Star Wars!", tag: "star_wars_channel");
            break;
          }
        case "watch_star_wars":
          {
            _sendBasicNotification("Sure, click here to watch it.", tag: "rick_roll");
            break;
          }

        case _notificationActionStopwatchStart: {
          _startTimerNotification();
          break;
        }

        case _notificationActionStopwatchPause: {
          _pauseTimerNotification();
          _onSecondTimerTick();
          break;
        }

        case _notificationActionStopwatchStop: {
          _stopTimerNotification();
          _onSecondTimerTick();
          break;
        }

        case _notificationActionStopwatchSilent: {
          setState(() {
            _stopwatchSilent = true;
          });
          break;
        }

        case _notificationActionStopwatchHeadsUp: {
          setState(() {
            _stopwatchSilent = false;
          });
          break;
        }

        default: {
          if(event.tag == "rick_roll") {
            openNewWindow("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
          } else if(event.tag == "star_wars_channel") {
            openNewWindow("https://www.youtube.com/@StarWars");
          }
        }
      }
    });
    _jsNotificationsPlugin.dismissStream.listen((event) {
      switch(event.tag) {
        case "data-notification": {
          _sendBasicNotification("Dismissed data notification", tag: "");
          break;
        }
        case "grievous": {
          _sendBasicNotification("My disappointment is immeasurable and my day is ruined.", tag: "ruined");
          break;
        }
      }
    });
  }

  void _onSecondTimerTick() {
    final formattedCallTime = StopWatchTimer.getDisplayTime(stopWatchTimer.rawTime.value, milliSecond: false);
    print("Timer: $formattedCallTime");
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
          JSNotificationAction(action: _notificationActionStopwatchPause, title: "Pause"),
          JSNotificationAction(action: _notificationActionStopwatchStop, title: "Stop"),
        ] else ...[
          JSNotificationAction(action: _notificationActionStopwatchStart, title: "Start"),
          JSNotificationAction(action: _notificationActionDismiss, title: "Dismiss"),
        ],
        if (_stopwatchSilent)
          JSNotificationAction(action: _notificationActionStopwatchHeadsUp, title: "Heads Up")
        else
          JSNotificationAction(action: _notificationActionStopwatchSilent, title: "Silence"),
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
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _sendBasicNotification("Test Notification", tag: "test");
                      },
                      child: Text("Test Notification"),
                    ),
                    SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        _dismissBasicNotification();
                      },
                      child: Text("Dismiss Test Notification"),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text("Data Notification", style: _boldTextStyle),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _sendDataNotification();
                  },
                  child: Text("Data Notification"),
                ),
                SizedBox(height: 24),
                Text("Custom Notifications", style: _boldTextStyle),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _sendSpanishInquisition();
                      },
                      child: Text("Expect the unexpected."),
                    ),
                    SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        _sendGrievous();
                      },
                      child: Text("Star Wars"),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Column(
              children: [
                // Control timer notification
                Text("Timer Notification", style: _boldTextStyle),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _startTimerNotification();
                      },
                      child: Icon(Icons.play_arrow),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _pauseTimerNotification();
                      },
                      child: Icon(Icons.pause),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _stopTimerNotification();
                      },
                      child: Icon(Icons.stop),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showTimerNotification();
                  },
                  child: Text("Show Timer Notification"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _hideTimerNotification();
                  },
                  child: Text("Hide Timer Notification"),
                ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _clearAllNotifications();
              },
              child: Text("Clear All"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDataNotification({String? id, String? title, String? body, Map<String, dynamic>? data}) {
    final _id = id ?? "data-notification";
    final _title = title ?? "Data Notification";
    final _body = body ?? "A notification with some data too";
    final _data = {
      "string": "string",
      "1": 1,
      "false": false,
      "1.1": 1.1,
      'c': 'c',
      '[]': [],
      '{}': {},
    };

    return _jsNotificationsPlugin.showNotification(_title, body: _body, data: _data, tag: _id);
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
      body: "Subverted expectations result in expected unexpected expectations. Anyway, check the icon...",
      tag: "inquisition",
      icon: "https://pbs.twimg.com/media/CtCG_f4WcAAJY-1.jpg",
      actions: [
        JSNotificationAction(action: "dismiss", title: "Whatever"),
        JSNotificationAction(action: "unexpected", title: "Didn't expect that"),
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
        JSNotificationAction(action: "general_kenobi", title: "General Kenobi"),
        JSNotificationAction(action: "confused", title: "I'm confused"),
      ],
      requireInteraction: true,
    );
  }

  Future<void> _sendGrievousConversation() {
    return _jsNotificationsPlugin.showNotification(
      "Grievous",
      tag: "grievous_2",
      body: "You acknowledge he is a bold one. What do you do?",
      icon: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvS2A_Sb7z7dXcrPVscT0FeCdFO7IM88U2vg&s",
      actions: [
        JSNotificationAction(action: "kill_him", title: "Kill Him"),
        JSNotificationAction(action: "watch_star_wars", title: "Watch Star Wars"),
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
        JSNotificationAction(title: "Start", action: "stopwatch_start"),
        JSNotificationAction(title: "Dismiss", action: "dismiss"),
      ],
      requireInteraction: true,
    );
  }

  void _startTimerNotification() {
    _stopWatchTimerListener ??= stopWatchTimer.secondTime.listen((_) => _onSecondTimerTick());
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
