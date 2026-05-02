import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/measurement.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Measurement>> getMeasurements(String uid, {int? limit}) {
    var query = _db
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Measurement.fromMap(d.data(), d.id)).toList());
  }

  Future<int> getMeasurementCount(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<DocumentReference> addMeasurement(String uid, Measurement m) async {
    return await _db
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .add(m.toMap());
  }

  Future<void> deleteMeasurement(String uid, String measurementId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('measurements')
        .doc(measurementId)
        .delete();
  }

  Future<void> updateUserName(String uid, String name) async {
    await _db.collection('users').doc(uid).update({'name': name});
  }
}
