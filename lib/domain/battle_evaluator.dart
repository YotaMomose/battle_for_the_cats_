import '../models/cards/round_cards.dart';
import '../models/player.dart';
import '../models/round_winners.dart';
import '../constants/game_constants.dart';

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

      final hostBet = host.currentBets[catIndex] ?? 0;
      final guestBet = guest.currentBets[catIndex] ?? 0;

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
