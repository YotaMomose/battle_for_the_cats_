import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// ユーザー認証サービス
///
/// Firebase Anonymous Auth を試み、失敗した場合は
/// SharedPreferences に UUID を保存してフォールバックする。
/// どちらの場合でも永続的なユーザーIDを提供する。
class AuthService {
  static const String _localUserIdKey = 'local_user_id';

  String? _userId;

  /// 現在のユーザーID（未初期化の場合は null）
  String? get currentUserId => _userId;

  /// 認証済みかどうか
  bool get isAuthenticated => _userId != null;

  /// 認証を初期化する
  ///
  /// 1. Firebase Auth の既存セッションを確認
  /// 2. なければ匿名サインインを試行
  /// 3. Firebase Auth が使えなければ SharedPreferences にフォールバック
  Future<String> initialize() async {
    // 既に初期化済みならそのまま返す
    if (_userId != null) return _userId!;

    // Firebase Auth を試す
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        _userId = auth.currentUser!.uid;
        return _userId!;
      }

      final credential = await auth.signInAnonymously();
      _userId = credential.user!.uid;
      return _userId!;
    } catch (_) {
      // Firebase Auth が使えない場合（デスクトップ環境等）はローカルIDにフォールバック
    }

    // SharedPreferences フォールバック
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_localUserIdKey);
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString(_localUserIdKey, _userId!);
    }
    return _userId!;
  }
}
