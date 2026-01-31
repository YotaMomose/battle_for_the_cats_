import '../constants/game_constants.dart';
import 'round_winners.dart';
import 'won_cat.dart';
import 'bets.dart';

/// ラウンドの結果を保持するデータモデル
class RoundResult {
  final List<WonCat> cats;
  final RoundWinners winners;
  final Bets hostBets;
  final Bets guestBets;

  RoundResult({
    required this.cats,
    required this.winners,
    required this.hostBets,
    required this.guestBets,
  });

  Map<String, dynamic> toMap() {
    return {
      'cats': cats.map((c) => c.toMap()).toList(),
      'winners': winners.toMap(),
      'hostBets': hostBets.toMap(),
      'guestBets': guestBets.toMap(),
    };
  }

  factory RoundResult.fromMap(Map<String, dynamic> map) {
    return RoundResult(
      cats:
          (map['cats'] as List?)
              ?.map((c) => WonCat.fromMap(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
      winners: RoundWinners.fromMap(map['winners'] ?? {}),
      hostBets: Bets.fromMap(Map<String, dynamic>.from(map['hostBets'] ?? {})),
      guestBets: Bets.fromMap(
        Map<String, dynamic>.from(map['guestBets'] ?? {}),
      ),
    );
  }

  /// 指定したインデックスの勝者を取得
  Winner getWinner(int index) {
    return winners.at(index);
  }

  /// 指定したインデックスの賭け金を取得
  int getBet(int index, String role) {
    final bets = role == 'host' ? hostBets : guestBets;
    return bets.getBet(index.toString());
  }

  /// 指定した役割のこのラウンドでの勝利数を返す
  int getWinCountFor(Winner role) {
    return winners.countWinsFor(role);
  }
}
