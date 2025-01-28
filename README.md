# js_notifications
An extended NotificationsAPI for Dart Web notifications.

## UI Examples

Examples of notifications on different platforms.

### Simple Notification

Example of a simple notification:

```dart
JsNotificationsPlatform.instance.showNotification("Test Notification", tag: "test");
```

### macOS

![](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/macos_simple_notification.png)

### Windows

![](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/windows_simple_notification.png)

### Linux

![Coming soon](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/linux_simple_notification.png)

### Notification with action

Example of a notification with actions:

```dart
JsNotificationsPlatform.instance.showNotification(
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
```

### macOS

Note: when hovering over the notification to display actions, the image is not displayed.

![](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/macos_unexpected_notification.png)

### Windows

![](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/windows_unexpected_notification.png)

### Linux

![Coming soon](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/linux_unexpected_notification.png)

## Inspiration
The Dart Web package is limited in showing notifications, one can only show a title, body, and icon. This package extends the NotificationsAPI to allow for more customization.

## Setup

### Imports
Add the following to your `pubspec.yaml` file:
```yaml
dependencies:
  js_notifications: ^0.0.3
```

### Copy service worker
Copy the service worker file named `js_notifications-sw.js` from the `example` directory to your web directory. _The name is very important, so make sure to have the file named `js_notifications-sw.js`._

## Usage

### import the package
```dart
import 'package:js_notifications/js_notifications.dart';
```

### Grab instance
```dart

final _jsNotificationsPlugin = JsNotificationsPlatform.instance;
```


### Requesting permission
```dart
_jsNotificationsPlugin.requestPermission().then((permission) {
    print(permission);
});
```

![](https://raw.githubusercontent.com/cybex-dev/js_notifications/refs/heads/master/images/chrome_permissions.png)

### Creating a notification
```dart
_jsNotificationsPlugin.showNotification('Title', {
    body: 'Body',
    icon: 'icon.png',
    badge: 'badge.png',
    image: 'image.png',
    tag: 'tag',
    data: {
      'key': 'value'
    },
  }
);
```

_Note: the tag is used to identify the notification, if a notification with the same tag is shown, the previous notification is replaced.

For convenient notification access, provide a tag or one will be generated via the [uuid](https://pub.dev/packages/uuid) package, specifically `uuid.v4()`._

### Creating a notification with actions

Here, we use the `actions` parameter to add actions to the notification. These are filled with `JSNotificationAction` objects.

```dart
JsNotificationsPlatform.instance.showNotification(
    "Click me",
    body: "An interactive notification",
    tag: "interactive",
    actions: [
        JSNotificationAction(action: "dismiss", title: "Click me"),
        JSNotificationAction(action: "click-me", title: "No, click me!"),
    ],
    requireInteraction: true,
);
```

There are convenience methods to create actions, `fromAction`, `fromTitle` and `simpleWithIcon`.

#### Platform limitations:
- macOS: Limited to 2 actions (text only) with `Settings` automatically added as a 3rd option. 
- Windows: Limited to 3 actions, fully customizable.
- Linux: Usually limited to 3 actions, customizability based on distro & desktop environment.

### Creating a "heads up" notification

For this, we use the `requireInteraction: true` option

```dart
JsNotificationsPlatform.instance.showNotification(
    "Attention",
    body: "I just wanted your attention",
    tag: "attention",
    actions: [
        JSNotificationAction(action: "dismiss", title: "Go away"),
    ],
    requireInteraction: true,
);
```

### Handling notification click or close events
```dart
_jsNotificationsPlugin.actionStream.listen((event) {
    print(event);
    switch (event.action) {
        case "unexpected": {
            _sendBasicNotification("I know, neither did they.");
            break;
        }
        //... other actions
    }
});

_jsNotificationsPlugin.dismissStream.listen((event) {
    print(event);
});
```


### Get a list of all notifications
```dart
_jsNotificationsPlugin.getAllNotifications().then((notifications) {
    notifications.forEach((notification) {
      print(notification);
    });
});
```

### Get a specific notification
```dart
_jsNotificationsPlugin.getNotification('my-awesome-notification-tag-here').then((notification) {
    print(notification);
});
```

## Features and bugs

Any and all feedback, PRs are welcome.
