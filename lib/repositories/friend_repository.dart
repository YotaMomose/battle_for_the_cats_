import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/firestore_repository.dart';
import '../models/friend_request.dart';
import '../models/user_profile.dart';
import '../models/friend.dart';
import 'user_repository.dart';

/// フレンド関係と申請を管理するリポジトリ
class FriendRepository {
  final FirestoreRepository _repository;
  static const String _requestCollection = 'friend_requests';
  static const String _usersCollection = 'users';

  FriendRepository({required FirestoreRepository repository})
    : _repository = repository;

  /// フレンド申請を送信
  Future<void> sendFriendRequest(UserProfile from, String toId) async {
    // 既に申請中かチェック
    final existing = await _repository.query(
      _requestCollection,
      filters: [
        QueryFilter('fromId', from.uid),
        QueryFilter('toId', toId),
        QueryFilter('status', FriendRequestStatus.pending.value),
      ],
      limit: 1,
    );

    if (existing.docs.isNotEmpty) {
      throw Exception('既に申請中です');
    }

    final request = FriendRequest(
      id: '', // Firestoreが自動生成
      fromId: from.uid,
      toId: toId,
      status: FriendRequestStatus.pending,
      fromName: from.displayName,
      fromIconId: from.iconId,
      timestamp: DateTime.now(),
    );

    // IDを指定せずに生成（Firestoreの自動生成機能を利用するため set ではなく add 的な挙動が必要）
    // FirestoreRepository に add 的なのがないので、getReference + set
    final ref = FirebaseFirestore.instance.collection(_requestCollection).doc();
    await ref.set(request.toMap());
  }

  /// 自分宛ての申請を監視
  Stream<List<FriendRequest>> watchIncomingRequests(String userId) {
    return FirebaseFirestore.instance
        .collection(_requestCollection)
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.value)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// 申請に回答
  Future<void> respondToRequest(FriendRequest request, bool accept) async {
    final status = accept
        ? FriendRequestStatus.accepted
        : FriendRequestStatus.rejected;

    await _repository.runTransaction((transaction) async {
      final requestRef = _repository.getDocumentReference(
        _requestCollection,
        request.id,
      );

      transaction.update(requestRef, {'status': status.value});

      if (accept) {
        // 相互にフレンド登録
        final myFriendRef = _repository.getDocumentReference(
          _usersCollection,
          '${request.toId}/friends/${request.fromId}',
        );
        final opponentFriendRef = _repository.getDocumentReference(
          _usersCollection,
          '${request.fromId}/friends/${request.toId}',
        );

        transaction.set(myFriendRef, {
          'friendId': request.fromId,
          'winCount': 0,
          'lossCount': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.set(opponentFriendRef, {
          'friendId': request.toId,
          'winCount': 0,
          'lossCount': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// フレンド一覧（戦績付き）を取得
  Future<List<Friend>> getFriendsWithStats(
    String userId,
    UserRepository userRepository,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(userId)
        .collection('friends')
        .get();

    final friends = <Friend>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final friendId = doc.id;
      final profile = await userRepository.getProfile(friendId);
      if (profile != null) {
        friends.add(Friend.fromMap(profile, data));
      }
    }
    return friends;
  }

  /// フレンド一覧を取得
  Future<List<String>> getFriendIds(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(userId)
        .collection('friends')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// 既にフレンドかチェック
  Future<bool> isFriend(String userId, String otherId) async {
    final doc = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(userId)
        .collection('friends')
        .doc(otherId)
        .get();
    return doc.exists;
  }

  /// 対戦結果を記録する
  Future<void> recordMatchResult({
    required String userId,
    required String friendId,
    required bool isWin,
  }) async {
    final friendRef = FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(userId)
        .collection('friends')
        .doc(friendId);

    // ドキュメントが存在する場合のみ更新（フレンドでない場合は記録しない）
    final doc = await friendRef.get();
    if (!doc.exists) return;

    await friendRef.update({
      if (isWin)
        'winCount': FieldValue.increment(1)
      else
        'lossCount': FieldValue.increment(1),
    });
  }
}
