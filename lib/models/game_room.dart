class GameRoom {
  final String roomId;
  final String hostId;
  String? guestId;
  String status; // 'waiting', 'playing', 'finished'
  
  // ゲーム状態
  int hostFishCount;
  int guestFishCount;
  int? hostBet;
  int? guestBet;
  bool hostReady;
  bool guestReady;
  String? winner;

  GameRoom({
    required this.roomId,
    required this.hostId,
    this.guestId,
    this.status = 'waiting',
    this.hostFishCount = 5,
    this.guestFishCount = 5,
    this.hostBet,
    this.guestBet,
    this.hostReady = false,
    this.guestReady = false,
    this.winner,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hostId': hostId,
      'guestId': guestId,
      'status': status,
      'hostFishCount': hostFishCount,
      'guestFishCount': guestFishCount,
      'hostBet': hostBet,
      'guestBet': guestBet,
      'hostReady': hostReady,
      'guestReady': guestReady,
      'winner': winner,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      roomId: map['roomId'] ?? '',
      hostId: map['hostId'] ?? '',
      guestId: map['guestId'],
      status: map['status'] ?? 'waiting',
      hostFishCount: map['hostFishCount'] ?? 5,
      guestFishCount: map['guestFishCount'] ?? 5,
      hostBet: map['hostBet'],
      guestBet: map['guestBet'],
      hostReady: map['hostReady'] ?? false,
      guestReady: map['guestReady'] ?? false,
      winner: map['winner'],
    );
  }
}
