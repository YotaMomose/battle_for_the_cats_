import '../constants/game_constants.dart';

/// ラウンドの各猫の勝者情報を保持するクラス
class RoundWinners {
  final Map<String, Winner> _winners;

  RoundWinners(this._winners);

  /// 全ての勝者マップを取得（読み取り専用）
  Map<String, Winner> get all => Map.unmodifiable(_winners);

  /// 指定したインデックスの勝者を取得
  Winner at(int index) {
    return _winners[index.toString()] ?? Winner.draw;
  }

  /// 指定した役割の勝利数をカウント
  int countWinsFor(Winner role) {
    return _winners.values.where((v) => v == role).length;
  }

  Map<String, dynamic> toMap() {
    return _winners.map((k, v) => MapEntry(k, v.value));
  }

  factory RoundWinners.fromMap(Map<String, dynamic> map) {
    return RoundWinners(
      map.map(
        (k, v) => MapEntry(k.toString(), Winner.fromString(v.toString())),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundWinners && other._winners.toString() == _winners.toString();

  @override
  int get hashCode => _winners.toString().hashCode;
}
