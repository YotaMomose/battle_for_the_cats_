import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invitation.dart';
import '../models/user_profile.dart';

/// ゲームへの招待を管理するサービス
class InvitationService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invitations';

  InvitationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 招待を送信
  Future<void> sendInvitation({
    required UserProfile sender,
    required String receiverId,
    required String roomCode,
  }) async {
    final invitation = Invitation(
      id: '', // 自動生成
      senderId: sender.uid,
      senderName: sender.displayName,
      senderIconId: sender.iconId,
      receiverId: receiverId,
      roomCode: roomCode,
      timestamp: DateTime.now(),
    );

    await _firestore.collection(_collection).add(invitation.toMap());
  }

  /// 自分宛ての招待をリアルタイム監視
  Stream<List<Invitation>> watchInvitations(String userId) {
    // 過去10分以内の未期限の招待のみ取得
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));

    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('isExpired', isEqualTo: false)
        .where('timestamp', isGreaterThan: tenMinutesAgo.millisecondsSinceEpoch)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Invitation.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// 招待を無効化（参加済み、または拒否）
  Future<void> expireInvitation(String invitationId) async {
    await _firestore.collection(_collection).doc(invitationId).update({
      'isExpired': true,
    });
  }

  /// 古い招待をクリーンアップ
  Future<void> cleanupOldInvitations(String userId) async {
    // 30分以上前の招待をすべて削除、または無効化
    final thirtyMinutesAgo = DateTime.now().subtract(
      const Duration(minutes: 30),
    );

    final batch = _firestore.batch();
    final oldDocs = await _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('timestamp', isLessThan: thirtyMinutesAgo.millisecondsSinceEpoch)
        .get();

    for (var doc in oldDocs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
