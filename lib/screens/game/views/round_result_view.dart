import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../../../models/item.dart';
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
              // 犬の効果の通知メッセージ
              ...viewModel.dogEffectNotifications.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewModel.dogEffectNotifications.isNotEmpty)
                const SizedBox(height: 16),

              // ターンタイトルと各猫の結果
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
              const SizedBox(height: 12),
              const Text(
                '累計: あなた',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              _buildWonCardsIconList(viewModel.myWonCardDetails),
              const SizedBox(height: 8),
              const Text(
                '累計: 相手',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              _buildWonCardsIconList(viewModel.opponentWonCardDetails),
              const SizedBox(height: 24),

              // 各猫の結果（横並び）
              SizedBox(
                height: 160,
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
                                  _buildPlayerResultRow(
                                    'あなた',
                                    item.myBet,
                                    item.myItem,
                                    viewModel,
                                  ),
                                  _buildPlayerResultRow(
                                    '相手',
                                    item.opponentBet,
                                    item.opponentItem,
                                    viewModel,
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
                        '✨ アイテム復活効果発動！ ✨',
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

              // 犬の効果選択 UI
              if (viewModel.canChaseAway) ...[
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '🐶 犬の効果発動中！ (残り ${viewModel.remainingDogChases}回)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '相手のキャラクターを1枚選んで追い出せます',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        if (viewModel.availableTargetsForDog.isEmpty)
                          const Text(
                            '追い出せる相手のキャラクターがいません',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: viewModel.availableTargetsForDog.map((
                              catName,
                            ) {
                              return ElevatedButton.icon(
                                onPressed: () =>
                                    viewModel.chaseAwayCard(catName),
                                icon: const Icon(Icons.exit_to_app, size: 18),
                                label: Text(catName),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  elevation: 0,
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => viewModel.chaseAwayCard(null),
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('すべての効果をスキップする'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: (isConfirmed || viewModel.canChaseAway)
                    ? null
                    : viewModel.nextTurn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: (isConfirmed || viewModel.canChaseAway)
                      ? Colors.grey
                      : Colors.orange,
                ),
                child: Text(
                  viewModel.canChaseAway
                      ? '追い出すカードを選択してください'
                      : (isConfirmed ? '相手の確認待ち...' : '次のターンへ'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerResultRow(
    String label,
    int bet,
    ItemType? item,
    GameScreenViewModel viewModel,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            '$label: $bet',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item != null && item != ItemType.unknown)
          Tooltip(
            message: item.displayName,
            child: Icon(
              viewModel.getItemIconData(item),
              size: 14,
              color: Colors.blueAccent,
            ),
          ),
      ],
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
