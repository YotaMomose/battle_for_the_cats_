import 'dart:math';
import '../constants/game_constants.dart';
import '../models/game_room.dart';
import '../models/cards/round_cards.dart';
import 'dice.dart';

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
  final Dice _dice;

  GameLogic({Dice? dice}) : _dice = dice ?? StandardDice();

  /// サイコロを振る
  int rollDice() {
    return _dice.roll();
  }

  /// ルームコードを生成（6桁の英数字）
  String generateRoomCode() {
    final random = Random();
    return List.generate(
      GameConstants.roomCodeLength,
      (index) =>
          GameConstants.roomCodeChars[random.nextInt(
            GameConstants.roomCodeChars.length,
          )],
    ).join();
  }

  /// ランダムに3匹の猫を生成する（各猫は独立したコスト付き）
  RoundCards generateRandomCards() {
    return RoundCards.random();
  }

  /// ラウンドの結果を判定
  RoundResult resolveRound(GameRoom room) {
    final guest = room.guest;
    if (guest == null) {
      throw StateError('Guest must be present to resolve round');
    }

    // 1. 各猫について勝敗を判定
    final perCatResults = _resolveCatResults(room);

    // 2. 累計獲得リストを計算
    final newHostCatsWon = [...room.host.catsWon, ...perCatResults.hostWonCats];
    final newGuestCatsWon = [...guest.catsWon, ...perCatResults.guestWonCats];
    final newHostWonCosts = [
      ...room.host.wonCatCosts,
      ...perCatResults.hostWonCosts,
    ];
    final newGuestWonCosts = [
      ...guest.wonCatCosts,
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
    final guest = room.guest;
    if (guest == null) {
      throw StateError('Guest must be present to resolve cat results');
    }

    final Map<String, String> winners = {};
    final List<String> hostWonCats = [];
    final List<String> guestWonCats = [];
    final List<int> hostWonCosts = [];
    final List<int> guestWonCosts = [];

    final cards = room.currentRound?.toList() ?? [];
    if (cards.isEmpty) {
      return _PerCatResults({}, [], [], [], []);
    }

    for (int i = 0; i < GameConstants.catsPerRound && i < cards.length; i++) {
      final catIndex = i.toString();
      final card = cards[i];
      final cost = card.baseCost;

      final hostBet = room.host.currentBets[catIndex] ?? 0;
      final guestBet = guest.currentBets[catIndex] ?? 0;

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
        hostWonCats.add(card.displayName);
        hostWonCosts.add(cost);
      }

      if (winner == Winner.guest) {
        guestWonCats.add(card.displayName);
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
      return _resolveDoubleWin(hostCosts, guestCosts);
    }

    if (hostWins) {
      return _GameFinalResult(GameStatus.finished, Winner.host);
    }

    if (guestWins) {
      return _GameFinalResult(GameStatus.finished, Winner.guest);
    }

    return _GameFinalResult(GameStatus.roundResult, null);
  }

  /// 両者が同時に勝利条件を満たした場合の判定（累計コストで判定）
  _GameFinalResult _resolveDoubleWin(
    List<int> hostCosts,
    List<int> guestCosts,
  ) {
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
