import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// サイコロフェーズ画面
class RollingPhaseView extends StatelessWidget {
  final GameRoom room;

  const RollingPhaseView({super.key, required this.room});

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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ターン情報
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'ターン ${room.currentTurn}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'あなた: ${_formatCatsWon(playerData.myCatsWon)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '相手: ${_formatCatsWon(playerData.opponentCatsWon)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // タイトル
            const Text(
              '🎲 サイコロフェーズ 🎲',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 相手の状態
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '対戦相手',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (playerData.opponentRolled &&
                        playerData.opponentDiceRoll != null) ...[
                      Text(
                        '🎲 ${playerData.opponentDiceRoll}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '魚を ${playerData.opponentDiceRoll} 匹獲得しました！',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'サイコロを振っています...',
                        style: TextStyle(fontSize: 16, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 自分のサイコロ
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'あなた',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (playerData.myRolled &&
                        playerData.myDiceRoll != null) ...[
                      Text(
                        '🎲 ${playerData.myDiceRoll}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '魚を ${playerData.myDiceRoll} 匹獲得！',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '相手を待っています...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: viewModel.hasRolled
                            ? null
                            : viewModel.rollDice,
                        icon: const Icon(Icons.casino, size: 32),
                        label: Text(
                          viewModel.hasRolled ? '振りました' : 'サイコロを振る',
                          style: const TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          backgroundColor: viewModel.hasRolled
                              ? Colors.grey
                              : Colors.orange,
                        ),
                      ),
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
