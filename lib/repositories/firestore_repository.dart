import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore の基本操作を抽象化
class FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ドキュメントを取得
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String docId,
  ) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  /// ドキュメントを作成
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  /// ドキュメントを更新
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  /// ドキュメントを削除
  Future<void> deleteDocument(
    String collection,
    String docId,
  ) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// ドキュメントを監視
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  /// クエリを実行
  Future<QuerySnapshot<Map<String, dynamic>>> query(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(filter.field, isEqualTo: filter.value);
      }
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// トランザクションを実行
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    return await _firestore.runTransaction(transactionHandler);
  }

  /// DocumentReference を取得
  DocumentReference<Map<String, dynamic>> getDocumentReference(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId);
  }
}

/// クエリフィルター
class QueryFilter {
  final String field;
  final dynamic value;

  QueryFilter(this.field, this.value);
}
