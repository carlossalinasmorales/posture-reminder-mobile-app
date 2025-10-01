import 'package:dartz/dartz.dart';
import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<Either<String, Reminder>> createReminder(Reminder reminder);
  Future<Either<String, Reminder>> updateReminder(Reminder reminder);
  Future<Either<String, void>> deleteReminder(String id);
  Future<Either<String, List<Reminder>>> getAllReminders();
  Future<Either<String, Reminder?>> getReminderById(String id);
  Future<Either<String, List<Reminder>>> getRemindersByStatus(
      ReminderStatus status);
  Future<Either<String, void>> syncWithFirebase();
  Future<Either<String, void>> completeReminder(String id);
  Future<Either<String, void>> postponeReminder(String id, Duration duration);
  Future<Either<String, Map<String, int>>> getStatistics();
  Stream<List<Reminder>> watchReminders();
}
