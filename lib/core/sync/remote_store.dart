import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class RemoteStore {
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data);

  Future<Map<String, Object?>?> get(String uid, String collection, String id);

  Future<List<Map<String, Object?>>> changedSince(String uid, String collection, int since);

  Future<void> putUser(String uid, Map<String, Object?> data);

  Future<void> delete(String uid, String collection, String id);

  Future<List<String>> ids(String uid, String collection);

  Future<void> wipe(String uid, String collection);
}

class FirestoreRemoteStore implements RemoteStore {
  FirestoreRemoteStore(this._db);

  final FirebaseFirestore _db;

  static const _page = 400;
  static const _server = GetOptions(source: Source.server);

  CollectionReference<Map<String, dynamic>> _col(String uid, String collection) =>
      _db.collection('users').doc(uid).collection(collection);

  @override
  Future<void> put(String uid, String collection, String id, Map<String, Object?> data) =>
      _col(uid, collection).doc(id).set(data);

  @override
  Future<void> putUser(String uid, Map<String, Object?> data) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  @override
  Future<void> delete(String uid, String collection, String id) => _col(uid, collection).doc(id).delete();

  @override
  Future<List<String>> ids(String uid, String collection) async => [
    for (final d in (await _col(uid, collection).get(_server)).docs) d.id,
  ];

  @override
  Future<void> wipe(String uid, String collection) async {
    while (true) {
      final snap = await _col(uid, collection).limit(_page).get(_server);
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<Map<String, Object?>?> get(String uid, String collection, String id) async =>
      (await _col(uid, collection).doc(id).get()).data();

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
