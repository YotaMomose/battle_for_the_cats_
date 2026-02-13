import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// ラウンド結果画面
class RoundResultView extends StatelessWidget {
  final GameRoom room;

  const RoundResultView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final displayTurn = viewModel.displayTurn;
    final isConfirmed = viewModel.isRoundResultConfirmed;
    final myRoundWins = viewModel.myRoundWinCount;
    final opponentRoundWins = viewModel.opponentRoundWinCount;

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
                '累計: あなた ${viewModel.myCatsWonSummary}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '累計: 相手 ${viewModel.opponentCatsWonSummary}',
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
                  children: List.generate(viewModel.lastRoundDisplayItems.length, (
                    index,
                  ) {
                    final item = viewModel.lastRoundDisplayItems[index];

                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Card(
                          color: item.cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.catIcon,
                                  size: 24,
                                  color: item.catIconColor,
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    item.catName,
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
                                  item.winnerLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.winnerTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'あなた: ${item.myBet}${item.myItem != null ? ' (じゃらし使!)' : ''}',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '相手: ${item.opponentBet}${item.opponentItem != null ? ' (じゃらし使!)' : ''}',
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

              // アイテム復活UI
              if (viewModel.canReviveItem) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '✨ アイテム屋の効果発動！ ✨',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '使用済みのアイテムを復活できます（残り ${viewModel.playerData?.myPendingItemRevivals ?? 0}回）',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.revivableItems.isEmpty)
                        const Text(
                          '復活できるアイテムがありません\n（またはすべてのアイテムを所持しています）',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8, // horizontal spacing
                          runSpacing: 8, // vertical spacing
                          alignment: WrapAlignment.center,
                          children: viewModel.revivableItems.map((item) {
                            return ElevatedButton.icon(
                              onPressed: () => viewModel.reviveItem(item),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(item.displayName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple,
                                side: const BorderSide(color: Colors.purple),
                                elevation: 0,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: isConfirmed ? null : viewModel.nextTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: isConfirmed ? Colors.grey : Colors.orange,
                ),
                child: Text(
                  isConfirmed ? '相手の確認待ち...' : '次のターンへ',
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
