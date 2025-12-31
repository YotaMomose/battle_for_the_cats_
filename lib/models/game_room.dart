class GameRoom {
  final String roomId;
  final String hostId;
  String? guestId;
  String status; // 'waiting', 'rolling', 'playing', 'roundResult', 'finished'

  // ターン情報
  int currentTurn;
  int hostCatsWon; // ホストが獲得した猫の累計数
  int guestCatsWon; // ゲストが獲得した猫の累計数

  // サイコロ
  int? hostDiceRoll; // ホストのサイコロの目（1-6）
  int? guestDiceRoll; // ゲストのサイコロの目（1-6）
  bool hostRolled; // ホストがサイコロを振ったか
  bool guestRolled; // ゲストがサイコロを振ったか

  // ゲーム状態
  int hostFishCount;
  int guestFishCount;

  // 3匹の猫（猫の種類を格納）
  List<String> cats;

  // 各プレイヤーの各猫への賭け（猫のインデックス -> 魚の数）
  Map<String, int> hostBets;
  Map<String, int> guestBets;

  bool hostReady;
  bool guestReady;

  // 各猫の勝者（猫のインデックス -> 'host'/'guest'/'draw'）
  Map<String, String>? winners;

  // 最終勝者
  String? finalWinner;

  GameRoom({
    required this.roomId,
    required this.hostId,
    this.guestId,
    this.status = 'waiting',
    this.currentTurn = 1,
    this.hostCatsWon = 0,
    this.guestCatsWon = 0,
    this.hostDiceRoll,
    this.guestDiceRoll,
    this.hostRolled = false,
    this.guestRolled = false,
    this.hostFishCount = 5,
    this.guestFishCount = 5,
    List<String>? cats,
    Map<String, int>? hostBets,
    Map<String, int>? guestBets,
    this.hostReady = false,
    this.guestReady = false,
    this.winners,
    this.finalWinner,
  }) : cats = cats ?? ['通常ネコ', '通常ネコ', '通常ネコ'],
       hostBets = hostBets ?? {'0': 0, '1': 0, '2': 0},
       guestBets = guestBets ?? {'0': 0, '1': 0, '2': 0};

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hostId': hostId,
      'guestId': guestId,
      'status': status,
      'currentTurn': currentTurn,
      'hostCatsWon': hostCatsWon,
      'guestCatsWon': guestCatsWon,
      'hostDiceRoll': hostDiceRoll,
      'guestDiceRoll': guestDiceRoll,
      'hostRolled': hostRolled,
      'guestRolled': guestRolled,
      'hostFishCount': hostFishCount,
      'guestFishCount': guestFishCount,
      'cats': cats,
      'hostBets': hostBets,
      'guestBets': guestBets,
      'hostReady': hostReady,
      'guestReady': guestReady,
      'winners': winners,
      'finalWinner': finalWinner,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      roomId: map['roomId'] ?? '',
      hostId: map['hostId'] ?? '',
      guestId: map['guestId'],
      status: map['status'] ?? 'waiting',
      currentTurn: map['currentTurn'] ?? 1,
      hostCatsWon: map['hostCatsWon'] ?? 0,
      guestCatsWon: map['guestCatsWon'] ?? 0,
      hostDiceRoll: map['hostDiceRoll'],
      guestDiceRoll: map['guestDiceRoll'],
      hostRolled: map['hostRolled'] ?? false,
      guestRolled: map['guestRolled'] ?? false,
      hostFishCount: map['hostFishCount'] ?? 5,
      guestFishCount: map['guestFishCount'] ?? 5,
      cats: List<String>.from(map['cats'] ?? ['通常ネコ', '通常ネコ', '通常ネコ']),
      hostBets: Map<String, int>.from(
        map['hostBets'] ?? {'0': 0, '1': 0, '2': 0},
      ),
      guestBets: Map<String, int>.from(
        map['guestBets'] ?? {'0': 0, '1': 0, '2': 0},
      ),
      hostReady: map['hostReady'] ?? false,
      guestReady: map['guestReady'] ?? false,
      winners: map['winners'] != null
          ? Map<String, String>.from(map['winners'])
          : null,
      finalWinner: map['finalWinner'],
    );
  }
}
