/// 招待情報を保持するモデル
class Invitation {
  final String id;
  final String senderId;
  final String senderName;
  final String senderIconId;
  final String receiverId;
  final String roomCode;
  final DateTime timestamp;
  final bool isExpired;

  Invitation({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderIconId,
    required this.receiverId,
    required this.roomCode,
    required this.timestamp,
    this.isExpired = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderIconId': senderIconId,
      'receiverId': receiverId,
      'roomCode': roomCode,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isExpired': isExpired,
    };
  }

  factory Invitation.fromMap(String id, Map<String, dynamic> map) {
    return Invitation(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'ゲスト',
      senderIconId: map['senderIconId'] ?? 'cat_orange',
      receiverId: map['receiverId'] ?? '',
      roomCode: map['roomCode'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isExpired: map['isExpired'] ?? false,
    );
  }
}
