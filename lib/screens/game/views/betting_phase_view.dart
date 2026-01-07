import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';

/// 賭けフェーズ画面
class BettingPhaseView extends StatelessWidget {
  final GameRoom room;

  const BettingPhaseView({super.key, required this.room});

  /// 猫の名前に応じて色を返す
  Color _getCatColor(String catName) {
    switch (catName) {
      case '茶トラねこ':
        return Colors.orange;
      case '白ねこ':
        return Colors.grey.shade300;
      case '黒ねこ':
        return Colors.black;
      default:
        return Colors.orange;
    }
  }

  /// 獲得した猫リストを表示するウィジェット
  Widget _buildWonCatsList(List<String> cats, List<int> costs) {
    if (cats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('まだ獲得していません', style: TextStyle(color: Colors.grey)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(cats.length, (index) {
        final cat = cats[index];
        final cost = costs.length > index ? costs[index] : 1;

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
              Icon(Icons.pets, size: 20, color: _getCatColor(cat)),
              Text(
                cat,
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
                  '★$cost',
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
      }),
    );
  }

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
                    _buildWonCatsList(
                      playerData.myCatsWon,
                      playerData.myWonCatCosts,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '相手の獲得カード:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildWonCatsList(
                      playerData.opponentCatsWon,
                      playerData.opponentWonCatCosts,
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
                              Icon(
                                Icons.pets,
                                size: 24,
                                color: _getCatColor(catName),
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
                                  '必要: ${room.catCosts.length > index ? room.catCosts[index] : 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!playerData.myReady) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: viewModel.hasPlacedBet
                            ? null
                            : viewModel.placeBets,
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
