/// アイテムの種類
enum ItemType {
  catTeaser('catTeaser', 'ねこじゃらし', '相手が魚を置いていなければ自動で猫をゲット！'),
  surpriseHorn('surpriseHorn', 'びっくりホーン', '全員の魚を無効化する'),
  luckyCat('luckyCat', 'まねきねこ', '猫の必要魚数が2倍になる'),
  unknown('unknown', '不明', '');

  final String value;
  final String displayName;
  final String description;

  const ItemType(this.value, this.displayName, this.description);

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ItemType.unknown,
    );
  }
}
