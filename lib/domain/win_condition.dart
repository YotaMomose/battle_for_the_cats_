import '../models/player.dart';
import '../models/cat_inventory.dart';
import '../constants/game_constants.dart';

/// 勝利条件のインターフェース
abstract class WinCondition {
  /// 勝利条件を満たしているかチェック
  bool isAchieved(CatInventory inventory);

  /// 勝利に寄与したカードのインデックスを取得
  Set<int> getWinningIndices(CatInventory inventory);

  /// 最終的な勝者を決定する（同点時のコスト比較なども含む）
  Winner? determineFinalWinner(Player host, Player guest);
}

/// 標準的な勝利条件（同種3匹 or 全3種以上）
class StandardWinCondition implements WinCondition {
  @override
  bool isAchieved(CatInventory inventory) {
    final counts = _getNormalizedCounts(inventory);

    // 合計数チェック（最低3匹必要）
    final totalCats = counts.values.fold(0, (sum, count) => sum + count);
    if (totalCats < 3) return false;

    return _hasThreeOfAKind(counts) || _hasThreeDifferentTypes(counts);
  }

  /// 通常猫とボス猫を合算したカウントマップを取得する
  Map<String, int> _getNormalizedCounts(CatInventory inventory) {
    final allCounts = inventory.countByName();
    final counts = <String, int>{};

    for (final entry in allCounts.entries) {
      final normalizedName = _getNormalizedName(entry.key);
      if (GameConstants.catTypes.contains(normalizedName)) {
        counts[normalizedName] = (counts[normalizedName] ?? 0) + entry.value;
      }
    }
    return counts;
  }

  /// ボスねこの名前を対応する通常ねこの名前に正規化する
  String _getNormalizedName(String name) {
    for (final type in GameConstants.catTypes) {
      if (name == 'ボス$type') return type;
    }
    return name;
  }

  /// 同種3匹以上の判定
  bool _hasThreeOfAKind(Map<String, int> counts) {
    return counts.values.any((count) => count >= 3);
  }

  /// 3種類以上の判定
  bool _hasThreeDifferentTypes(Map<String, int> counts) {
    return counts.keys.length >= 3;
  }

  @override
  Set<int> getWinningIndices(CatInventory inventory) {
    final allCats = inventory.all;
    final normalizedNames = allCats
        .map((cat) => _getNormalizedName(cat.name))
        .toList();

    // 種類ごとのインデックスリスト
    final indicesByType = <String, List<int>>{};
    for (int i = 0; i < normalizedNames.length; i++) {
      final name = normalizedNames[i];
      // 有効な猫の型（通常またはボス）のみ対象
      if (GameConstants.catTypes.contains(name)) {
        indicesByType.putIfAbsent(name, () => []).add(i);
      }
    }

    final winningIndices = <int>{};

    // 1. 同種3匹チェック
    for (final indices in indicesByType.values) {
      if (indices.length >= 3) {
        winningIndices.addAll(indices);
      }
    }

    // 2. 3種類以上チェック（すべての種類が1匹以上）
    if (indicesByType.keys.length >= 3) {
      for (final indices in indicesByType.values) {
        winningIndices.addAll(indices);
      }
    }

    return winningIndices;
  }

  @override
  Winner? determineFinalWinner(Player host, Player guest) {
    final hostWins = isAchieved(host.catsWon);
    final guestWins = isAchieved(guest.catsWon);

    // どちらも勝利条件を満たしていない場合は決着せず
    if (!hostWins && !guestWins) return null;

    // 片方だけが勝利条件を満たしている場合
    if (hostWins && !guestWins) return Winner.host;
    if (!hostWins && guestWins) return Winner.guest;

    // 両者勝利時は合計コストで判定（タイブレーク）
    final hostTotalCost = host.totalWonCatCost;
    final guestTotalCost = guest.totalWonCatCost;

    if (hostTotalCost > guestTotalCost) return Winner.host;
    if (guestTotalCost > hostTotalCost) return Winner.guest;
    return Winner.draw;
  }
}
