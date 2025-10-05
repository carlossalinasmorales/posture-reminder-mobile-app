import 'dart:async';
import 'package:flutter/material.dart';
import '/../domain/entities/reminder.dart';

/// Controlador que maneja toda la lógica del formulario de recordatorios
class ReminderFormController {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final GlobalKey<FormState> formKey;
  
  DateTime selectedDateTime;
  ReminderFrequency frequency;
  List<int> selectedDays;
  int? customInterval;
  
  Timer? _debounceTimer;
  final VoidCallback? onAutoSave;
  
  ReminderFormController({
    Reminder? initialReminder,
    this.onAutoSave,
  })  : titleController = TextEditingController(text: initialReminder?.title ?? ''),
        descriptionController = TextEditingController(text: initialReminder?.description ?? ''),
        formKey = GlobalKey<FormState>(),
        selectedDateTime = initialReminder?.dateTime ?? DateTime.now().add(const Duration(hours: 1)),
        frequency = initialReminder?.frequency ?? ReminderFrequency.once,
        selectedDays = initialReminder?.customDays ?? [],
        customInterval = initialReminder?.customInterval;

  bool get isEditing => onAutoSave != null;

  /// Valida el formulario
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Valida frecuencia personalizada
  bool validateCustomFrequency() {
    if (frequency == ReminderFrequency.custom) {
      return selectedDays.isNotEmpty || customInterval != null;
    }
    return true;
  }

  /// Actualiza la fecha seleccionada
  void updateDate(DateTime newDate) {
    selectedDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      selectedDateTime.hour,
      selectedDateTime.minute,
    );
    _triggerAutoSave();
  }

  /// Actualiza la hora seleccionada
  void updateTime(TimeOfDay newTime) {
    selectedDateTime = DateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
      newTime.hour,
      newTime.minute,
    );
    _triggerAutoSave();
  }

  /// Actualiza la frecuencia
  void updateFrequency(ReminderFrequency newFrequency) {
    frequency = newFrequency;
    _triggerAutoSave();
  }

  /// Actualiza días seleccionados
  void updateDays(List<int> days) {
    selectedDays = days;
    customInterval = null;
    _triggerAutoSave();
  }

  /// Actualiza intervalo personalizado
  void updateCustomInterval(int? interval) {
    customInterval = interval;
    if (interval != null) {
      selectedDays = [];
    }
    _triggerAutoSave();
  }

  /// Trigger de auto-guardado con debounce
  void _triggerAutoSave() {
    if (!isEditing) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (_canAutoSave()) {
          onAutoSave?.call();
        }
      },
    );
  }

  /// Verifica si se puede auto-guardar
  bool _canAutoSave() {
    if (titleController.text.trim().isEmpty) return false;
    if (descriptionController.text.trim().isEmpty) return false;
    if (!validateCustomFrequency()) return false;
    return true;
  }

  /// Crea un objeto Reminder con los datos actuales
  Reminder toReminder({String? id, DateTime? createdAt, ReminderStatus? status}) {
    return Reminder(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dateTime: selectedDateTime,
      frequency: frequency,
      customDays: frequency == ReminderFrequency.custom ? selectedDays : null,
      customInterval: frequency == ReminderFrequency.custom ? customInterval : null,
      isActive: true,
      status: status ?? ReminderStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Libera recursos
  void dispose() {
    _debounceTimer?.cancel();
    titleController.dispose();
    descriptionController.dispose();
  }
}