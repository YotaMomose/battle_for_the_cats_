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
    if (inventory.totalValidCatCount < 3) return false;
    return inventory.hasThreeOfAKind || inventory.hasThreeDifferentTypes;
  }

  @override
  Set<int> getWinningIndices(CatInventory inventory) {
    return inventory.winningIndices;
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
