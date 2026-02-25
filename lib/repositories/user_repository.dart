import 'dart:math';
import '../repositories/firestore_repository.dart';
import '../models/user_profile.dart';

/// ユーザープロフィールの永続化を担当するリポジトリ
class UserRepository {
  final FirestoreRepository _repository;
  static const String _collection = 'users';

  UserRepository({required FirestoreRepository repository})
    : _repository = repository;

  /// ユーザープロフィールを取得する
  ///
  /// ドキュメントが存在しない場合（初回利用時）は null を返す。
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _repository.getDocument(_collection, uid);
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  /// ユーザープロフィールを保存する
  ///
  /// friendCode が未設定の場合は自動生成する。
  Future<void> saveProfile(UserProfile profile) async {
    var profileToSave = profile;

    // フレンドコードがなければ生成
    if (profile.friendCode == null || profile.friendCode!.isEmpty) {
      final code = await _generateUniqueFriendCode();
      profileToSave = profile.copyWith(friendCode: code);
    }

    await _repository.setDocument(
      _collection,
      profileToSave.uid,
      profileToSave.toMap(),
    );
  }

  /// フレンドコードからユーザーを検索
  Future<UserProfile?> findByFriendCode(String code) async {
    final results = await _repository.query(
      _collection,
      filters: [QueryFilter('friendCode', code.toUpperCase())],
      limit: 1,
    );
    if (results.docs.isEmpty) return null;
    return UserProfile.fromMap(results.docs.first.data());
  }

  /// 一意なフレンドコードを生成
  Future<String> _generateUniqueFriendCode() async {
    int attempts = 0;
    while (attempts < 10) {
      final code = _generateRandomCode();
      final results = await _repository.query(
        _collection,
        filters: [QueryFilter('friendCode', code)],
        limit: 1,
      );
      if (results.docs.isEmpty) return code;
      attempts++;
    }
    // 10回失敗することは稀だが、安全のためタイムスタンプを混ぜる
    return _generateRandomCode() +
        DateTime.now().millisecondsSinceEpoch.toString().substring(10);
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
