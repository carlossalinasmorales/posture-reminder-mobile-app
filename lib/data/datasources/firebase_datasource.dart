import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  CollectionReference get _remindersCollection {
    if (userId == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  // Autenticación anónima
  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Crear o actualizar recordatorio
  Future<void> saveReminder(ReminderModel reminder) async {
    await _remindersCollection.doc(reminder.id).set(
          reminder.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // Obtener todos los recordatorios
  Future<List<ReminderModel>> getAllReminders() async {
    final snapshot = await _remindersCollection.get();
    return snapshot.docs
        .map((doc) => ReminderModel.fromFirestore(doc))
        .toList();
  }

  // Obtener recordatorio por ID
  Future<ReminderModel?> getReminderById(String id) async {
    final doc = await _remindersCollection.doc(id).get();
    if (!doc.exists) return null;
    return ReminderModel.fromFirestore(doc);
  }

  // Eliminar recordatorio
  Future<void> deleteReminder(String id) async {
    await _remindersCollection.doc(id).delete();
  }

  // Stream para sincronización en tiempo real
  Stream<List<ReminderModel>> remindersStream() {
    return _remindersCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Actualizar estado del recordatorio
  Future<void> updateReminderStatus(String id, String status) async {
    await _remindersCollection.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Sincronización batch
  Future<void> syncReminders(List<ReminderModel> reminders) async {
    final batch = _firestore.batch();

    for (final reminder in reminders) {
      final docRef = _remindersCollection.doc(reminder.id);
      batch.set(docRef, reminder.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Obtener última fecha de sincronización
  Future<DateTime?> getLastSyncTime() async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('metadata')
        .doc('sync')
        .get();

    if (!doc.exists) return null;

    final timestamp = doc.data()?['lastSync'] as Timestamp?;
    return timestamp?.toDate();
  }

  // Actualizar última fecha de sincronización
  Future<void> updateLastSyncTime() async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('metadata')
        .doc('sync')
        .set({
      'lastSync': FieldValue.serverTimestamp(),
    });
  }
}
