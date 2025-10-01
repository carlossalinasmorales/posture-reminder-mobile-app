import 'package:equatable/equatable.dart';

enum ReminderFrequency {
  once,
  daily,
  weekly,
  custom,
}

enum ReminderStatus {
  pending,
  completed,
  skipped,
  postponed,
}

class Reminder extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final ReminderFrequency frequency;
  final ReminderStatus status;
  final List<int>?
      customDays; // Para frecuencias personalizadas (1=Lunes, 7=Domingo)
  final int? customInterval; // Para "cada X días"
  final DateTime? postponedUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.frequency,
    required this.status,
    this.customDays,
    this.customInterval,
    this.postponedUntil,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderFrequency? frequency,
    ReminderStatus? status,
    List<int>? customDays,
    int? customInterval,
    DateTime? postponedUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      customDays: customDays ?? this.customDays,
      customInterval: customInterval ?? this.customInterval,
      postponedUntil: postponedUntil ?? this.postponedUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dateTime,
        frequency,
        status,
        customDays,
        customInterval,
        postponedUntil,
        isActive,
        createdAt,
        updatedAt,
      ];
}
