import '../models/player.dart';
import '../models/cat_inventory.dart';
import '../constants/game_constants.dart';

/// 勝利条件のインターフェース
abstract class WinCondition {
  /// 勝利条件をチェック（各ルールが独自に実装）
  bool checkWin(CatInventory inventory);

  /// 勝利に寄与したカードのインデックスを取得
  Set<int> getWinningIndices(CatInventory inventory);

  /// 最終的な勝者を決定する（同点時のコスト比較なども含む）
  Winner? determineFinalWinner(Player host, Player guest);
}

/// 標準的な勝利条件（同種3匹 or 全3種以上）
class StandardWinCondition implements WinCondition {
  @override
  bool checkWin(CatInventory inventory) {
    // 種類（名前）ごとのカウント
    final allCounts = inventory.countByName();

    // 通常の猫のみをカウント対象にする
    final counts = <String, int>{};
    for (final type in GameConstants.catTypes) {
      // 通常の猫のカウントを追加
      if (allCounts.containsKey(type)) {
        counts[type] = (counts[type] ?? 0) + allCounts[type]!;
      }

      // 対応するボスねこのカウントを合算する
      final bossType = 'ボス$type';
      if (allCounts.containsKey(bossType)) {
        counts[type] = (counts[type] ?? 0) + allCounts[bossType]!;
      }
    }

    // 合計数チェック
    final totalCats = counts.values.fold(0, (sum, count) => sum + count);
    if (totalCats < 3) return false;

    for (final count in counts.values) {
      // 同じ種類が3匹以上
      if (count >= 3) return true;
    }

    // 3種類以上
    return counts.keys.length >= 3;
  }

  @override
  Set<int> getWinningIndices(CatInventory inventory) {
    final allCats = inventory.all;
    final normalizedNames = allCats.map((cat) {
      String name = cat.name;
      // ボスねこなら通常ねこの名前に変換（例: ボス黒ねこ -> 黒ねこ）
      for (final type in GameConstants.catTypes) {
        if (name == 'ボス$type') return type;
      }
      return name;
    }).toList();

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
    final hostWins = checkWin(host.catsWon);
    final guestWins = checkWin(guest.catsWon);

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
