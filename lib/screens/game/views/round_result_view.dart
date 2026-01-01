import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// ラウンド結果画面
class RoundResultView extends StatelessWidget {
  final GameRoom room;

  const RoundResultView({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;
    final winners = room.winners ?? {};

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
                'ターン ${room.currentTurn} 結果',
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
                '累計: あなた ${playerData.myCatsWon}匹 - ${playerData.opponentCatsWon}匹 相手',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 各猫の結果（横並び）
              SizedBox(
                height: 160,
                child: Row(
                  children: List.generate(3, (index) {
                    final catIndex = index.toString();
                    final catName = room.cats[index];
                    final myBet = playerData.myBets[catIndex] ?? 0;
                    final opponentBet = playerData.opponentBets[catIndex] ?? 0;
                    final winner = winners[catIndex];
                    final myId = viewModel.isHost ? 'host' : 'guest';
                    final opponentId = viewModel.isHost ? 'guest' : 'host';

                    Color cardColor;
                    String winnerText;
                    if (winner == myId) {
                      cardColor = Colors.green.shade50;
                      winnerText = 'あなた獲得';
                    } else if (winner == opponentId) {
                      cardColor = Colors.red.shade50;
                      winnerText = '相手獲得';
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
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pets,
                                    size: 24, color: Colors.orange),
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
                                        : (winner == myId
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
                onPressed: viewModel.nextTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                ),
                child: const Text('次のターンへ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
