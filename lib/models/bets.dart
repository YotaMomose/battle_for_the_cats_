/// 各猫への賭け金を管理するクラス
class Bets {
  final Map<String, int> _bets;

  Bets([Map<String, int>? bets])
    : _bets = Map.from(bets ?? {'0': 0, '1': 0, '2': 0});

  /// 特定の猫の賭け金を取得
  int getBet(String index) => _bets[index] ?? 0;

  /// 合計賭け金を計算
  int get total => _bets.values.fold(0, (sum, val) => sum + val);

  /// 賭け金を更新（イミュータブルに扱う場合は新インスタンスを返しても良いが、
  /// 現在のプロジェクト方針に合わせてここでは内部状態の更新または
  /// 便利な操作を提供）
  Map<String, int> toMap() => Map.unmodifiable(_bets);

  factory Bets.fromMap(Map<String, dynamic> map) {
    final converted = map.map((key, value) {
      if (value is int) return MapEntry(key, value);
      if (value is String) return MapEntry(key, int.tryParse(value) ?? 0);
      if (value is num) return MapEntry(key, value.toInt());
      return MapEntry(key, 0);
    });
    return Bets(converted);
  }

  /// 0埋めの初期状態
  factory Bets.empty() => Bets({'0': 0, '1': 0, '2': 0});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bets &&
          other._bets.length == _bets.length &&
          _bets.entries.every((e) => other._bets[e.key] == e.value);

  @override
  int get hashCode =>
      Object.hashAll(_bets.entries.map((e) => Object.hash(e.key, e.value)));
}
