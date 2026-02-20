import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../repositories/firestore_repository.dart';
import '../models/user_profile.dart';

/// ユーザープロフィールの永続化を担当するリポジトリ
class UserRepository {
  final FirestoreRepository _repository;
  static const String _collection = 'users';
  static const String _localKey = 'cached_user_profile';

  UserRepository({required FirestoreRepository repository})
    : _repository = repository;

  /// ユーザープロフィールを取得する
  ///
  /// 1. Firestore から取得を試みる
  /// 2. 失敗または不在の場合はローカルキャッシュを返す
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _repository.getDocument(_collection, uid);
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        // 成功したらローカルキャッシュも更新
        await _saveToLocal(profile);
        return profile;
      }
    } catch (e) {
      print('[UserRepository] Firestore取得失敗: $e');
    }

    // Firestore がダメな場合はローカルから取得
    return await _getFromLocal(uid);
  }

  /// ユーザープロフィールを保存する
  /// Firestore と ローカルの両方に保存を試みる。
  Future<void> saveProfile(UserProfile profile) async {
    // 1. ローカルに保存（即座に反映されるように）
    await _saveToLocal(profile);

    // 2. Firestore に保存
    try {
      await _repository.setDocument(_collection, profile.uid, profile.toMap());
    } catch (e) {
      print('[UserRepository] Firestore保存失敗（権限エラー等の可能性）: $e');
    }
  }

  Future<void> _saveToLocal(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(profile.toMap()));
  }

  Future<UserProfile?> _getFromLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localKey);
    if (data == null) return null;

    try {
      final profile = UserProfile.fromMap(jsonDecode(data));
      // IDが一致する場合のみ返す
      return profile.uid == uid ? profile : null;
    } catch (_) {
      return null;
    }
  }
}
