/// アイテムの種類
enum ItemType {
  catTeaser(
    'catTeaser',
    'ねこじゃらし',
    '相手がさかなを置いていなければ自動でにゃんこをゲット！',
    'assets/images/nekojarashi.png',
  ),
  surpriseHorn(
    'surpriseHorn',
    'びっくりホーン',
    '全員のさかなを無効化する',
    'assets/images/horn.png',
  ),
  matatabi(
    'matatabi',
    'またたび',
    'にゃんこの必要さかな数が2倍になる',
    'assets/images/matatabi.png',
  ),
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
