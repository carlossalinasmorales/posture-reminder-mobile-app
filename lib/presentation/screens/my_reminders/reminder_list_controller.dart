import 'dart:async';
import '../../../domain/entities/reminder.dart';

/// Controlador para la lógica de la pantalla de lista de recordatorios
class ReminderListController {
  String currentFilterLabel;
  Reminder? deletedReminder;
  Timer? undoTimer;

  ReminderListController({this.currentFilterLabel = 'Todos'});

  /// Obtiene el status del filtro según la etiqueta
  ReminderStatus? getFilterStatus(String label) {
    switch (label) {
      case 'Pendientes':
        return ReminderStatus.pending;
      case 'Completados':
        return ReminderStatus.completed;
      case 'Omitidos':
        return ReminderStatus.skipped;
      case 'Aplazados':
        return ReminderStatus.postponed;
      default:
        return null;
    }
  }

  /// Actualiza el filtro actual
  void updateFilter(String newLabel) {
    currentFilterLabel = newLabel;
  }

  /// Guarda el recordatorio eliminado para deshacer
  void saveDeletedReminder(Reminder reminder) {
    deletedReminder = reminder;
    undoTimer?.cancel();
    undoTimer = Timer(const Duration(seconds: 5), () {
      deletedReminder = null;
    });
  }

  /// Limpia el recordatorio eliminado
  void clearDeletedReminder() {
    deletedReminder = null;
    undoTimer?.cancel();
  }

  /// Obtiene el recordatorio eliminado
  Reminder? getDeletedReminder() {
    return deletedReminder;
  }

  /// Libera recursos
  void dispose() {
    undoTimer?.cancel();
  }
}
