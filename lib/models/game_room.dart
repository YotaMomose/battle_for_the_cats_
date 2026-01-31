import 'dart:math';
import '../constants/game_constants.dart';
import '../domain/win_condition.dart';
import 'cards/round_cards.dart';
import 'player.dart';
import 'bets.dart';
import 'round_result.dart';
import 'round_winners.dart';
import 'won_cat.dart';
import '../domain/battle_evaluator.dart';

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

  // 各猫の勝者
  RoundWinners? winners;

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
      'winners': winners?.toMap(),
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
          ? RoundWinners.fromMap(map['winners'])
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
    final evaluator = BattleEvaluator();

    // 1. 各猫について勝敗を判定 (Domain Service)
    final winnersMap = evaluator.evaluate(currentRound!, host, g);

    // 2. 履歴の記録
    _recordRoundResult(winnersMap);

    // 3. プレイヤーへの猫の付与
    _applyRoundWinners(winnersMap);

    // 4. 最終勝利判定 (Domain Object)
    finalWinner = condition.determineFinalWinner(host, g);
    if (finalWinner != null) {
      status = GameStatus.finished;
    } else {
      status = GameStatus.roundResult;
    }

    winners = winnersMap;

    // 確認フラグをリセット
    host.confirmedRoundResult = false;
    g.confirmedRoundResult = false;
  }

  /// 獲得情報（履歴）を保存する
  void _recordRoundResult(RoundWinners winnersMap) {
    final cards = currentRound?.toList() ?? [];
    lastRoundResult = RoundResult(
      cats: cards
          .map((c) => WonCat(name: c.displayName, cost: c.baseCost))
          .toList(),
      winners: winnersMap,
      hostBets: host.currentBets,
      guestBets: guest?.currentBets ?? Bets.empty(),
    );
  }

  /// 勝者に基づいてプレイヤーに猫とコストを付与する
  void _applyRoundWinners(RoundWinners winnersMap) {
    final cards = currentRound?.toList() ?? [];
    for (int i = 0; i < cards.length; i++) {
      final winner = winnersMap.at(i);
      final card = cards[i];
      if (winner == Winner.host) {
        host.addWonCat(card.displayName, card.baseCost);
      } else if (winner == Winner.guest) {
        guest?.addWonCat(card.displayName, card.baseCost);
      }
    }
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
