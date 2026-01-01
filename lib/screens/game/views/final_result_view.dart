import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// 最終結果画面
class FinalResultView extends StatelessWidget {
  final GameRoom room;

  const FinalResultView({
    super.key,
    required this.room,
  });

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
                    const Icon(Icons.emoji_events,
                        size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      '最終スコア',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'あなた: ${playerData.myCatsWon}匹',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '相手: ${playerData.opponentCatsWon}匹',
                      style: const TextStyle(fontSize: 28),
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
                Navigator.pop(context);
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
