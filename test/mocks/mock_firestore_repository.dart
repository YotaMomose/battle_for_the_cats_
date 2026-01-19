import 'package:mockito/mockito.dart';
import 'package:battle_for_the_cats/repositories/firestore_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// MockFirestoreRepository: FirestoreRepositoryをモック化
class MockFirestoreRepository extends Mock implements FirestoreRepository {
  /// 保存されたドキュメントの辞書
  final Map<String, Map<String, dynamic>> _documents = {};

  /// queryRoomWithCode呼び出しの履歴
  final List<String> queryCallHistory = [];

  /// addRoom呼び出しの履歴
  final List<Map<String, dynamic>> addCallHistory = [];

  /// updateRoom呼び出しの履歴
  final List<(String, Map<String, dynamic>)> updateFirestoreCallHistory = [];

  /// deleteRoom呼び出しの履歴
  final List<String> deleteFirestoreCallHistory = [];

  /// Firestore Timestamp を生成するヘルパー（テスト用）
  Timestamp createTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  /// 呼び出し履歴をリセット
  void resetCallHistories() {
    queryCallHistory.clear();
    addCallHistory.clear();
    updateFirestoreCallHistory.clear();
    deleteFirestoreCallHistory.clear();
    _documents.clear();
  }

  /// queryRoomWithCodeの呼び出し数を取得
  int get queryRoomCallCount => queryCallHistory.length;

  /// addRoomの呼び出し数を取得
  int get addRoomCallCount => addCallHistory.length;

  /// updateRoomの呼び出し数を取得
  int get updateFirestoreCallCount => updateFirestoreCallHistory.length;

  /// deleteRoomの呼び出し数を取得
  int get deleteFirestoreCallCount => deleteFirestoreCallHistory.length;

  /// setDocument のモック実装
  @override
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    final key = '$collection/$docId';
    _documents[key] = data;
  }

  /// getDocument のモック実装
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String docId,
  ) async {
    final key = '$collection/$docId';
    final data = _documents[key];
    return MockDocumentSnapshot(data);
  }

  /// updateDocument のモック実装
  @override
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final key = '$collection/$docId';
    if (_documents.containsKey(key)) {
      _documents[key]!.addAll(data);
    }
  }

  /// deleteDocument のモック実装
  @override
  Future<void> deleteDocument(String collection, String docId) async {
    final key = '$collection/$docId';
    _documents.remove(key);
  }
}

/// MockDocumentSnapshot: DocumentSnapshot をシミュレート
class MockDocumentSnapshot<T extends Map<String, dynamic>> implements DocumentSnapshot<T> {
  final T? _data;

  MockDocumentSnapshot(this._data);

  @override
  T? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  String get id => '';

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<T> get reference => throw UnimplementedError();

  @override
  dynamic get(Object field) {
    if (_data != null) {
      return _data![field];
    }
    return null;
  }

  @override
  dynamic operator [](Object field) {
    if (_data != null) {
      return _data![field];
    }
    return null;
  }
}
