/// ゲームカードのタイプ分類
enum CardType {
  regularCat('regular_cat', '通常ネコ'),
  dog('dog', '犬'),
  fatCat('fat_cat', '太っちょねこ'),
  fisherman('fisherman', '漁師'),
  itemShop('item_shop', 'アイテム屋'),
  bossKitty('boss_kitty', 'ボスねこ');

  final String value;
  final String displayName;

  const CardType(this.value, this.displayName);

  static CardType fromString(String value) {
    return CardType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CardType.regularCat,
    );
  }
}
