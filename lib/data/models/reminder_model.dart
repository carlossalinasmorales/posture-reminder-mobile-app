import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reminder.dart';

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.title,
    required super.description,
    required super.dateTime,
    required super.frequency,
    required super.status,
    super.customDays,
    super.customInterval,
    super.postponedUntil,
    super.isActive,
    required super.createdAt,
    super.updatedAt,
  });

  // Conversión desde entidad
  factory ReminderModel.fromEntity(Reminder reminder) {
    return ReminderModel(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dateTime: reminder.dateTime,
      frequency: reminder.frequency,
      status: reminder.status,
      customDays: reminder.customDays,
      customInterval: reminder.customInterval,
      postponedUntil: reminder.postponedUntil,
      isActive: reminder.isActive,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    );
  }

  // Conversión a JSON para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'frequency': frequency.name,
      'status': status.name,
      'customDays': customDays,
      'customInterval': customInterval,
      'postponedUntil': postponedUntil?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Conversión desde JSON (almacenamiento local)
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      customDays: json['customDays'] != null
          ? List<int>.from(json['customDays'])
          : null,
      customInterval: json['customInterval'],
      postponedUntil: json['postponedUntil'] != null
          ? DateTime.parse(json['postponedUntil'])
          : null,
      isActive: json['isActive'] == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'frequency': frequency.name,
      'status': status.name,
      'customDays': customDays,
      'customInterval': customInterval,
      'postponedUntil':
          postponedUntil != null ? Timestamp.fromDate(postponedUntil!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Conversión desde Firestore
  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      customDays: data['customDays'] != null
          ? List<int>.from(data['customDays'])
          : null,
      customInterval: data['customInterval'],
      postponedUntil: data['postponedUntil'] != null
          ? (data['postponedUntil'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
