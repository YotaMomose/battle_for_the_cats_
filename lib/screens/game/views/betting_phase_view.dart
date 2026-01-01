import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// 賭けフェーズ画面
class BettingPhaseView extends StatelessWidget {
  final GameRoom room;

  const BettingPhaseView({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ターン情報とスコア表示
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'ターン ${room.currentTurn}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'あなた: ${playerData.myCatsWon}匹  |  相手: ${playerData.opponentCatsWon}匹',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 対戦相手の状態
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '対戦相手',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '魚: ${playerData.opponentFishCount}匹 🐟',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playerData.opponentReady ? '準備完了！' : '選択中...',
                      style: TextStyle(
                        fontSize: 16,
                        color: playerData.opponentReady
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3匹の猫カード（横並び）
            SizedBox(
              height: 200,
              child: Row(
                children: List.generate(3, (index) {
                  final catIndex = index.toString();
                  final catName = room.cats[index];
                  final currentBet = viewModel.bets[catIndex] ?? 0;

                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pets,
                                  size: 24, color: Colors.orange),
                              const SizedBox(height: 2),
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
                              if (!playerData.myReady) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '$currentBet 🐟',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: viewModel.hasPlacedBet ||
                                              currentBet == 0
                                          ? null
                                          : () {
                                              viewModel.updateBet(
                                                  catIndex, currentBet - 1);
                                            },
                                      icon: const Icon(Icons.remove_circle),
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: viewModel.hasPlacedBet ||
                                              viewModel.totalBet >=
                                                  playerData.myFishCount
                                          ? null
                                          : () {
                                              viewModel.updateBet(
                                                  catIndex, currentBet + 1);
                                            },
                                      icon: const Icon(Icons.add_circle),
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 自分の情報
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '残りの魚: ${playerData.myFishCount - viewModel.totalBet} / ${playerData.myFishCount} 🐟',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (!playerData.myReady) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            viewModel.hasPlacedBet ? null : viewModel.placeBets,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          viewModel.hasPlacedBet ? '確定済み' : '確定',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        '準備完了！',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('結果を待っています...'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
