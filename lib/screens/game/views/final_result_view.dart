import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// 最終結果画面
class FinalResultView extends StatelessWidget {
  final GameRoom room;

  const FinalResultView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final resultText = viewModel.finalWinnerLabel;
    final resultColor = viewModel.finalWinnerColor;

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
            if (viewModel.lastRoundDisplayItems.isNotEmpty) ...[
              const Text(
                '最終ターンの結果',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Row(
                  children: List.generate(
                    viewModel.lastRoundDisplayItems.length,
                    (index) {
                      final item = viewModel.lastRoundDisplayItems[index];

                      return Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Card(
                            color: item.cardColor,
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
                                    color: item.catIconColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      item.catName,
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
                                    item.winnerLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.winnerTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '自: ${item.myBet}${item.myItem != null ? '*' : ''} 敵: ${item.opponentBet}${item.opponentItem != null ? '*' : ''}',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          '最終スコア',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.emoji_events, color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPlayerCards(
                      context,
                      'あなた',
                      viewModel.myWonCardDetails,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    _buildPlayerCards(
                      context,
                      '相手',
                      viewModel.opponentWonCardDetails,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '全${room.currentTurn}ターン終了',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                backgroundColor: resultColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCards(
    BuildContext context,
    String title,
    List<FinalResultCardInfo> cards,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${cards.length}枚',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (cards.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('カードなし', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards.map((card) => _buildCardChip(card)).toList(),
          ),
      ],
    );
  }

  Widget _buildCardChip(FinalResultCardInfo card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: card.isWinningCard
            ? card.color.withOpacity(0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isWinningCard ? card.color : Colors.grey.shade300,
          width: card.isWinningCard ? 2 : 1,
        ),
        boxShadow: card.isWinningCard
            ? [
                BoxShadow(
                  color: card.color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            card.icon,
            size: 16,
            color: card.isWinningCard ? card.color : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            card.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: card.isWinningCard
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: card.isWinningCard ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          if (card.isWinningCard) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
          ],
        ],
      ),
    );
  }
}
