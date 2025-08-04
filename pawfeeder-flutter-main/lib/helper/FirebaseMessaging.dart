import 'package:app/helper/LocalNotification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

LocalNotification localNotification = LocalNotification();

void configureFirebaseMessaging() async {
  // NOTIFICATION PERMISSION
  FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // FOREGROUND
  FirebaseMessaging.onMessage.listen((event) {
    if (event != null) {
      String title = event.notification.title;
      String body = event.notification.body;
      localNotification.showNotification(title, body);
    }
  });

  // ON APP REOPEN
  FirebaseMessaging.onMessageOpenedApp.listen((event) async {});
}
