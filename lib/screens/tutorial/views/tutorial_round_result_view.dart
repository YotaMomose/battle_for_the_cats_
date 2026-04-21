import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../tutorial_view_model.dart';

/// チュートリアル用の判定結果画面
class TutorialRoundResultView extends StatefulWidget {
  const TutorialRoundResultView({super.key});

  @override
  State<TutorialRoundResultView> createState() => _TutorialRoundResultViewState();
}

class _TutorialRoundResultViewState extends State<TutorialRoundResultView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TutorialViewModel>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;
    final currentStep = viewModel.currentStep;

    // 現在どのカードを判定中か (11:しろ, 12:くろ, 13-15:茶トラ)
    final int cardIndex = (currentStep == 11)
        ? 0
        : (currentStep == 12 ? 1 : (currentStep >= 13 && currentStep <= 15 ? 2 : 0));
    final resultItem = viewModel.roundResultItems[cardIndex];

    return Container(
      color: Colors.black.withOpacity(0.8), // 判定中の暗転背景
      child: Column(
        children: [
          // ヘッダー
          _buildHeader(isSmallScreen),

          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(1.2, 0.0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutQuart)),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  key: ValueKey<int>(cardIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildResultCard(context, viewModel, resultItem, isSmallScreen, currentStep),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(
          'ターン 1 けっか！',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4D331F),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    TutorialViewModel viewModel,
    TutorialRoundResultItem item,
    bool isSmallScreen,
    int currentStep,
  ) {
    final bool isRevealed = currentStep > 9;

    // 実戦に近い色設定
    Color accentColor = const Color(0xFFFFD54F);
    Color cardColor = Colors.white;
    Color stampColor = Colors.grey;
    String stampText = '?';

    if (item.winStatus == 'win') {
      cardColor = const Color(0xFFFFF9C4); // 黄色味がかった白
      stampColor = Colors.orange;
      stampText = 'WIN!!';
    } else if (item.winStatus == 'lose') {
      cardColor = const Color(0xFFE3F2FD); // 青みがかった白
      stampColor = Colors.blue;
      stampText = 'LOSE...';
    } else {
      stampText = 'DRAW';
    }

    return StereoscopicContainer(
      baseColor: cardColor,
      shadowColor: const Color(0xFF4D331F).withOpacity(0.3),
      borderRadius: 24,
      depth: 8,
      showDots: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // カード名ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF4D331F).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              item.catName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // 猫アバターとスタンプの重ね合わせ
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      viewModel.getCatImagePath(item.catName) ?? '',
                      height: isSmallScreen ? 100 : 140,
                      fit: BoxFit.contain,
                    ),

                    // 判定スタンプ
                    if (isRevealed)
                      Transform.rotate(
                        angle: -0.15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: stampColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: stampColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            stampText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 36,
                              fontWeight: FontWeight.w900,
                              color: stampColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // コスト表示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.opponentItem == ItemType.matatabi)
                        const Text('1 x 2 = ',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.red)),
                      Text(
                        (item.opponentItem == ItemType.matatabi
                                ? 2
                                : _getCatCost(item.catName))
                            .toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: item.opponentItem == ItemType.matatabi
                                ? Colors.red
                                : Colors.black),
                      ),
                      const SizedBox(width: 4),
                      const Text('🐟', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 詳細スコアテーブル (実戦風)
                _buildSmallStatsTable(
                  viewModel.myDisplayName,
                  item.myBet,
                  item.myItem,
                  viewModel.opponentDisplayName,
                  item.opponentBet,
                  item.opponentItem,
                  isSmallScreen,
                  isRevealed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCatCost(String name) {
    if (name.contains('しろ')) return 3;
    if (name.contains('くろ')) return 2;
    return 1; // 茶トラ
  }

  Widget _buildSmallStatsTable(
    String name1,
    int val1,
    ItemType? item1,
    String name2,
    int val2,
    ItemType? item2,
    bool isSmallScreen,
    bool isRevealed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4D331F).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildStatRow(name1, val1, item1, isSmallScreen, isRevealed, true),
          const Divider(height: 16, thickness: 1),
          _buildStatRow(name2, val2, item2, isSmallScreen, isRevealed, false),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, int val, ItemType? item, bool isSmallScreen, bool isRevealed, bool isPlayer) {
    return Row(
      children: [
        Text(
          isPlayer ? '🐱' : '👴',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4D331F),
            ),
          ),
        ),
        if (item != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              item.displayName,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        Row(
          children: [
            const Text('🐟', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              val.toString(),
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
