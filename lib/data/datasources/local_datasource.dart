import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder_model.dart';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._internal();
  factory LocalDataSource() => _instance;
  LocalDataSource._internal();

  static const String _remindersKey = 'reminders';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'posture_reminders.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            frequency TEXT NOT NULL,
            status TEXT NOT NULL,
            customDays TEXT,
            customInterval INTEGER,
            postponedUntil TEXT,
            isActive INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  // SQLite Operations
  Future<void> insertReminder(ReminderModel reminder) async {
    final db = await database;
    final json = reminder.toJson();

    // Convertir listas a JSON strings
    if (json['customDays'] != null) {
      json['customDays'] = jsonEncode(json['customDays']);
    }

    await db.insert(
      'reminders',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // También guardar en SharedPreferences como backup
    await _saveToSharedPreferences();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final db = await database;
    final json = reminder.toJson();

    if (json['customDays'] != null) {
      json['customDays'] = jsonEncode(json['customDays']);
    }

    await db.update(
      'reminders',
      json,
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    await _saveToSharedPreferences();
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _saveToSharedPreferences();
  }

  Future<List<ReminderModel>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');

    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);

      // Convertir JSON strings de vuelta a listas
      if (modifiedMap['customDays'] != null &&
          modifiedMap['customDays'] is String) {
        modifiedMap['customDays'] = jsonDecode(modifiedMap['customDays']);
      }

      return ReminderModel.fromJson(modifiedMap);
    }).toList();
  }

  Future<ReminderModel?> getReminderById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = Map<String, dynamic>.from(maps.first);
    if (map['customDays'] != null && map['customDays'] is String) {
      map['customDays'] = jsonDecode(map['customDays']);
    }

    return ReminderModel.fromJson(map);
  }

  Future<List<ReminderModel>> getRemindersByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'status = ?',
      whereArgs: [status],
    );

    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap['customDays'] != null &&
          modifiedMap['customDays'] is String) {
        modifiedMap['customDays'] = jsonDecode(modifiedMap['customDays']);
      }
      return ReminderModel.fromJson(modifiedMap);
    }).toList();
  }

  // SharedPreferences backup
  Future<void> _saveToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await getAllReminders();
    final remindersJson = reminders.map((r) => r.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(remindersJson));
  }

  Future<List<ReminderModel>> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersString = prefs.getString(_remindersKey);

    if (remindersString == null) return [];

    final List<dynamic> remindersJson = jsonDecode(remindersString);
    return remindersJson.map((json) => ReminderModel.fromJson(json)).toList();
  }

  // Sincronizar desde SharedPreferences a SQLite (útil al iniciar la app)
  Future<void> syncFromSharedPreferences() async {
    final reminders = await loadFromSharedPreferences();
    final db = await database;

    for (final reminder in reminders) {
      final json = reminder.toJson();
      if (json['customDays'] != null) {
        json['customDays'] = jsonEncode(json['customDays']);
      }

      await db.insert(
        'reminders',
        json,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('reminders');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
  }

  // Estadísticas
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final total = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM reminders WHERE isActive = 1')) ??
        0;

    final pending = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE status = ? AND isActive = 1',
            ['pending'])) ??
        0;

    final completed = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE status = ?',
            ['completed'])) ??
        0;

    final skipped = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM reminders WHERE status = ?', ['skipped'])) ??
        0;

    return {
      'total': total,
      'pending': pending,
      'completed': completed,
      'skipped': skipped,
    };
  }
}
