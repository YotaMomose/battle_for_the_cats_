import '../models/player.dart';
import '../models/won_cat.dart';
import '../constants/game_constants.dart';

/// 勝利条件のインターフェース
abstract class WinCondition {
  /// 勝利条件をチェック（各ルールが独自に実装）
  bool checkWin(List<WonCat> catsWon);

  /// 最終的な勝者を決定する（同点時のコスト比較なども含む）
  Winner? determineFinalWinner(Player host, Player guest);
}

/// 標準的な勝利条件（同種3匹 or 全3種以上）
class StandardWinCondition implements WinCondition {
  @override
  bool checkWin(List<WonCat> catsWon) {
    if (catsWon.length < 3) return false;

    // 各種類のカウント
    final counts = <String, int>{};
    for (final cat in catsWon) {
      counts[cat.name] = (counts[cat.name] ?? 0) + 1;
      // 同じ種類が3匹以上
      if (counts[cat.name]! >= 3) return true;
    }

    // 3種類以上
    return counts.keys.length >= 3;
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
