import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class RemoteStore {
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data);

  Future<List<Map<String, Object?>>> changedSince(String uid, String collection, int since);
}

class FirestoreRemoteStore implements RemoteStore {
  FirestoreRemoteStore(this._db);

  final FirebaseFirestore _db;

  static const _page = 400;

  CollectionReference<Map<String, dynamic>> _col(String uid, String collection) =>
      _db.collection('users').doc(uid).collection(collection);

  @override
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data) =>
      _col(uid, collection).doc(id).set(data);

  @override
  Future<List<Map<String, Object?>>> changedSince(String uid, String collection, int since) async {
    final out = <Map<String, Object?>>[];
    var from = since;
    while (true) {
      final snap = await _col(
        uid,
        collection,
      ).where('updated_at', isGreaterThan: from).orderBy('updated_at').limit(_page).get();
      out.addAll(snap.docs.map((d) => d.data()));
      if (snap.docs.length < _page) return out;
      from = (snap.docs.last.data()['updated_at']! as num).toInt();
    }
  }
}
