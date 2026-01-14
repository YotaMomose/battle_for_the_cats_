import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// 最終結果画面
class FinalResultView extends StatelessWidget {
  final GameRoom room;

  const FinalResultView({super.key, required this.room});

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

    if (room.finalWinner == 'draw') {
      resultText = '引き分け';
      resultColor = Colors.grey;
    } else if ((room.finalWinner == 'host' && viewModel.isHost) ||
        (room.finalWinner == 'guest' && !viewModel.isHost)) {
      resultText = 'あなたの勝利！';
      resultColor = Colors.green;
    } else {
      resultText = '敗北...';
      resultColor = Colors.red;
    }

    return Center(
      child: Padding(
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 80,
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
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
