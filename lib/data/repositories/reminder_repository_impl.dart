import 'package:dartz/dartz.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/firebase_datasource.dart';
import '../datasources/notification_service.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final LocalDataSource localDataSource;
  final FirebaseDataSource firebaseDataSource;
  final NotificationService notificationService;

  ReminderRepositoryImpl({
    required this.localDataSource,
    required this.firebaseDataSource,
    required this.notificationService,
  });

  @override
  Future<Either<String, Reminder>> createReminder(Reminder reminder) async {
    try {
      final model = ReminderModel.fromEntity(reminder);
      
      // 1. Guardar localmente primero
      await localDataSource.insertReminder(model);
      
      // 2. Programar notificación
      await notificationService.scheduleReminder(reminder);
      
      // 3. Sincronizar con Firebase si está autenticado
      if (firebaseDataSource.isAuthenticated) {
        try {
          await firebaseDataSource.saveReminder(model);
        } catch (e) {
          print('Error sincronizando con Firebase: $e');
          // Continuar aunque falle Firebase
        }
      }

      return Right(reminder);
    } catch (e) {
      return Left('Error al crear recordatorio: $e');
    }
  }

  @override
  Future<Either<String, Reminder>> updateReminder(Reminder reminder) async {
    try {
      final model = ReminderModel.fromEntity(reminder);
      
      await localDataSource.updateReminder(model);
      
      await notificationService.cancelReminder(reminder.id);
      if (reminder.isActive && reminder.status == ReminderStatus.pending) {
        await notificationService.scheduleReminder(reminder);
      }
      
      if (firebaseDataSource.isAuthenticated) {
        try {
          await firebaseDataSource.saveReminder(model);
        } catch (e) {
          print('Error sincronizando con Firebase: $e');
        }
      }

      return Right(reminder);
    } catch (e) {
      return Left('Error al actualizar recordatorio: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteReminder(String id) async {
    try {
      await localDataSource.deleteReminder(id);
      await notificationService.cancelReminder(id);
      
      if (firebaseDataSource.isAuthenticated) {
        try {
          await firebaseDataSource.deleteReminder(id);
        } catch (e) {
          print('Error eliminando de Firebase: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left('Error al eliminar recordatorio: $e');
    }
  }

  @override
  Future<Either<String, List<Reminder>>> getAllReminders() async {
    try {
      final reminders = await localDataSource.getAllReminders();
      return Right(reminders);
    } catch (e) {
      return Left('Error al obtener recordatorios: $e');
    }
  }

  @override
  Future<Either<String, Reminder?>> getReminderById(String id) async {
    try {
      final reminder = await localDataSource.getReminderById(id);
      return Right(reminder);
    } catch (e) {
      return Left('Error al obtener recordatorio: $e');
    }
  }

  @override
  Future<Either<String, List<Reminder>>> getRemindersByStatus(
    ReminderStatus status,
  ) async {
    try {
      final reminders = await localDataSource.getRemindersByStatus(status.name);
      return Right(reminders);
    } catch (e) {
      return Left('Error al obtener recordatorios: $e');
    }
  }

  @override
  Future<Either<String, void>> syncWithFirebase() async {
    if (!firebaseDataSource.isAuthenticated) {
      return const Left('Usuario no autenticado');
    }

    try {
      // Obtener recordatorios locales
      final localReminders = await localDataSource.getAllReminders();
      
      // Obtener recordatorios de Firebase
      final firebaseReminders = await firebaseDataSource.getAllReminders();
      
      // Merge strategy: más reciente gana
      final Map<String, ReminderModel> mergedMap = {};
      
      for (final reminder in localReminders) {
        mergedMap[reminder.id] = reminder;
      }
      
      for (final reminder in firebaseReminders) {
        final local = mergedMap[reminder.id];
        if (local == null || 
            (reminder.updatedAt?.isAfter(local.updatedAt ?? local.createdAt) ?? false)) {
          mergedMap[reminder.id] = reminder;
        }
      }
      
      // Guardar localmente
      for (final reminder in mergedMap.values) {
        await localDataSource.insertReminder(reminder);
      }
      
      // Sincronizar a Firebase
      await firebaseDataSource.syncReminders(mergedMap.values.toList());
      await firebaseDataSource.updateLastSyncTime();
      
      // Re-programar notificaciones
      await _reschedulePendingNotifications(mergedMap.values.toList());

      return const Right(null);
    } catch (e) {
      return Left('Error al sincronizar: $e');
    }
  }

  Future<void> _reschedulePendingNotifications(List<Reminder> reminders) async {
    await notificationService.cancelAllReminders();
    
    for (final reminder in reminders) {
      if (reminder.isActive && reminder.status == ReminderStatus.pending) {
        await notificationService.scheduleReminder(reminder);
      }
    }
  }

  @override
  Future<Either<String, void>> completeReminder(String id) async {
    try {
      final reminder = await localDataSource.getReminderById(id);
      if (reminder == null) {
        return const Left('Recordatorio no encontrado');
      }

      final updated = reminder.copyWith(
        status: ReminderStatus.completed,
        updatedAt: DateTime.now(),
      );

      await updateReminder(updated);
      return const Right(null);
    } catch (e) {
      return Left('Error al completar recordatorio: $e');
    }
  }

  @override
  Future<Either<String, void>> postponeReminder(String id, Duration duration) async {
    try {
      final reminder = await localDataSource.getReminderById(id);
      if (reminder == null) {
        return const Left('Recordatorio no encontrado');
      }

      final postponedUntil = DateTime.now().add(duration);
      final updated = reminder.copyWith(
        status: ReminderStatus.postponed,
        postponedUntil: postponedUntil,
        updatedAt: DateTime.now(),
      );

      await updateReminder(updated);
      
      final postponedReminder = updated.copyWith(
        dateTime: postponedUntil,
      );
      await notificationService.scheduleReminder(postponedReminder);

      return const Right(null);
    } catch (e) {
      return Left('Error al aplazar recordatorio: $e');
    }
  }

  @override
  Future<Either<String, Map<String, int>>> getStatistics() async {
    try {
      final stats = await localDataSource.getStatistics();
      return Right(stats);
    } catch (e) {
      return Left('Error al obtener estadísticas: $e');
    }
  }

  @override
  Stream<List<Reminder>> watchReminders() {
    if (!firebaseDataSource.isAuthenticated) {
      return Stream.value([]);
    }

    try {
      return firebaseDataSource.remindersStream();
    } catch (e) {
      return Stream.value([]);
    }
  }
}