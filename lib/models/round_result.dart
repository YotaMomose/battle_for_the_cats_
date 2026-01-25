import '../constants/game_constants.dart';

/// ラウンドの結果を保持するデータモデル
class RoundResult {
  final List<String> catNames;
  final List<int> catCosts;
  final Map<String, Winner> winners; // '0': Winner.host, '1': Winner.guest, ...
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
      'winners': winners.map((k, v) => MapEntry(k, v.value)),
      'hostBets': hostBets,
      'guestBets': guestBets,
    };
  }

  factory RoundResult.fromMap(Map<String, dynamic> map) {
    return RoundResult(
      catNames: List<String>.from(map['catNames'] ?? []),
      catCosts: List<int>.from(map['catCosts'] ?? []),
      winners: (map['winners'] as Map<dynamic, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k.toString(), Winner.fromString(v.toString())),
      ),
      hostBets: Map<String, int>.from(map['hostBets'] ?? {}),
      guestBets: Map<String, int>.from(map['guestBets'] ?? {}),
    );
  }

  /// 指定したインデックスの勝者を取得
  Winner getWinner(int index) {
    return winners[index.toString()] ?? Winner.draw;
  }

  /// 指定したインデックスの賭け金を取得
  int getBet(int index, String role) {
    final bets = role == 'host' ? hostBets : guestBets;
    return bets[index.toString()] ?? 0;
  }

  /// 指定した役割のこのラウンドでの勝利数を返す
  int getWinCountFor(Winner role) {
    return winners.values.where((v) => v == role).length;
  }
}
