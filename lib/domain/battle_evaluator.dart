import 'package:battle_for_the_cats/constants/game_constants.dart';

import '../models/cards/round_cards.dart';
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
      final card = cards[i];
      final cost = card.baseCost;

      final hostBet = host.currentBets.getBet(catIndex);
      final guestBet = guest.currentBets.getBet(catIndex);

      final hostItem = host.currentBets.getItem(catIndex);
      final guestItem = guest.currentBets.getItem(catIndex);

      // --- ねこじゃらしの効果 ---
      // 相手が魚を置いていなければ、ねこじゃらし使用者が無条件勝利
      final hostTeaserWins = hostItem == ItemType.catTeaser && guestBet == 0;
      final guestTeaserWins = guestItem == ItemType.catTeaser && hostBet == 0;

      if (hostTeaserWins && !guestTeaserWins) {
        winnersMap[catIndex] = Winner.host;
        continue;
      } else if (guestTeaserWins && !hostTeaserWins) {
        winnersMap[catIndex] = Winner.guest;
        continue;
      }
      // 両者がねこじゃらしを使い、両者の魚が0の場合は引き分け（通常ロジックへ）
      // -----------------------

      final hostQualified = hostBet >= cost;
      final guestQualified = guestBet >= cost;

      if (hostQualified && (!guestQualified || hostBet > guestBet)) {
        winnersMap[catIndex] = Winner.host;
      } else if (guestQualified && (!hostQualified || guestBet > hostBet)) {
        winnersMap[catIndex] = Winner.guest;
      } else {
        winnersMap[catIndex] = Winner.draw;
      }
    }

    return RoundWinners(winnersMap);
  }
}
