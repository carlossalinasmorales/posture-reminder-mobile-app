import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../../domain/entities/reminder.dart';

const String completeActionId = 'complete';
const String postponeActionId = 'postpone';
const String notificationChannelId = 'posture_reminders';

// MethodChannel para comunicación con código nativo
const MethodChannel _platform = MethodChannel('notification_actions');

// Instancia global para permitir uso en callbacks de background
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
    NotificationResponse notificationResponse) async {
  try {
    // Asegurar zonas horarias disponibles en el isolate de background
    tzdata.initializeTimeZones();
  } catch (_) {
    // ignorar si ya está inicializado
  }

  final String? reminderId = notificationResponse.payload;
  final String? actionId = notificationResponse.actionId;

  if (reminderId == null || actionId == null) return;

  // Construir detalles mínimos para Android/iOS cuando sea necesario reprogramar
  const androidDetails = AndroidNotificationDetails(
    notificationChannelId,
    'Recordatorios de Postura',
    channelDescription:
        'Notificaciones para recordar mantener una buena postura',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  if (actionId == completeActionId) {
    // Cancelar cualquier notificación asociada a este recordatorio
    await notificationsPlugin.cancel(reminderId.hashCode);
  } else if (actionId == postponeActionId) {
    // Reprogramar a +2 minutos con contenido genérico (no tenemos título/descripción aquí)
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    await notificationsPlugin.zonedSchedule(
      reminderId.hashCode,
      'Recordatorio de Postura',
      'Aplazado 2 minutos',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: reminderId,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = notificationsPlugin;

  Function(String reminderId, String action)? onActionReceived;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

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
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Configurar el handler para acciones desde el código nativo
    _platform.setMethodCallHandler(_handleNativeAction);

    await _handleAppLaunchNotification();

    // Verificar acciones pendientes
    await _checkPendingActions();
  }

  // Handler para acciones desde el código nativo de Android
  Future<void> _handleNativeAction(MethodCall call) async {
    if (call.method == 'onNotificationAction') {
      final String reminderId = call.arguments['reminderId'];
      final String action = call.arguments['action'];

      print('🔔 Acción nativa recibida: $action para $reminderId');
      onActionReceived?.call(reminderId, action);
    }
  }

  // Verificar si hay acciones pendientes al iniciar
  Future<void> _checkPendingActions() async {
    try {
      await _platform.invokeMethod('checkPendingActions');
    } catch (e) {
      print('Error verificando acciones pendientes: $e');
    }
  }

  Future<void> _handleAppLaunchNotification() async {
    final notificationAppLaunchDetails =
        await _notifications.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      _onNotificationResponse(
          notificationAppLaunchDetails!.notificationResponse!);
    }
  }

  void _onNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    final actionId = response.actionId;

    print('Notificación respondida - Payload: $payload, ActionId: $actionId');

    if (payload == null || actionId == null) return;

    // Ejecutar lógica directa para asegurar efecto inmediato
    if (actionId == completeActionId) {
      await _notifications.cancel(payload.hashCode);
    } else if (actionId == postponeActionId) {
      // Programar a +2 minutos con contenido genérico
      const androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        'Recordatorios de Postura',
        channelDescription:
            'Notificaciones para recordar mantener una buena postura',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        payload.hashCode,
        'Recordatorio de Postura',
        'Aplazado 2 minutos',
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    }

    // Notificar a capas superiores si están escuchando
    onActionReceived?.call(payload, actionId);
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
      notificationChannelId,
      'Recordatorios de Postura',
      channelDescription:
          'Notificaciones para recordar mantener una buena postura',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        reminder.description,
        contentTitle: reminder.title,
        summaryText: 'Recordatorio de postura',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          completeActionId,
          'Completar',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          postponeActionId,
          'Aplazar 2 min',
          showsUserInterface: true,
          cancelNotification: true,
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

    try {
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
      print('Notificación programada para: $scheduledDate');
    } catch (e) {
      print('Error al programar notificación: $e');
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
      notificationChannelId,
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
