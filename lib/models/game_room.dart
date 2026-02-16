import 'dart:math';
import '../constants/game_constants.dart';
import 'cards/round_cards.dart';
import 'player.dart';
import 'bets.dart';
import 'round_result.dart';
import 'round_winners.dart';
import 'won_cat.dart';
import 'chased_card_info.dart';
import 'cards/card_type.dart';
import 'cards/game_card.dart';

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

  // ===== Domain Methods =====

  /// ラウンドの結果をルームの状態に反映する
  void applyRoundResults(RoundWinners winnersMap) {
    this.winners = winnersMap;

    // 1. 履歴の記録
    final cards = currentRound?.toList() ?? [];
    lastRoundResult = RoundResult(
      cats: cards
          .map((c) => WonCat(name: c.displayName, cost: c.baseCost))
          .toList(),
      winners: winnersMap,
      hostBets: host.currentBets,
      guestBets: guest?.currentBets ?? Bets.empty(),
    );

    // 2. コストの支払い（魚とアイテム消費）
    host.payCosts();
    guest?.payCosts();

    // 3. プレイヤーへの猫・特殊効果の付与
    for (int i = 0; i < cards.length; i++) {
      final winner = winnersMap.at(i);
      final card = cards[i];
      if (winner == Winner.host) {
        _assignCardToPlayer(host, card);
      } else if (winner == Winner.guest && guest != null) {
        _assignCardToPlayer(guest!, card);
      }
    }

    // 4. 確認フラグのリセット
    host.confirmedRoundResult = false;
    guest?.confirmedRoundResult = false;
  }

  /// 指定したプレイヤーにカードを付与し、特殊効果の保留数を更新する
  void _assignCardToPlayer(Player player, GameCard card) {
    player.addWonCat(card.displayName, card.baseCost);

    switch (card.cardType) {
      case CardType.itemShop:
      case CardType.bossKitty:
        player.pendingItemRevivals++;
        break;
      case CardType.fisherman:
        player.fishermanCount++;
        break;
      case CardType.dog:
        player.pendingDogChases++;
        break;
      default:
        break;
    }
  }

  /// ラウンド終了後のステータスと最終勝者を更新する
  void updatePostRoundState(
    Winner? newFinalWinner, {
    required bool hasPendingEffects,
  }) {
    finalWinner = newFinalWinner;
    if (finalWinner != null) {
      status = GameStatus.finished;
    } else {
      status = GameStatus.roundResult;
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
