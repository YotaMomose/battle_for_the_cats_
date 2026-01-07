import 'dart:math';
import '../constants/game_constants.dart';
import '../models/game_room.dart';

/// ラウンド結果
class RoundResult {
  final Map<String, String>
  winners; // 各猫の勝者（'0', '1', '2' -> 'host'/'guest'/'draw'）
  final List<String> hostWonCats; // ホストがこのラウンドで獲得した猫の種類
  final List<String> guestWonCats; // ゲストがこのラウンドで獲得した猫の種類
  final List<int> hostWonCosts; // ホストがこのラウンドで獲得した猫のコスト
  final List<int> guestWonCosts; // ゲストがこのラウンドで獲得した猫のコスト
  final GameStatus finalStatus; // 最終ステータス
  final Winner? finalWinner; // 最終勝者

  RoundResult({
    required this.winners,
    required this.hostWonCats,
    required this.guestWonCats,
    required this.hostWonCosts,
    required this.guestWonCosts,
    required this.finalStatus,
    this.finalWinner,
  });
}

/// ゲームロジック（純粋な関数として実装、Firestoreに依存しない）
class GameLogic {
  final Random _random = Random();

  /// サイコロを振る（1-6のランダムな目）
  int rollDice() {
    return _random.nextInt(GameConstants.diceMax) + GameConstants.diceMin;
  }

  /// ルームコードを生成（6桁の英数字）
  String generateRoomCode() {
    return List.generate(
      GameConstants.roomCodeLength,
      (index) =>
          GameConstants.roomCodeChars[_random.nextInt(
            GameConstants.roomCodeChars.length,
          )],
    ).join();
  }

  /// 3匹の猫をランダムに選択（重複OK）
  List<String> generateRandomCats() {
    return List.generate(
      GameConstants.catCount,
      (index) =>
          GameConstants.catTypes[_random.nextInt(
            GameConstants.catTypes.length,
          )],
    );
  }

  /// 3匹の猫のコスト（必要魚数）をランダムに決定（1〜4）
  List<int> generateRandomCosts(int count) {
    return List.generate(count, (_) => _random.nextInt(4) + 1);
  }

  /// ラウンドの結果を判定
  RoundResult resolveRound(GameRoom room) {
    final Map<String, String> winners = {};
    final List<String> hostWonCats = [];
    final List<String> guestWonCats = [];
    final List<int> hostWonCosts = [];
    final List<int> guestWonCosts = [];

    // 各猫について勝敗を判定
    for (int i = 0; i < GameConstants.catCount; i++) {
      final catIndex = i.toString();
      final catName = room.cats[i];
      final cost = room.catCosts.length > i
          ? room.catCosts[i]
          : 1; // コスト取得（デフォルト1）

      final hostBet = room.hostBets[catIndex] ?? 0;
      final guestBet = room.guestBets[catIndex] ?? 0;

      // 足切り判定
      final hostQualified = hostBet >= cost;
      final guestQualified = guestBet >= cost;

      if (hostQualified && guestQualified) {
        // 両者条件クリア → 数が多い方
        if (hostBet > guestBet) {
          winners[catIndex] = Winner.host.value;
          hostWonCats.add(catName);
          hostWonCosts.add(cost);
        } else if (guestBet > hostBet) {
          winners[catIndex] = Winner.guest.value;
          guestWonCats.add(catName);
          guestWonCosts.add(cost);
        } else {
          winners[catIndex] = Winner.draw.value;
        }
      } else if (hostQualified) {
        // ホストのみ条件クリア → ホスト獲得
        winners[catIndex] = Winner.host.value;
        hostWonCats.add(catName);
        hostWonCosts.add(cost);
      } else if (guestQualified) {
        // ゲストのみ条件クリア → ゲスト獲得
        winners[catIndex] = Winner.guest.value;
        guestWonCats.add(catName);
        guestWonCosts.add(cost);
      } else {
        // 両者条件満たさず → 獲得なし（引き分け扱い）
        winners[catIndex] = Winner.draw.value;
      }
    }

    // 累計獲得猫リストを計算
    final newHostCatsWon = [...room.hostCatsWon, ...hostWonCats];
    final newGuestCatsWon = [...room.guestCatsWon, ...guestWonCats];

    // 累計獲得コストリストを計算
    final newHostWonCatCosts = [...room.hostWonCatCosts, ...hostWonCosts];
    final newGuestWonCatCosts = [...room.guestWonCatCosts, ...guestWonCosts];

    // 勝利条件判定
    final hostWins = checkWinCondition(newHostCatsWon);
    final guestWins = checkWinCondition(newGuestCatsWon);

    final GameStatus finalStatus;
    final Winner? finalWinner;

    if (hostWins && guestWins) {
      // 同時に勝利条件達成 → コスト合計で判定
      final hostTotalCost = newHostWonCatCosts.fold(0, (a, b) => a + b);
      final guestTotalCost = newGuestWonCatCosts.fold(0, (a, b) => a + b);

      finalStatus = GameStatus.finished;
      if (hostTotalCost > guestTotalCost) {
        finalWinner = Winner.host;
      } else if (guestTotalCost > hostTotalCost) {
        finalWinner = Winner.guest;
      } else {
        finalWinner = Winner.draw;
      }
    } else if (hostWins) {
      // ホストの勝利
      finalStatus = GameStatus.finished;
      finalWinner = Winner.host;
    } else if (guestWins) {
      // ゲストの勝利
      finalStatus = GameStatus.finished;
      finalWinner = Winner.guest;
    } else {
      // まだ勝敗がつかない → ラウンド結果表示
      finalStatus = GameStatus.roundResult;
      finalWinner = null;
    }

    return RoundResult(
      winners: winners,
      hostWonCats: hostWonCats,
      guestWonCats: guestWonCats,
      hostWonCosts: hostWonCosts,
      guestWonCosts: guestWonCosts,
      finalStatus: finalStatus,
      finalWinner: finalWinner,
    );
  }

  /// 勝利条件をチェック（同種3匹 or 3種類）
  bool checkWinCondition(List<String> catsWon) {
    if (catsWon.length < 3) return false;

    // 各種類のカウント
    final counts = <String, int>{};
    for (final cat in catsWon) {
      counts[cat] = (counts[cat] ?? 0) + 1;
      // 同じ種類が3匹以上
      if (counts[cat]! >= 3) return true;
    }

    // 3種類以上
    return counts.keys.length >= 3;
  }
}
