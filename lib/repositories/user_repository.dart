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
  Future<void> saveProfile(UserProfile profile) async {
    await _repository.setDocument(_collection, profile.uid, profile.toMap());
  }
}
