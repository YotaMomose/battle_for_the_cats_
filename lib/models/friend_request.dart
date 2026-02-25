/// フレンド申請のステータス
enum FriendRequestStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  final String value;
  const FriendRequestStatus(this.value);

  static FriendRequestStatus fromValue(String value) {
    return FriendRequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

/// フレンド申請情報を保持するモデル
class FriendRequest {
  final String id; // ドキュメントID
  final String fromId;
  final String toId;
  final FriendRequestStatus status;
  final String fromName;
  final String fromIconId;
  final DateTime timestamp;

  FriendRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    required this.fromName,
    required this.fromIconId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromId': fromId,
      'toId': toId,
      'status': status.value,
      'fromName': fromName,
      'fromIconId': fromIconId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      id: id,
      fromId: map['fromId'] ?? '',
      toId: map['toId'] ?? '',
      status: FriendRequestStatus.fromValue(map['status'] ?? 'pending'),
      fromName: map['fromName'] ?? 'ゲスト',
      fromIconId: map['fromIconId'] ?? 'cat_orange',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
