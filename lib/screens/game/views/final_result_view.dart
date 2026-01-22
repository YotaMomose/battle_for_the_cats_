import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../../../constants/game_constants.dart';
import '../game_screen_view_model.dart';

/// 最終結果画面
class FinalResultView extends StatelessWidget {
  final GameRoom room;

  const FinalResultView({super.key, required this.room});

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

    String resultText;
    Color resultColor;

    if (room.finalWinner == Winner.draw) {
      resultText = '引き分け';
      resultColor = Colors.grey;
    } else if ((room.finalWinner == Winner.host && viewModel.isHost) ||
        (room.finalWinner == Winner.guest && !viewModel.isHost)) {
      resultText = 'あなたの勝利！';
      resultColor = Colors.green;
    } else {
      resultText = '敗北...';
      resultColor = Colors.red;
    }

    final winners = room.lastRoundWinners ?? {};
    final cats = room.lastRoundCats ?? [];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              resultText,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 24),

            // 最終ターンの詳細
            if (cats.isNotEmpty) ...[
              const Text(
                '最終ターンの結果',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Row(
                  children: List.generate(3, (index) {
                    final catIndex = index.toString();
                    final catName = index < cats.length ? cats[index] : '???';
                    final myBet =
                        (viewModel.isHost
                            ? room.lastRoundHostBets
                            : room.lastRoundGuestBets)?[catIndex] ??
                        0;
                    final opponentBet =
                        (viewModel.isHost
                            ? room.lastRoundGuestBets
                            : room.lastRoundHostBets)?[catIndex] ??
                        0;
                    final winner = winners[catIndex];
                    final myId = viewModel.isHost ? 'host' : 'guest';
                    final opponentId = viewModel.isHost ? 'guest' : 'host';

                    Color cardColor;
                    String winnerText;
                    if (winner == myId) {
                      cardColor = Colors.green.shade50;
                      winnerText = '獲得';
                    } else if (winner == opponentId) {
                      cardColor = Colors.red.shade50;
                      winnerText = '取られた';
                    } else {
                      cardColor = Colors.grey.shade50;
                      winnerText = '引き分け';
                    }

                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Card(
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pets,
                                  size: 20,
                                  color: _getCatColor(catName),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    catName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  winnerText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: winner == 'draw'
                                        ? Colors.grey
                                        : (winner == myId
                                              ? Colors.green
                                              : Colors.red),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '自: $myBet 敵: $opponentBet',
                                  style: const TextStyle(fontSize: 9),
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
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '最終スコア',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'あなた: ${_formatCatsWon(playerData.myCatsWon)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '相手: ${_formatCatsWon(playerData.opponentCatsWon)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '全${room.currentTurn}ターン',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                viewModel.leaveRoom();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
