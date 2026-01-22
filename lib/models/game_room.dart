import 'cards/round_cards.dart';
import 'player.dart';

class GameRoom {
  final String roomId;
  String status; // 'waiting', 'rolling', 'playing', 'roundResult', 'finished'
  int currentTurn;

  // プレイヤー情報
  Player host;
  Player? guest;

  // 前回のラウンド情報（画面表示用、個別に次へ進むために必要）
  List<String>? lastRoundCats;
  List<int>? lastRoundCatCosts;
  Map<String, String>? lastRoundWinners;
  Map<String, int>? lastRoundHostBets;
  Map<String, int>? lastRoundGuestBets;

  // 現在のラウンドの3匹の猫
  RoundCards? currentRound;

  // 各猫の勝者（猫のインデックス -> 'host'/'guest'/'draw'）
  Map<String, String>? winners;

  // 最終勝者
  String? finalWinner;

  GameRoom({
    required this.roomId,
    required this.host,
    this.guest,
    this.status = 'waiting',
    this.currentTurn = 1,
    this.lastRoundCats,
    this.lastRoundCatCosts,
    this.lastRoundWinners,
    this.lastRoundHostBets,
    this.lastRoundGuestBets,
    this.currentRound,
    this.winners,
    this.finalWinner,
  });

  String get hostId => host.id;
  String? get guestId => guest?.id;

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'status': status,
      'currentTurn': currentTurn,
      'host': host.toMap(),
      'guest': guest?.toMap(),
      'currentRound': currentRound?.toMap(),
      'winners': winners,
      'finalWinner': finalWinner,
      'lastRoundCats': lastRoundCats,
      'lastRoundCatCosts': lastRoundCatCosts,
      'lastRoundWinners': lastRoundWinners,
      'lastRoundHostBets': lastRoundHostBets,
      'lastRoundGuestBets': lastRoundGuestBets,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      roomId: map['roomId'] ?? '',
      status: map['status'] ?? 'waiting',
      currentTurn: map['currentTurn'] ?? 1,
      host: Player.fromMap(map['host'] ?? {'id': map['hostId'] ?? ''}),
      guest: map['guest'] != null
          ? Player.fromMap(map['guest'])
          : (map['guestId'] != null ? Player(id: map['guestId']) : null),
      currentRound: map['currentRound'] != null
          ? RoundCards.fromMap(map['currentRound'])
          : null,
      winners: map['winners'] != null
          ? Map<String, String>.from(map['winners'])
          : null,
      finalWinner: map['finalWinner'],
      lastRoundCats: map['lastRoundCats'] != null
          ? List<String>.from(map['lastRoundCats'])
          : null,
      lastRoundCatCosts: map['lastRoundCatCosts'] != null
          ? List<int>.from(map['lastRoundCatCosts'])
          : null,
      lastRoundWinners: map['lastRoundWinners'] != null
          ? Map<String, String>.from(map['lastRoundWinners'])
          : null,
      lastRoundHostBets: map['lastRoundHostBets'] != null
          ? Map<String, int>.from(map['lastRoundHostBets'])
          : null,
      lastRoundGuestBets: map['lastRoundGuestBets'] != null
          ? Map<String, int>.from(map['lastRoundGuestBets'])
          : null,
    );
  }

  // ===== Domain Methods =====

  /// 両プレイヤーが準備完了か
  bool get canStartRound => host.ready && (guest?.ready ?? false);

  /// 両プレイヤーがサイコロを振ったか
  bool get bothRolled => host.rolled && (guest?.rolled ?? false);

  /// 両プレイヤーがサイコロ結果を確認したか
  bool get bothConfirmedRoll =>
      host.confirmedRoll && (guest?.confirmedRoll ?? false);

  /// ラウンド結果を自分自身に適用する
  void resolveRound(dynamic result) {
    // GameLogic.RoundResult を想定
    final g = guest;
    if (g == null) return;

    // 獲得情報を個別に保存（画面表示用）
    lastRoundCats = currentRound?.toList().map((c) => c.displayName).toList();
    lastRoundCatCosts = currentRound?.getCosts();
    lastRoundWinners = Map<String, String>.from(result.winners);
    lastRoundHostBets = Map<String, int>.from(host.currentBets);
    lastRoundGuestBets = Map<String, int>.from(g.currentBets);

    // プレイヤーの獲得リストを更新
    for (var i = 0; i < result.hostWonCats.length; i++) {
      host.addWonCat(result.hostWonCats[i], result.hostWonCosts[i]);
    }
    for (var i = 0; i < result.guestWonCats.length; i++) {
      g.addWonCat(result.guestWonCats[i], result.guestWonCosts[i]);
    }

    // ルーム状態を更新
    winners = Map<String, String>.from(result.winners);
    status = result.finalStatus.value;
    finalWinner = result.finalWinner?.value;

    // 確認フラグをリセット
    host.confirmedRoundResult = false;
    g.confirmedRoundResult = false;
  }

  /// 次のターンの準備をする
  void prepareNextTurn(RoundCards nextRoundCards) {
    currentTurn++;
    status = 'rolling';

    host.prepareForNextTurn();
    guest?.prepareForNextTurn();

    currentRound = nextRoundCards;
    winners = null;
  }

  /// 指定されたプレイヤーIDがホストか
  bool isHost(String playerId) => host.id == playerId;
}
