import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;
  bool get isAuthenticated => currentUser != null;

  CollectionReference get _remindersCollection {
    if (userId == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  // Stream del estado de autenticación
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> saveReminder(ReminderModel reminder) async {
    await _remindersCollection.doc(reminder.id).set(
          reminder.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<List<ReminderModel>> getAllReminders() async {
    final snapshot = await _remindersCollection.get();
    return snapshot.docs
        .map((doc) => ReminderModel.fromFirestore(doc))
        .toList();
  }

  Future<ReminderModel?> getReminderById(String id) async {
    final doc = await _remindersCollection.doc(id).get();
    if (!doc.exists) return null;
    return ReminderModel.fromFirestore(doc);
  }

  Future<void> deleteReminder(String id) async {
    await _remindersCollection.doc(id).delete();
  }

  Stream<List<ReminderModel>> remindersStream() {
    return _remindersCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateReminderStatus(String id, String status) async {
    await _remindersCollection.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncReminders(List<ReminderModel> reminders) async {
    final batch = _firestore.batch();

    for (final reminder in reminders) {
      final docRef = _remindersCollection.doc(reminder.id);
      batch.set(docRef, reminder.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
