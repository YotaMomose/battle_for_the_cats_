/// アイテムの種類
enum ItemType {
  catTeaser(
    'catTeaser',
    'ねこじゃらし',
    '相手が魚を置いていなければ自動で猫をゲット！',
    'assets/images/nekojarashi.png',
  ),
  surpriseHorn(
    'surpriseHorn',
    'びっくりホーン',
    '全員の魚を無効化する',
    'assets/images/horn.png',
  ),
  matatabi('matatabi', 'またたび', '猫の必要魚数が2倍になる', 'assets/images/matatabi.png'),
  unknown('unknown', '不明', '', null);

  final String value;
  final String displayName;
  final String description;
  final String? imagePath;

  const ItemType(
    this.value,
    this.displayName,
    this.description,
    this.imagePath,
  );

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ItemType.unknown,
    );
  }
}
