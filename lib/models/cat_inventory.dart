import 'won_cat.dart';

/// 獲得した猫のコレクションを管理するクラス
class CatInventory {
  final List<WonCat> _cats;

  CatInventory([List<WonCat>? cats]) : _cats = List.from(cats ?? []);

  /// リストとして取得（読み取り専用）
  List<WonCat> get all => List.unmodifiable(_cats);

  /// 獲得した猫の総数
  int get count => _cats.length;

  /// 猫を追加
  void add(WonCat cat) => _cats.add(cat);

  /// 猫の名前とコストを指定して追加
  void addCat(String name, int cost) =>
      _cats.add(WonCat(name: name, cost: cost));

  /// すべての猫の合計コスト
  int get totalCost => _cats.fold(0, (sum, cat) => sum + cat.cost);

  /// 獲得した猫の名前リスト
  List<String> get names => _cats.map((c) => c.name).toList();

  /// 種類（名前）ごとのカウント
  Map<String, int> countByName() {
    final counts = <String, int>{};
    for (final cat in _cats) {
      counts[cat.name] = (counts[cat.name] ?? 0) + 1;
    }
    return counts;
  }

  /// Firestore保存用
  List<Map<String, dynamic>> toMapList() =>
      _cats.map((c) => c.toMap()).toList();

  /// Firestore復元用
  factory CatInventory.fromMapList(List<dynamic>? list) {
    if (list == null) return CatInventory();
    final cats = list
        .map((item) => WonCat.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return CatInventory(cats);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatInventory &&
          other._cats.length == _cats.length &&
          Iterable.generate(
            _cats.length,
          ).every((i) => _cats[i] == other._cats[i]);

  @override
  int get hashCode => Object.hashAll(_cats);
}
