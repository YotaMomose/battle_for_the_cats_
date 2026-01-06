import 'dart:math';
import '../constants/game_constants.dart';
import '../models/game_room.dart';

/// ラウンド結果
class RoundResult {
  final Map<String, String> winners; // 各猫の勝者（'0', '1', '2' -> 'host'/'guest'/'draw'）
  final int hostWins; // ホストが獲得した猫の数
  final int guestWins; // ゲストが獲得した猫の数
  final GameStatus finalStatus; // 最終ステータス
  final Winner? finalWinner; // 最終勝者

  RoundResult({
    required this.winners,
    required this.hostWins,
    required this.guestWins,
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
      (index) => GameConstants.roomCodeChars[
          _random.nextInt(GameConstants.roomCodeChars.length)],
    ).join();
  }

  /// ラウンドの結果を判定
  RoundResult resolveRound(GameRoom room) {
    final Map<String, String> winners = {};
    int hostWins = 0;
    int guestWins = 0;

    // 各猫について勝敗を判定
    for (int i = 0; i < GameConstants.catCount; i++) {
      final catIndex = i.toString();
      final hostBet = room.hostBets[catIndex] ?? 0;
      final guestBet = room.guestBets[catIndex] ?? 0;

      if (hostBet > guestBet) {
        winners[catIndex] = Winner.host.value;
        hostWins++;
      } else if (guestBet > hostBet) {
        winners[catIndex] = Winner.guest.value;
        guestWins++;
      } else {
        winners[catIndex] = Winner.draw.value;
      }
    }

    // 累計獲得猫数を計算
    final newHostCatsWon = room.hostCatsWon + hostWins;
    final newGuestCatsWon = room.guestCatsWon + guestWins;

    // 勝利条件判定
    final GameStatus finalStatus;
    final Winner? finalWinner;

    if (newHostCatsWon >= GameConstants.winCondition &&
        newGuestCatsWon >= GameConstants.winCondition) {
      // 同時に3匹到達 → 引き分け
      finalStatus = GameStatus.finished;
      finalWinner = Winner.draw;
    } else if (newHostCatsWon >= GameConstants.winCondition) {
      // ホストの勝利
      finalStatus = GameStatus.finished;
      finalWinner = Winner.host;
    } else if (newGuestCatsWon >= GameConstants.winCondition) {
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
      hostWins: hostWins,
      guestWins: guestWins,
      finalStatus: finalStatus,
      finalWinner: finalWinner,
    );
  }

  /// 勝利条件をチェック
  bool checkWinCondition(int catsWon) {
    return catsWon >= GameConstants.winCondition;
  }
}
