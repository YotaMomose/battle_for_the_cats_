import 'dart:math';
import '../constants/game_constants.dart';
import '../domain/win_condition.dart';
import 'cards/round_cards.dart';
import 'player.dart';
import 'round_result.dart';

class GameRoom {
  final String roomId;
  GameStatus status;
  int currentTurn;

  // プレイヤー情報
  Player host;
  Player? guest;

  // 前回のラウンド情報（画面表示用、個別に次へ進むために必要）
  RoundResult? lastRoundResult;

  // 現在のラウンドの3匹の猫
  RoundCards? currentRound;

  // 各猫の勝者（猫のインデックス -> Winner.host/guest/draw）
  Map<String, Winner>? winners;

  // 最終勝者
  Winner? finalWinner;

  GameRoom({
    required this.roomId,
    required this.host,
    this.guest,
    this.status = GameStatus.waiting,
    this.currentTurn = 1,
    this.lastRoundResult,
    this.currentRound,
    this.winners,
    this.finalWinner,
  });

  String get hostId => host.id;
  String? get guestId => guest?.id;

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'status': status.value,
      'currentTurn': currentTurn,
      'host': host.toMap(),
      'guest': guest?.toMap(),
      'currentRound': currentRound?.toMap(),
      'winners': winners?.map((k, v) => MapEntry(k, v.value)),
      'finalWinner': finalWinner?.value,
      'lastRoundResult': lastRoundResult?.toMap(),
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      roomId: map['roomId'] ?? '',
      status: GameStatus.fromString(map['status'] ?? 'waiting'),
      currentTurn: map['currentTurn'] ?? 1,
      host: Player.fromMap(map['host'] ?? {'id': map['hostId'] ?? ''}),
      guest: map['guest'] != null
          ? Player.fromMap(map['guest'])
          : (map['guestId'] != null ? Player(id: map['guestId']) : null),
      currentRound: map['currentRound'] != null
          ? RoundCards.fromMap(map['currentRound'])
          : null,
      winners: map['winners'] != null
          ? (map['winners'] as Map<dynamic, dynamic>).map(
              (k, v) => MapEntry(k.toString(), Winner.fromString(v.toString())),
            )
          : null,
      finalWinner: map['finalWinner'] != null
          ? Winner.fromString(map['finalWinner'])
          : null,
      lastRoundResult: map['lastRoundResult'] != null
          ? RoundResult.fromMap(map['lastRoundResult'])
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

  /// 両プレイヤーがラウンド結果を確認したか
  bool get bothConfirmedRoundResult =>
      host.confirmedRoundResult && (guest?.confirmedRoundResult ?? false);

  /// ラウンド結果を判定し、自身に適用する
  void resolveRound({WinCondition? winCondition}) {
    final g = guest;
    if (g == null) return;

    final condition = winCondition ?? StandardWinCondition();
    final cards = currentRound?.toList() ?? [];

    // 1. 各猫について勝敗を判定
    final winnersMap = <String, Winner>{};
    final List<String> hostWonNames = [];
    final List<String> guestWonNames = [];
    final List<int> hostWonCosts = [];
    final List<int> guestWonCosts = [];

    for (int i = 0; i < cards.length; i++) {
      final catIndex = i.toString();
      final card = cards[i];
      final cost = card.baseCost;

      final hostBet = host.currentBets[catIndex] ?? 0;
      final guestBet = g.currentBets[catIndex] ?? 0;

      final hostQualified = hostBet >= cost;
      final guestQualified = guestBet >= cost;

      if (hostQualified && (!guestQualified || hostBet > guestBet)) {
        winnersMap[catIndex] = Winner.host;
        hostWonNames.add(card.displayName);
        hostWonCosts.add(cost);
      } else if (guestQualified && (!hostQualified || guestBet > hostBet)) {
        winnersMap[catIndex] = Winner.guest;
        guestWonNames.add(card.displayName);
        guestWonCosts.add(cost);
      } else {
        winnersMap[catIndex] = Winner.draw;
      }
    }

    // 獲得情報を画面表示用に保存
    lastRoundResult = RoundResult(
      catNames: cards.map((c) => c.displayName).toList(),
      catCosts: currentRound?.getCosts() ?? [],
      winners: Map<String, Winner>.from(winnersMap),
      hostBets: Map<String, int>.from(host.currentBets),
      guestBets: Map<String, int>.from(g.currentBets),
    );

    // プレイヤーの獲得リストを更新
    for (var i = 0; i < hostWonNames.length; i++) {
      host.addWonCat(hostWonNames[i], hostWonCosts[i]);
    }
    for (var i = 0; i < guestWonNames.length; i++) {
      g.addWonCat(guestWonNames[i], guestWonCosts[i]);
    }

    // 最終勝利判定
    final hostWins = condition.checkWin(host.catsWon);
    final guestWins = condition.checkWin(g.catsWon);

    if (hostWins && guestWins) {
      // 両者勝利時は合計コストで判定
      final hostTotalCost = host.wonCatCosts.fold(0, (a, b) => a + b);
      final guestTotalCost = g.wonCatCosts.fold(0, (a, b) => a + b);
      if (hostTotalCost > guestTotalCost) {
        finalWinner = Winner.host;
      } else if (guestTotalCost > hostTotalCost) {
        finalWinner = Winner.guest;
      } else {
        finalWinner = Winner.draw;
      }
      status = GameStatus.finished;
    } else if (hostWins) {
      finalWinner = Winner.host;
      status = GameStatus.finished;
    } else if (guestWins) {
      finalWinner = Winner.guest;
      status = GameStatus.finished;
    } else {
      status = GameStatus.roundResult;
    }

    winners = winnersMap;

    // 確認フラグをリセット
    host.confirmedRoundResult = false;
    g.confirmedRoundResult = false;
  }

  /// 次のターンの準備をする
  void prepareNextTurn(RoundCards nextRoundCards) {
    currentTurn++;
    status = GameStatus.rolling;

    host.prepareForNextTurn();
    guest?.prepareForNextTurn();

    currentRound = nextRoundCards;
    winners = null;
  }

  /// 指定されたプレイヤーIDがホストか
  bool isHost(String playerId) => host.id == playerId;

  /// ランダムなルームID（6桁の英数字）を生成
  static String generateRandomId() {
    final random = Random();
    return List.generate(
      GameConstants.roomCodeLength,
      (index) =>
          GameConstants.roomCodeChars[random.nextInt(
            GameConstants.roomCodeChars.length,
          )],
    ).join();
  }
}
