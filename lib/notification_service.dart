import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static const _channel = AndroidNotificationDetails(
    'smart_parking_channel',
    'Smart Parking',
    channelDescription: 'Smart Parking booking notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  /// Immediate confirmation notification
  Future<void> showBookingConfirmation(String bookingId, String slot) async {
    await _plugin.show(
      bookingId.hashCode,
      '🅿️ Booking Confirmed!',
      'Your slot $slot has been booked. Show QR at entry.',
      const NotificationDetails(android: _channel),
    );
  }

  /// Schedule a reminder 30 minutes before booking time
  Future<void> scheduleReminder(
      String bookingId, String slot, DateTime bookingTime) async {
    final reminderTime = bookingTime.subtract(const Duration(minutes: 30));
    if (reminderTime.isBefore(DateTime.now())) return; // already passed

    await _plugin.zonedSchedule(
      '${bookingId}_reminder'.hashCode,
      '⏰ Parking Reminder',
      'Your slot $slot starts in 30 minutes!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
