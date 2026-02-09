import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../../../models/cat_inventory.dart';
import '../../../models/item.dart';
import '../game_screen_view_model.dart';

/// 賭けフェーズ画面
class BettingPhaseView extends StatelessWidget {
  final GameRoom room;

  const BettingPhaseView({super.key, required this.room});

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ターン ${room.currentTurn}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'あなたの獲得カード:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildWonCatsList(playerData.myCatsWon, viewModel),
                    const SizedBox(height: 12),
                    const Text(
                      '相手の獲得カード:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildWonCatsList(playerData.opponentCatsWon, viewModel),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      viewModel.opponentReadyStatusLabel,
                      style: TextStyle(
                        fontSize: 16,
                        color: viewModel.opponentReadyStatusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3匹の猫カード（横並び）
            SizedBox(
              height: 220,
              child: Row(
                children: List.generate(3, (index) {
                  final catIndex = index.toString();
                  final cards = room.currentRound?.toList() ?? [];
                  if (cards.isEmpty || index >= cards.length) {
                    return const SizedBox();
                  }

                  final catName = cards[index].displayName;
                  final currentBet = viewModel.bets[catIndex] ?? 0;
                  final placedItem = viewModel.getPlacedItem(catIndex);

                  return Flexible(
                    child: DragTarget<ItemType>(
                      onWillAccept: (data) => !viewModel.hasPlacedBet,
                      onAccept: (item) {
                        viewModel.updateItemPlacement(catIndex, item);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Card(
                            elevation: candidateData.isNotEmpty ? 8 : 4,
                            color: candidateData.isNotEmpty
                                ? Colors.yellow.shade100
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (placedItem != null)
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.pets,
                                          size: 24,
                                          color: viewModel.getCatIconColor(
                                            catName,
                                          ),
                                        ),
                                        Positioned(
                                          right: -4,
                                          top: -4,
                                          child: Icon(
                                            Icons.stars,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Icon(
                                      Icons.pets,
                                      size: 24,
                                      color: viewModel.getCatIconColor(catName),
                                    ),
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
                                  const SizedBox(height: 2),
                                  // 必要コスト表示
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '必要: ${cards[index].baseCost}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!viewModel.isMyReady) ...[
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed:
                                              viewModel.hasPlacedBet ||
                                                  currentBet == 0
                                              ? null
                                              : () {
                                                  viewModel.updateBet(
                                                    catIndex,
                                                    currentBet - 1,
                                                  );
                                                },
                                          icon: const Icon(Icons.remove_circle),
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed:
                                              viewModel.hasPlacedBet ||
                                                  viewModel.totalBet >=
                                                      playerData.myFishCount
                                              ? null
                                              : () {
                                                  viewModel.updateBet(
                                                    catIndex,
                                                    currentBet + 1,
                                                  );
                                                },
                                          icon: const Icon(Icons.add_circle),
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                      viewModel.myRemainingFishLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!viewModel.isMyReady) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: viewModel.hasPlacedBet
                            ? null
                            : viewModel.placeBets,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          viewModel.confirmBetsButtonLabel,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'アイテム (ドラッグして使おう):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          children: [
                            _buildDraggableItem(ItemType.catTeaser, viewModel),
                            _buildDraggableItem(
                              ItemType.surpriseHorn,
                              viewModel,
                            ),
                            _buildDraggableItem(ItemType.luckyCat, viewModel),
                            // 他のアイテムも同様に追加可能
                          ],
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableItem(ItemType type, GameScreenViewModel viewModel) {
    final count = viewModel.playerData?.myInventory.count(type) ?? 0;
    if (count <= 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Draggable<ItemType>(
        data: type,
        feedback: Material(
          color: Colors.transparent,
          child: _buildItemIcon(type, count, true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildItemIcon(type, count, false),
        ),
        child: _buildItemIcon(type, count, false),
      ),
    );
  }

  Widget _buildItemIcon(ItemType type, int count, bool isFeedback) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: isFeedback
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 20),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'あと$count個',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 獲得した猫リストを表示するウィジェット
  Widget _buildWonCatsList(
    CatInventory inventory,
    GameScreenViewModel viewModel,
  ) {
    final cats = inventory.all;
    if (cats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('まだ獲得していません', style: TextStyle(color: Colors.grey)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((cat) {
        return Container(
          width: 70,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.pets,
                size: 20,
                color: viewModel.getCatIconColor(cat.name),
              ),
              Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '★${cat.cost}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
