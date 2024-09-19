# js_notifications
An extended NotificationsAPI for Dart Web notifications.

## Inspiration
The Dart Web package is limited in showing notifications, one can only show a title, body, and icon. This package extends the NotificationsAPI to allow for more customization.

## Setup

### Imports
Add the following to your `pubspec.yaml` file:
```yaml
dependencies:
  js_notifications: ^0.0.1
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

### Handling notification click or close events
```dart
_jsNotificationsPlugin.actionStream.listen((event) {
  print(event);
});

_jsNotificationsPlugin.dismissStream.listen((event) {
  print(event);
});
```
