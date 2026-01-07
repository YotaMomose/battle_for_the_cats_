class GameRoom {
  final String roomId;
  final String hostId;
  String? guestId;
  String status; // 'waiting', 'rolling', 'playing', 'roundResult', 'finished'

  // ターン情報
  int currentTurn;
  List<String> hostCatsWon; // ホストが獲得した猫の種類リスト
  List<String> guestCatsWon; // ゲストが獲得した猫の種類リスト

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
  List<int> catCosts; // 各猫の獲得に必要な魚の数

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
    List<String>? hostCatsWon,
    List<String>? guestCatsWon,
    this.hostDiceRoll,
    this.guestDiceRoll,
    this.hostRolled = false,
    this.guestRolled = false,
    this.hostFishCount = 0,
    this.guestFishCount = 0,
    List<String>? cats,
    List<int>? catCosts,
    Map<String, int>? hostBets,
    Map<String, int>? guestBets,
    this.hostReady = false,
    this.guestReady = false,
    this.winners,
    this.finalWinner,
  }) : cats = cats ?? ['通常ネコ', '通常ネコ', '通常ネコ'],
       catCosts = catCosts ?? [1, 1, 1],
       hostCatsWon = hostCatsWon ?? [],
       guestCatsWon = guestCatsWon ?? [],
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
      'catCosts': catCosts,
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
      hostCatsWon: List<String>.from(map['hostCatsWon'] ?? []),
      guestCatsWon: List<String>.from(map['guestCatsWon'] ?? []),
      hostDiceRoll: map['hostDiceRoll'],
      guestDiceRoll: map['guestDiceRoll'],
      hostRolled: map['hostRolled'] ?? false,
      guestRolled: map['guestRolled'] ?? false,
      hostFishCount: map['hostFishCount'] ?? 0,
      guestFishCount: map['guestFishCount'] ?? 0,
      cats: List<String>.from(map['cats'] ?? ['通常ネコ', '通常ネコ', '通常ネコ']),
      catCosts: List<int>.from(map['catCosts'] ?? [1, 1, 1]),
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
