import '../constants/game_constants.dart';
import 'won_cat.dart';

/// 獲得した猫のコレクションを管理するクラス
///
/// データの保持だけでなく、勝利条件に関する問い合わせ（正規化カウント、
/// 同種3匹判定、3種類判定など）も自身の責務として持つ。
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

  /// 名前を指定して猫を1匹削除する（犬の効果などで使用）
  void removeByName(String name) {
    final index = _cats.indexWhere((c) => c.name == name);
    if (index != -1) {
      _cats.removeAt(index);
    }
  }

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

  // ===== 勝利条件に関する問い合わせ =====

  /// ボス猫を通常猫に正規化したうえでの種類別カウント
  Map<String, int> get normalizedCounts {
    final allCounts = countByName();
    final counts = <String, int>{};

    for (final entry in allCounts.entries) {
      final normalizedName = _getNormalizedName(entry.key);
      if (GameConstants.catTypes.contains(normalizedName)) {
        counts[normalizedName] = (counts[normalizedName] ?? 0) + entry.value;
      }
    }
    return counts;
  }

  /// 勝利条件に有効な猫の合計数（ボス猫含む、アイテム屋等は除外）
  int get totalValidCatCount =>
      normalizedCounts.values.fold(0, (sum, count) => sum + count);

  /// 同種3匹以上を持っているか
  bool get hasThreeOfAKind =>
      normalizedCounts.values.any((count) => count >= 3);

  /// 3種類以上の猫を持っているか
  bool get hasThreeDifferentTypes => normalizedCounts.keys.length >= 3;

  /// 勝利に寄与した猫のインデックスを取得
  Set<int> get winningIndices {
    final normalizedNames = _cats
        .map((cat) => _getNormalizedName(cat.name))
        .toList();

    // 種類ごとのインデックスリスト
    final indicesByType = <String, List<int>>{};
    for (int i = 0; i < normalizedNames.length; i++) {
      final name = normalizedNames[i];
      if (GameConstants.catTypes.contains(name)) {
        indicesByType.putIfAbsent(name, () => []).add(i);
      }
    }

    final result = <int>{};

    // 同種3匹チェック
    for (final indices in indicesByType.values) {
      if (indices.length >= 3) {
        result.addAll(indices);
      }
    }

    // 3種類以上チェック
    if (indicesByType.keys.length >= 3) {
      for (final indices in indicesByType.values) {
        result.addAll(indices);
      }
    }

    return result;
  }

  /// ボスねこの名前を対応する通常ねこの名前に正規化する
  String _getNormalizedName(String name) {
    for (final type in GameConstants.catTypes) {
      if (name == 'ボス$type') return type;
    }
    return name;
  }

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
