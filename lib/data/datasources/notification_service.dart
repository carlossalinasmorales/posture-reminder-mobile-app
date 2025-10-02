import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../domain/entities/reminder.dart';

// Callback global para manejar acciones en segundo plano
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Este método se ejecuta cuando se toca la notificación en segundo plano
  print('Notificación tocada en segundo plano: ${response.actionId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Callback para manejar acciones
  Function(String reminderId, String action)? onActionReceived;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final action = response.actionId;

    print('Notificación tocada - Payload: $payload, Action: $action');

    if (payload != null && action != null) {
      // Llamar al callback registrado
      onActionReceived?.call(payload, action);
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    final now = DateTime.now();
    var scheduledDate = reminder.dateTime;

    if (scheduledDate.isBefore(now) &&
        reminder.frequency == ReminderFrequency.once) {
      return;
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = _getNextOccurrence(reminder);
    }

    final androidDetails = AndroidNotificationDetails(
      'posture_reminders',
      'Recordatorios de Postura',
      channelDescription:
          'Notificaciones para recordar mantener una buena postura',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        reminder.description,
        contentTitle: reminder.title,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'complete',
          '✓ Completar',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'postpone',
          '⏰ Aplazar 2 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'postureReminder',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    switch (reminder.frequency) {
      case ReminderFrequency.once:
        await _notifications.zonedSchedule(
          reminder.id.hashCode,
          reminder.title,
          reminder.description,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: reminder.id,
        );
        break;

      case ReminderFrequency.daily:
        await _notifications.zonedSchedule(
          reminder.id.hashCode,
          reminder.title,
          reminder.description,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: reminder.id,
        );
        break;

      case ReminderFrequency.weekly:
        await _notifications.zonedSchedule(
          reminder.id.hashCode,
          reminder.title,
          reminder.description,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: reminder.id,
        );
        break;

      case ReminderFrequency.custom:
        await _scheduleCustomReminder(reminder, notificationDetails);
        break;
    }
  }

  Future<void> _scheduleCustomReminder(
    Reminder reminder,
    NotificationDetails details,
  ) async {
    if (reminder.customDays != null && reminder.customDays!.isNotEmpty) {
      for (final day in reminder.customDays!) {
        final nextDate = _getNextDateForWeekday(reminder.dateTime, day);
        await _notifications.zonedSchedule(
          '${reminder.id}_$day'.hashCode,
          reminder.title,
          reminder.description,
          tz.TZDateTime.from(nextDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: reminder.id,
        );
      }
    } else if (reminder.customInterval != null) {
      var currentDate = reminder.dateTime;
      final now = DateTime.now();

      for (var i = 0; i < 10; i++) {
        if (currentDate.isAfter(now)) {
          await _notifications.zonedSchedule(
            '${reminder.id}_$i'.hashCode,
            reminder.title,
            reminder.description,
            tz.TZDateTime.from(currentDate, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: reminder.id,
          );
        }
        currentDate = currentDate.add(Duration(days: reminder.customInterval!));
      }
    }
  }

  DateTime _getNextOccurrence(Reminder reminder) {
    final now = DateTime.now();
    var next = reminder.dateTime;

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        while (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case ReminderFrequency.weekly:
        while (next.isBefore(now)) {
          next = next.add(const Duration(days: 7));
        }
        break;
      case ReminderFrequency.custom:
        if (reminder.customInterval != null) {
          while (next.isBefore(now)) {
            next = next.add(Duration(days: reminder.customInterval!));
          }
        }
        break;
      case ReminderFrequency.once:
        break;
    }

    return next;
  }

  DateTime _getNextDateForWeekday(DateTime baseDate, int weekday) {
    final now = DateTime.now();
    var date = DateTime(
      now.year,
      now.month,
      now.day,
      baseDate.hour,
      baseDate.minute,
    );

    while (date.weekday != weekday || date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  Future<void> cancelReminder(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> showImmediateNotification(Reminder reminder) async {
    const androidDetails = AndroidNotificationDetails(
      'posture_reminders',
      'Recordatorios de Postura',
      channelDescription:
          'Notificaciones para recordar mantener una buena postura',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      reminder.id.hashCode,
      reminder.title,
      reminder.description,
      notificationDetails,
      payload: reminder.id,
    );
  }
}
