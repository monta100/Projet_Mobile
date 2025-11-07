import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class WaterNotifs {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android, iOS: DarwinInitializationSettings());
    await _plugin.initialize(init);
  }

  static Future<void> scheduleEvery(int minutes) async {
    // Cancelle les anciens rappels
    await _plugin.cancel(1001);
    final now = tz.TZDateTime.now(tz.local);
    final first = now.add(Duration(minutes: minutes));

    await _plugin.zonedSchedule(
      1001,
      'Hydratation',
      'Buvez un verre d’eau 💧',
      tz.TZDateTime.from(first, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('water', 'Hydratation',
            channelDescription: 'Rappels hydratation', importance: Importance.max, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time, // relance quotidienne même heure
    );
  }

  static Future<void> cancel() => _plugin.cancel(1001);
}
