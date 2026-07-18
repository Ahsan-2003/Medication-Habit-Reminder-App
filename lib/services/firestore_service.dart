import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';
import '../models/user.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  static Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  static Future<AppUser?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  // --- Invite codes ---
  static Future<void> setInviteCode(String userId, String code) async {
    await _db.collection('users').doc(userId).update({'inviteCode': code});
  }

  static Future<String?> getUserIdByInviteCode(String code) async {
    final snap = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // --- Caregiver linking ---
  static Future<void> linkCaregiver(
    String patientId,
    String caregiverId,
  ) async {
    // Add caregiver to patient's caregiverIds
    await _db.collection('users').doc(patientId).update({
      'caregiverIds': FieldValue.arrayUnion([caregiverId]),
    });
    // Add patient to caregiver's patientIds
    await _db.collection('users').doc(caregiverId).update({
      'patientIds': FieldValue.arrayUnion([patientId]),
    });
  }

  static Future<List<String>> getCaregiverPatientIds(String caregiverId) async {
    final user = await getUser(caregiverId);
    return user?.patientIds ?? [];
  }

  // --- Reminders ---
  static Future<void> addReminder(Reminder r) async {
    await _db.collection('reminders').add(r.toMap());
  }

  static Future<void> updateReminder(Reminder r) async {
    await _db.collection('reminders').doc(r.id).update(r.toMap());
  }

  static Stream<List<Reminder>> getRemindersStream(String userId) {
    return _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Reminder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // --- Adherence ---
  static Future<void> markAdherence(
    String reminderId,
    DateTime date,
    bool taken,
  ) async {
    final key = date.toIso8601String().split('T').first; // yyyy-mm-dd
    await _db
        .collection('reminders')
        .doc(reminderId)
        .collection('adherence')
        .doc(key)
        .set({'taken': taken, 'date': date.toIso8601String()});
  }

  static Future<bool?> getAdherenceForDay(
    String reminderId,
    DateTime date,
  ) async {
    final key = date.toIso8601String().split('T').first;
    final doc = await _db
        .collection('reminders')
        .doc(reminderId)
        .collection('adherence')
        .doc(key)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['taken'] as bool?;
  }

  static Future<List<bool?>> getAdherenceForLastNDays(
    String reminderId,
    int days,
  ) async {
    final now = DateTime.now();
    final results = <bool?>[];
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      results.add(await getAdherenceForDay(reminderId, date));
    }
    return results;
  }

  // For caregiver view – fetch reminders of a specific user
  static Future<List<Reminder>> getRemindersForUser(String userId) async {
    final snap = await _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs
        .map((doc) => Reminder.fromMap(doc.id, doc.data()))
        .toList();
  }
}
