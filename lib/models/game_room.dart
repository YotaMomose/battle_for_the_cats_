import 'dart:math';
import '../constants/game_constants.dart';
import '../domain/win_condition.dart';
import 'cards/round_cards.dart';
import 'player.dart';
import 'bets.dart';
import 'round_result.dart';
import 'round_winners.dart';
import 'won_cat.dart';
import 'chased_card_info.dart';
import '../domain/battle_evaluator.dart';
import 'cards/card_type.dart';

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

  // 犬の効果で逃がされたカード（通知用）
  List<ChasedCardInfo> chasedCards;

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
    List<ChasedCardInfo>? chasedCards,
  }) : chasedCards = chasedCards ?? [];

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
      'chasedCards': chasedCards.map((c) => c.toMap()).toList(),
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
      chasedCards: (map['chasedCards'] as List?)
          ?.map((c) => ChasedCardInfo.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
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

  /// 両者がラウンド結果を確認したか
  bool get bothConfirmedRoundResult =>
      host.confirmedRoundResult && (guest?.confirmedRoundResult ?? false);

  /// 両者が太っちょネコイベントを確認したか
  bool get bothConfirmedFatCatEvent =>
      host.confirmedFatCatEvent && (guest?.confirmedFatCatEvent ?? false);

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

    // 3. コストの支払い（魚とアイテム消費）
    host.payCosts();
    g.payCosts();

    // 4. プレイヤーへの猫の付与
    _applyRoundWinners(winnersMap);

    // 5. 最終勝利判定 (Domain Object)
    // 犬の効果がある場合は、効果発動後に判定するため一旦保留
    final hasPendingDogEffects =
        host.pendingDogChases > 0 || g.pendingDogChases > 0;

    if (!hasPendingDogEffects) {
      finalWinner = condition.determineFinalWinner(host, g);
      if (finalWinner != null) {
        status = GameStatus.finished;
      } else {
        status = GameStatus.roundResult;
      }
    } else {
      finalWinner = null;
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
        if (card.cardType == CardType.itemShop ||
            card.cardType == CardType.bossKitty) {
          host.pendingItemRevivals++;
        }
        if (card.cardType == CardType.fisherman) {
          host.fishermanCount++;
        }
        if (card.cardType == CardType.dog) {
          host.pendingDogChases++;
        }
      } else if (winner == Winner.guest) {
        guest?.addWonCat(card.displayName, card.baseCost);
        if (card.cardType == CardType.itemShop ||
            card.cardType == CardType.bossKitty) {
          guest?.pendingItemRevivals++;
        }
        if (card.cardType == CardType.fisherman) {
          guest?.fishermanCount++;
        }
        if (card.cardType == CardType.dog) {
          guest?.pendingDogChases++;
        }
      }
    }
  }

  /// 次のターンの準備をする
  void prepareNextTurn(RoundCards nextRoundCards) {
    currentTurn++;
    status = GameStatus.rolling;

    host.resetRoundState();
    guest?.resetRoundState();

    currentRound = nextRoundCards;
    winners = null;
    chasedCards.clear();
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
