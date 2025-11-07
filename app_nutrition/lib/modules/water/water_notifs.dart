import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class WaterNotifs {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    // Ask for runtime permissions (Android 13+ and iOS)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> scheduleEvery(int minutes) async {
    if (minutes < 15) {
      throw ArgumentError(
        'L\'intervalle doit être supérieur ou égal à 15 minutes.',
      );
    }

    await init();

    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == false) {
        throw StateError(
          'Permission Exact Alarm refusée. Activez-la dans les paramètres.',
        );
      }

      // Annule les anciens rappels
      await _plugin.cancel(1001);
      final now = tz.TZDateTime.now(tz.local);
      final first = now.add(Duration(minutes: minutes));

      await _plugin.zonedSchedule(
        1001,
        'Hydratation',
        'Buvez un verre d’eau 💧',
        tz.TZDateTime.from(first, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water',
            'Hydratation',
            channelDescription: 'Rappels hydratation',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // relance quotidienne même heure
      );
    } on PlatformException catch (e, stack) {
      debugPrint(
        'Water reminder scheduling failed: ${e.code} - ${e.message}\n$stack',
      );
      rethrow;
    } catch (e, stack) {
      debugPrint(
        'Unexpected error while scheduling water reminder: $e\n$stack',
      );
      rethrow;
    }
  }

  static Future<void> cancel() => _plugin.cancel(1001);
}
