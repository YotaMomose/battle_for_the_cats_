import 'item.dart';

/// プレイヤーのアイテムインベントリを管理するクラス
class ItemInventory {
  final Map<ItemType, int> _items;

  ItemInventory([Map<ItemType, int>? items]) : _items = Map.from(items ?? {});

  /// 初期状態（ねこじゃらしを1つ持っている）
  factory ItemInventory.initial() {
    return ItemInventory({
      ItemType.catTeaser: 1,
      ItemType.surpriseHorn: 1,
      ItemType.luckyCat: 1,
    });
  }

  /// 指定したアイテムの所持数を取得
  int count(ItemType type) => _items[type] ?? 0;

  /// アイテムを消費する
  bool consume(ItemType type) {
    final current = count(type);
    if (current <= 0) return false;
    _items[type] = current - 1;
    return true;
  }

  /// アイテムを追加する
  void add(ItemType type, [int amount = 1]) {
    _items[type] = count(type) + amount;
  }

  /// 全アイテムのリストを取得（所持しているもののみ）
  List<ItemType> get availableItems =>
      _items.entries.where((e) => e.value > 0).map((e) => e.key).toList();

  /// Firestore保存用
  Map<String, int> toMap() {
    return _items.map((key, value) => MapEntry(key.value, value));
  }

  /// Firestore復元用
  factory ItemInventory.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ItemInventory.initial();
    final items = <ItemType, int>{};
    map.forEach((key, value) {
      final type = ItemType.fromString(key);
      if (type != ItemType.unknown) {
        items[type] = value as int;
      }
    });
    return ItemInventory(items);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemInventory &&
          _items.length == other._items.length &&
          _items.entries.every((e) => other._items[e.key] == e.value);

  @override
  int get hashCode => _items.hashCode;
}
