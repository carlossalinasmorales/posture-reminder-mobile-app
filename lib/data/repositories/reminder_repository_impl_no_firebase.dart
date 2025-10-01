import 'package:dartz/dartz.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/notification_service.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImplNoFirebase implements ReminderRepository {
  final LocalDataSource localDataSource;
  final NotificationService notificationService;

  ReminderRepositoryImplNoFirebase({
    required this.localDataSource,
    required this.notificationService,
  });

  @override
  Future<Either<String, Reminder>> createReminder(Reminder reminder) async {
    try {
      final model = ReminderModel.fromEntity(reminder);

      await localDataSource.insertReminder(model);
      await notificationService.scheduleReminder(reminder);

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
    // Sin Firebase, solo retornamos éxito
    return const Right(null);
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
  Future<Either<String, void>> postponeReminder(
      String id, Duration duration) async {
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
    // Sin Firebase, retornamos stream vacío
    return Stream.value([]);
  }
}
