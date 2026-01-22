/// ゲームカードが持つ特殊効果
enum CardEffect {
  none('none', 'なし'),
  dogEffect('dog', '相手の猫を逃がす'),
  fattyEffect('fatty', '登場時、手札の魚全て破棄'),
  fishermanEffect('fisherman', '毎ターン魚+1'),
  itemShopEffect('item_shop', 'アイテム1つ復活'),
  bossEffect('boss', 'ボスの複合効果');

  final String value;
  final String description;

  const CardEffect(this.value, this.description);

  static CardEffect fromString(String value) {
    return CardEffect.values.firstWhere(
      (effect) => effect.value == value,
      orElse: () => CardEffect.none,
    );
  }
}
