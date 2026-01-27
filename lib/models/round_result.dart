import '../constants/game_constants.dart';
import 'round_winners.dart';

/// ラウンドの結果を保持するデータモデル
class RoundResult {
  final List<String> catNames;
  final List<int> catCosts;
  final RoundWinners winners;
  final Map<String, int> hostBets;
  final Map<String, int> guestBets;

  RoundResult({
    required this.catNames,
    required this.catCosts,
    required this.winners,
    required this.hostBets,
    required this.guestBets,
  });

  Map<String, dynamic> toMap() {
    return {
      'catNames': catNames,
      'catCosts': catCosts,
      'winners': winners.toMap(),
      'hostBets': hostBets,
      'guestBets': guestBets,
    };
  }

  factory RoundResult.fromMap(Map<String, dynamic> map) {
    return RoundResult(
      catNames: List<String>.from(map['catNames'] ?? []),
      catCosts: List<int>.from(map['catCosts'] ?? []),
      winners: RoundWinners.fromMap(map['winners'] ?? {}),
      hostBets: Map<String, int>.from(map['hostBets'] ?? {}),
      guestBets: Map<String, int>.from(map['guestBets'] ?? {}),
    );
  }

  /// 指定したインデックスの勝者を取得
  Winner getWinner(int index) {
    return winners.at(index);
  }

  /// 指定したインデックスの賭け金を取得
  int getBet(int index, String role) {
    final bets = role == 'host' ? hostBets : guestBets;
    return bets[index.toString()] ?? 0;
  }

  /// 指定した役割のこのラウンドでの勝利数を返す
  int getWinCountFor(Winner role) {
    return winners.countWinsFor(role);
  }
}
