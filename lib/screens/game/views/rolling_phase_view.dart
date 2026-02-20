import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// サイコロフェーズ画面
class RollingPhaseView extends StatelessWidget {
  final GameRoom room;

  const RollingPhaseView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;

    return Center(
      child: SingleChildScrollView(
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            viewModel.myIconEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewModel.myDisplayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      _buildWonCardsIconList(viewModel.myWonCardDetails),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            viewModel.opponentIconEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewModel.opponentDisplayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      _buildWonCardsIconList(viewModel.opponentWonCardDetails),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ...

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            viewModel.opponentIconEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            viewModel.opponentDisplayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (viewModel.shouldShowOpponentRollResult) ...[
                        Text(
                          '🎲 ${playerData.opponentDiceRoll}${playerData.opponentFishermanCount > 0 ? ' + ${playerData.opponentFishermanCount}' : ''}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      Text(
                        viewModel.opponentRollStatusLabel,
                        style: TextStyle(
                          fontSize: 16,
                          color: viewModel.opponentRollStatusColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (playerData.opponentFishermanCount > 0)
                        Text(
                          '(漁師ボーナス +${playerData.opponentFishermanCount} 🐟)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            viewModel.myIconEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            viewModel.myDisplayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.shouldShowMyRollResult) ...[
                        Text(
                          '🎲 ${playerData.myDiceRoll}${playerData.myFishermanCount > 0 ? ' + ${playerData.myFishermanCount}' : ''}',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '魚を ${playerData.myDiceRoll! + playerData.myFishermanCount} 匹獲得！',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (playerData.myFishermanCount > 0)
                          Text(
                            '(漁師ボーナス +${playerData.myFishermanCount} 🐟)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (viewModel.canProceedFromRoll)
                          ElevatedButton(
                            onPressed: viewModel.confirmRoll,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text(
                              '次へ進む',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
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
                            viewModel.rollButtonLabel,
                            style: const TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            backgroundColor: viewModel.rollButtonColor,
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
      ),
    );
  }

  Widget _buildWonCardsIconList(List<FinalResultCardInfo> cards) {
    if (cards.isEmpty) {
      return const Text(
        'なし',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: cards.map((card) {
        return Tooltip(
          message: card.name,
          child: Icon(card.icon, size: 18, color: card.color),
        );
      }).toList(),
    );
  }
}
