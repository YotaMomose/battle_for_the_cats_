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
    // 1. 各猫について勝敗を判定
    final perCatResults = _resolveCatResults(room);

    // 2. 累計獲得リストを計算
    final newHostCatsWon = [...room.hostCatsWon, ...perCatResults.hostWonCats];
    final newGuestCatsWon = [
      ...room.guestCatsWon,
      ...perCatResults.guestWonCats,
    ];
    final newHostWonCosts = [
      ...room.hostWonCatCosts,
      ...perCatResults.hostWonCosts,
    ];
    final newGuestWonCosts = [
      ...room.guestWonCatCosts,
      ...perCatResults.guestWonCosts,
    ];

    // 3. ゲーム全体の勝利判定
    final gameResult = _determineFinalGameResult(
      newHostCatsWon,
      newGuestCatsWon,
      newHostWonCosts,
      newGuestWonCosts,
    );

    return RoundResult(
      winners: perCatResults.winners,
      hostWonCats: perCatResults.hostWonCats,
      guestWonCats: perCatResults.guestWonCats,
      hostWonCosts: perCatResults.hostWonCosts,
      guestWonCosts: perCatResults.guestWonCosts,
      finalStatus: gameResult.status,
      finalWinner: gameResult.winner,
    );
  }

  /// 各猫の勝敗判定を行う
  _PerCatResults _resolveCatResults(GameRoom room) {
    final Map<String, String> winners = {};
    final List<String> hostWonCats = [];
    final List<String> guestWonCats = [];
    final List<int> hostWonCosts = [];
    final List<int> guestWonCosts = [];

    for (int i = 0; i < GameConstants.catCount; i++) {
      final catIndex = i.toString();
      final catName = room.cats[i];
      final cost = room.catCosts.length > i ? room.catCosts[i] : 1;

      final hostBet = room.hostBets[catIndex] ?? 0;
      final guestBet = room.guestBets[catIndex] ?? 0;

      final hostQualified = hostBet >= cost;
      final guestQualified = guestBet >= cost;

      // 判定ロジック: デフォルトをドローとし、勝者の条件を満たす場合のみ上書き
      Winner winner = Winner.draw;

      if (hostQualified && (!guestQualified || hostBet > guestBet)) {
        winner = Winner.host;
      }

      if (guestQualified && (!hostQualified || guestBet > hostBet)) {
        winner = Winner.guest;
      }

      winners[catIndex] = winner.value;

      if (winner == Winner.host) {
        hostWonCats.add(catName);
        hostWonCosts.add(cost);
      }

      if (winner == Winner.guest) {
        guestWonCats.add(catName);
        guestWonCosts.add(cost);
      }
    }

    return _PerCatResults(
      winners,
      hostWonCats,
      guestWonCats,
      hostWonCosts,
      guestWonCosts,
    );
  }

  /// ゲーム全体の最終結果（勝利判定）を行う
  _GameFinalResult _determineFinalGameResult(
    List<String> hostCats,
    List<String> guestCats,
    List<int> hostCosts,
    List<int> guestCosts,
  ) {
    final hostWins = checkWinCondition(hostCats);
    final guestWins = checkWinCondition(guestCats);

    if (hostWins && guestWins) {
      final hostTotalCost = hostCosts.fold(0, (a, b) => a + b);
      final guestTotalCost = guestCosts.fold(0, (a, b) => a + b);

      if (hostTotalCost > guestTotalCost) {
        return _GameFinalResult(GameStatus.finished, Winner.host);
      }
      if (guestTotalCost > hostTotalCost) {
        return _GameFinalResult(GameStatus.finished, Winner.guest);
      }
      return _GameFinalResult(GameStatus.finished, Winner.draw);
    }

    if (hostWins) {
      return _GameFinalResult(GameStatus.finished, Winner.host);
    }

    if (guestWins) {
      return _GameFinalResult(GameStatus.finished, Winner.guest);
    }

    return _GameFinalResult(GameStatus.roundResult, null);
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

/// 内部用：各猫の結果をまとめる
class _PerCatResults {
  final Map<String, String> winners;
  final List<String> hostWonCats;
  final List<String> guestWonCats;
  final List<int> hostWonCosts;
  final List<int> guestWonCosts;

  _PerCatResults(
    this.winners,
    this.hostWonCats,
    this.guestWonCats,
    this.hostWonCosts,
    this.guestWonCosts,
  );
}

/// 内部用：最終結果をまとめる
class _GameFinalResult {
  final GameStatus status;
  final Winner? winner;

  _GameFinalResult(this.status, this.winner);
}
