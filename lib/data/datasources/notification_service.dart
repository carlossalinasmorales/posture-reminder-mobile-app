import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../domain/entities/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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
    // Manejar la acción de la notificación
    final payload = response.payload;
    final action = response.actionId;

    if (action == 'complete') {
      // Marcar como completado
      _handleCompleteAction(payload);
    } else if (action == 'postpone') {
      // Aplazar recordatorio
      _handlePostponeAction(payload);
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    final now = DateTime.now();
    var scheduledDate = reminder.dateTime;

    // Si la fecha ya pasó y es un recordatorio único, no programar
    if (scheduledDate.isBefore(now) &&
        reminder.frequency == ReminderFrequency.once) {
      return;
    }

    // Ajustar fecha si ya pasó según la frecuencia
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
      actions: [
        const AndroidNotificationAction(
          'complete',
          'Completado',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
        ),
        const AndroidNotificationAction(
          'postpone',
          'Aplazar 2 min',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Programar según frecuencia
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
        // Para recordatorios personalizados, programar múltiples notificaciones
        await _scheduleCustomReminder(reminder, notificationDetails);
        break;
    }
  }

  Future<void> _scheduleCustomReminder(
    Reminder reminder,
    NotificationDetails details,
  ) async {
    if (reminder.customDays != null && reminder.customDays!.isNotEmpty) {
      // Programar para días específicos de la semana
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
      // Programar cada X días
      var currentDate = reminder.dateTime;
      final now = DateTime.now();

      // Programar las próximas 10 ocurrencias
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

  void _handleCompleteAction(String? reminderId) {
    // Esta función será llamada desde el BLoC
    print('Recordatorio completado: $reminderId');
  }

  void _handlePostponeAction(String? reminderId) {
    // Esta función será llamada desde el BLoC
    print('Recordatorio aplazado: $reminderId');
  }
}
