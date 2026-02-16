import 'package:battle_for_the_cats/constants/game_constants.dart';

import '../models/cards/round_cards.dart';
import '../models/cards/game_card.dart';
import '../models/player.dart';
import '../models/round_winners.dart';
import '../models/item.dart';

/// 各猫の勝敗判定を行うクラス
class BattleEvaluator {
  /// 全ての猫について、賭け金とコストを比較して勝者を決定する
  RoundWinners evaluate(RoundCards currentRound, Player host, Player guest) {
    final cards = currentRound.toList();
    final winnersMap = <String, Winner>{};

    for (int i = 0; i < cards.length; i++) {
      final catIndex = i.toString();
      winnersMap[catIndex] = _evaluateSingleCat(
        cards[i],
        catIndex,
        host,
        guest,
      );
    }

    return RoundWinners(winnersMap);
  }

  /// 1匹の猫に対する勝敗を判定する
  Winner _evaluateSingleCat(
    GameCard card,
    String catIndex,
    Player host,
    Player guest,
  ) {
    final hostItem = host.currentBets.getItem(catIndex);
    final guestItem = guest.currentBets.getItem(catIndex);

    // 1. 各種効果を適用した実効コストと実効賭け金を算出
    final effectiveCost = _calculateEffectiveCost(
      card.baseCost,
      hostItem,
      guestItem,
    );
    final (hostBet, guestBet) = _calculateEffectiveBets(
      catIndex,
      host,
      guest,
      hostItem,
      guestItem,
    );

    // 2. ねこじゃらしによる特殊勝利判定
    final teaserWinner = _checkTeaserVictory(
      hostItem,
      guestItem,
      hostBet,
      guestBet,
    );
    if (teaserWinner != null) return teaserWinner;

    // 3. 通常の賭け金比較による勝敗判定
    return _determineWinner(effectiveCost, hostBet, guestBet);
  }

  /// まねきねこの効果を適用したコストを計算
  int _calculateEffectiveCost(
    int cost,
    ItemType? hostItem,
    ItemType? guestItem,
  ) {
    final isLuckyCatActive =
        hostItem == ItemType.luckyCat || guestItem == ItemType.luckyCat;
    return isLuckyCatActive ? cost * 2 : cost;
  }

  /// びっくりホーンの効果を適用した賭け金を算出
  (int, int) _calculateEffectiveBets(
    String catIndex,
    Player host,
    Player guest,
    ItemType? hostItem,
    ItemType? guestItem,
  ) {
    final isSurpriseHornActive =
        hostItem == ItemType.surpriseHorn || guestItem == ItemType.surpriseHorn;

    if (isSurpriseHornActive) {
      return (0, 0);
    }

    return (
      host.currentBets.getBet(catIndex),
      guest.currentBets.getBet(catIndex),
    );
  }

  /// ねこじゃらしによる特殊勝利があるか判定
  Winner? _checkTeaserVictory(
    ItemType? hostItem,
    ItemType? guestItem,
    int hostBet,
    int guestBet,
  ) {
    final hostTeaserWins = hostItem == ItemType.catTeaser && guestBet == 0;
    final guestTeaserWins = guestItem == ItemType.catTeaser && hostBet == 0;

    if (hostTeaserWins && !guestTeaserWins) {
      return Winner.host;
    } else if (guestTeaserWins && !hostTeaserWins) {
      return Winner.guest;
    }
    return null;
  }

  /// 通常の賭け金比較による勝者を決定
  Winner _determineWinner(int cost, int hostBet, int guestBet) {
    final hostQualified = hostBet >= cost;
    final guestQualified = guestBet >= cost;

    if (hostQualified && (!guestQualified || hostBet > guestBet)) {
      return Winner.host;
    } else if (guestQualified && (!hostQualified || guestBet > hostBet)) {
      return Winner.guest;
    } else {
      return Winner.draw;
    }
  }
}
