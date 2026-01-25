import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../../../constants/game_constants.dart';
import '../game_screen_view_model.dart';

/// ラウンド結果画面
class RoundResultView extends StatelessWidget {
  final GameRoom room;

  const RoundResultView({super.key, required this.room});

  /// 猫の名前に応じて色を返す
  Color _getCatColor(String catName) {
    switch (catName) {
      case '茶トラねこ':
        return Colors.orange;
      case '白ねこ':
        return Colors.grey.shade300;
      case '黒ねこ':
        return Colors.black;
      default:
        return Colors.orange;
    }
  }

  /// 獲得した猫を種類別にフォーマット
  String _formatCatsWon(List<String> catsWon) {
    final counts = <String, int>{'茶トラねこ': 0, '白ねこ': 0, '黒ねこ': 0};
    for (final cat in catsWon) {
      if (counts.containsKey(cat)) {
        counts[cat] = counts[cat]! + 1;
      }
    }
    return '茶トラ${counts['茶トラねこ']}匹 白${counts['白ねこ']}匹 黒${counts['黒ねこ']}匹';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;
    final winners = room.lastRoundResult?.winners ?? room.winners ?? {};
    final cats =
        room.lastRoundResult?.catNames ??
        (room.currentRound?.toList().map((card) => card.displayName).toList() ??
            []);
    final displayTurn = room.status == GameStatus.roundResult
        ? room.currentTurn
        : room.currentTurn - 1;
    final myConfirmedRound = viewModel.isHost
        ? room.host.confirmedRoundResult
        : (room.guest?.confirmedRoundResult ?? false);

    // このラウンドで獲得した猫数をカウント
    int myRoundWins = 0;
    int opponentRoundWins = 0;

    for (int i = 0; i < 3; i++) {
      final catIndex = i.toString();
      final winner = winners[catIndex];
      final myId = viewModel.isHost ? 'host' : 'guest';
      final opponentId = viewModel.isHost ? 'guest' : 'host';

      if (winner == myId) {
        myRoundWins++;
      } else if (winner == opponentId) {
        opponentRoundWins++;
      }
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ターン $displayTurn 結果',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'このターン: あなた $myRoundWins匹 - $opponentRoundWins匹 相手',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '累計: あなた ${_formatCatsWon(playerData.myCatsWon)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '累計: 相手 ${_formatCatsWon(playerData.opponentCatsWon)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 各猫の結果（横並び）
              SizedBox(
                height: 160,
                child: Row(
                  children: List.generate(3, (index) {
                    final catIndex = index.toString();
                    final catName = index < cats.length ? cats[index] : '???';
                    final myRole = viewModel.isHost
                        ? Winner.host
                        : Winner.guest;
                    final opponentRole = viewModel.isHost
                        ? Winner.guest
                        : Winner.host;

                    final myBet =
                        room.lastRoundResult?.getBet(
                          index,
                          viewModel.isHost ? 'host' : 'guest',
                        ) ??
                        playerData.myBets[catIndex] ??
                        0;
                    final opponentBet =
                        room.lastRoundResult?.getBet(
                          index,
                          viewModel.isHost ? 'guest' : 'host',
                        ) ??
                        playerData.opponentBets[catIndex] ??
                        0;

                    final winner = winners[catIndex];
                    String winnerText = '引き分け';
                    if (winner == myRole) {
                      winnerText = 'あなた獲得';
                    } else if (winner == opponentRole) {
                      winnerText = '相手獲得';
                    }

                    Color cardColor;
                    if (winner == myRole) {
                      cardColor = Colors.green.shade50;
                    } else if (winner == opponentRole) {
                      cardColor = Colors.red.shade50;
                    } else {
                      cardColor = Colors.grey.shade50;
                    }

                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Card(
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 24,
                                  color: _getCatColor(catName),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    catName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  winnerText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: winner == 'draw'
                                        ? Colors.grey
                                        : (winner == myRole
                                              ? Colors.green
                                              : Colors.red),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'あなた: $myBet',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '相手: $opponentBet',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: myConfirmedRound ? null : viewModel.nextTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: myConfirmedRound
                      ? Colors.grey
                      : Colors.orange,
                ),
                child: Text(
                  myConfirmedRound ? '相手の確認待ち...' : '次のターンへ',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
