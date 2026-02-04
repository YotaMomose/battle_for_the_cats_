import 'item.dart';

/// 各猫への賭け金を管理するクラス
class Bets {
  final Map<String, int> _bets;
  final Map<String, ItemType?> _itemPlacements;

  Bets([Map<String, int>? bets, Map<String, ItemType?>? itemPlacements])
    : _bets = Map.from(bets ?? {'0': 0, '1': 0, '2': 0}),
      _itemPlacements = Map.from(
        itemPlacements ?? {'0': null, '1': null, '2': null},
      );

  /// 特定の猫の賭け金を取得
  int getBet(String index) => _bets[index] ?? 0;

  /// 特定の猫に配置されたアイテムを取得
  ItemType? getItem(String index) => _itemPlacements[index];

  /// 合計賭け金を計算
  int get total => _bets.values.fold(0, (sum, val) => sum + val);

  /// 賭け金を更新
  Map<String, int> toMap() => Map.unmodifiable(_bets);

  /// アイテム配置を反映したMapを取得
  Map<String, String?> itemsToMap() =>
      _itemPlacements.map((key, value) => MapEntry(key, value?.value));

  factory Bets.fromMap(
    Map<String, dynamic> map, [
    Map<String, dynamic>? itemMap,
  ]) {
    final convertedBets = map.map((key, value) {
      if (value is int) return MapEntry(key, value);
      if (value is String) return MapEntry(key, int.tryParse(value) ?? 0);
      if (value is num) return MapEntry(key, value.toInt());
      return MapEntry(key, 0);
    });

    final convertedItems =
        itemMap?.map((key, value) {
          if (value == null) return MapEntry(key, null);
          return MapEntry(key, ItemType.fromString(value as String));
        }) ??
        {'0': null, '1': null, '2': null};

    return Bets(convertedBets, convertedItems);
  }

  /// 0埋めの初期状態
  factory Bets.empty() =>
      Bets({'0': 0, '1': 0, '2': 0}, {'0': null, '1': null, '2': null});

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
