import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/item.dart';
import '../game_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';

/// ラウンド結果画面
class RoundResultView extends StatelessWidget {
  final GameRoom room;

  const RoundResultView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final displayTurn = viewModel.displayTurn;
    final isConfirmed = viewModel.isRoundResultConfirmed;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    // 犬の効果通知がある場合、ビルド後にポップアップを表示
    if (viewModel.dogEffectNotifications.isNotEmpty) {
      final notifications = List<DogEffectNotification>.from(
        viewModel.dogEffectNotifications,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 表示直前にクリアすることで、再ビルドによる重複表示を防ぐ
        viewModel.clearDogNotifications();
        _showDogEffectPopup(context, notifications, isSmallScreen, viewModel);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ヘッダー
                _buildHeader(displayTurn, isSmallScreen),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isSmallScreen ? 12 : 20,
                  ),
                  child: Column(
                    children: [
                      // 累計結果
                      _buildCumulativeResult(context, viewModel, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 32),

                      // 猫カードの横並び
                      _buildCatCardRow(context, viewModel, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 32),

                      // 特殊効果UI (復活/追い出し) - ボタンの上に配置
                      if (viewModel.canReviveItem) ...[
                        _buildReviveSection(context, viewModel, isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                      ],
                      if (viewModel.canChaseAway) ...[
                        _buildChaseAwaySection(
                          context,
                          viewModel,
                          isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                      ],

                      // 次のターンへボタン
                      _buildNextButton(viewModel, isConfirmed, isSmallScreen),
                      const SizedBox(height: 120), // 余裕を持たせる
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDogEffectPopup(
    BuildContext context,
    List<DogEffectNotification> notifications,
    bool isSmallScreen,
    GameScreenViewModel viewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StereoscopicContainer(
              baseColor: Colors.white,
              shadowColor: Colors.red.shade200,
              borderRadius: 24,
              depth: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/inu.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '犬の効果発動！',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...notifications.map(
                      (n) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (n.imagePath != null)
                              Image.asset(
                                n.imagePath!,
                                width: isSmallScreen ? 40 : 50,
                                height: isSmallScreen ? 40 : 50,
                                fit: BoxFit.contain,
                              )
                            else
                              const Icon(Icons.pets, color: Colors.grey),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                n.message,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4D331F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StereoscopicButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      baseColor: const Color(0xFFFFD54F),
                      shadowColor: const Color(0xFFE58900),
                      borderRadius: 16,
                      depth: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF4D331F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int turn, bool isSmallScreen) {
    final headerHeight = isSmallScreen ? 50.0 : 80.0;
    final fontSize = isSmallScreen ? 24.0 : 36.0;
    final starSize = isSmallScreen ? 24.0 : 36.0;

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        boxShadow: [
          BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 4),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StripePainter(
                color: Colors.white.withOpacity(0.2),
                stripeWidth: 20,
              ),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: const Color(0xFFE58900),
                  size: starSize,
                ),
                const SizedBox(width: 16),
                Text(
                  'ターン $turn けっか！',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4D331F),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.star,
                  color: const Color(0xFFE58900),
                  size: starSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeResult(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    return StereoscopicContainer(
      baseColor: const Color(0xFFC8E6C9), // 薄い緑
      shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
      borderRadius: 24,
      showDots: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCapsuleHeader(
              '累計',
              color: const Color(0xFF66BB6A),
              isSmallScreen: isSmallScreen,
            ),
            const SizedBox(height: 16),
            _buildPlayerCumulativeRow(
              viewModel.myIconEmoji,
              viewModel.myDisplayName,
              viewModel.myWonCardDetails,
              isSmallScreen,
            ),
            const SizedBox(height: 10),
            _buildPlayerCumulativeRow(
              viewModel.opponentIconEmoji,
              viewModel.opponentDisplayName,
              viewModel.opponentWonCardDetails,
              isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviveSection(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/shop.png',
                width: isSmallScreen ? 32 : 48,
                height: isSmallScreen ? 32 : 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'の詳細効果発動！',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 27,
                  fontWeight: FontWeight.w900,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '使用済みのアイテムを復活できます（残り ${viewModel.playerData?.myPendingItemRevivals ?? 0}回）',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (viewModel.revivableItems.isEmpty)
            const Text('復活できるアイテムがありません', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: viewModel.revivableItems.map((item) {
                return StereoscopicButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.reviveItem(item);
                  },
                  baseColor: Colors.white,
                  shadowColor: Colors.purple.shade200,
                  borderRadius: 16,
                  depth: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.imagePath != null)
                          Image.asset(
                            item.imagePath!,
                            width: isSmallScreen ? 40 : 56,
                            height: isSmallScreen ? 40 : 56,
                            fit: BoxFit.contain,
                          )
                        else
                          Icon(
                            Icons.refresh,
                            size: isSmallScreen ? 40 : 56,
                            color: Colors.purple,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          item.displayName,
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w900,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChaseAwaySection(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/inu.png',
                width: isSmallScreen ? 32 : 48,
                height: isSmallScreen ? 32 : 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'の効果発動！',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 27,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '(残り ${viewModel.remainingDogChases}回)',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          if (viewModel.availableTargetsForDog.isEmpty)
            const Text(
              '追い出せる相手のキャラクターがいません',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: viewModel.availableTargetsForDog.map((catName) {
                final imagePath = viewModel.getCatImagePath(catName);
                return StereoscopicButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.chaseAwayCard(catName);
                  },
                  baseColor: Colors.white,
                  shadowColor: Colors.red.shade200,
                  borderRadius: 16,
                  depth: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imagePath != null)
                          Image.asset(
                            imagePath,
                            width: isSmallScreen ? 48 : 64,
                            height: isSmallScreen ? 48 : 64,
                            fit: BoxFit.contain,
                          )
                        else
                          Icon(
                            Icons.pets,
                            size: isSmallScreen ? 48 : 64,
                            color: viewModel.getCatIconColor(catName),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          catName,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          StereoscopicButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              viewModel.chaseAwayCard(null);
            },
            baseColor: Colors.grey.shade200,
            shadowColor: Colors.grey.shade400,
            borderRadius: 12,
            depth: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.skip_next, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'スキップする',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 14 : 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCumulativeRow(
    String emoji,
    String name,
    List<FinalResultCardInfo> cards,
    bool isSmallScreen,
  ) {
    return Container(
      height: isSmallScreen ? 44 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Row(
        children: [
          _buildCircleIcon(emoji, isSmallScreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
                fontSize: isSmallScreen ? 16 : 20,
              ),
            ),
          ),
          if (cards.isEmpty)
            Text(
              'なし',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            _buildWonCardsIconListSmall(cards, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildCatCardRow(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(viewModel.lastRoundDisplayItems.length, (
          index,
        ) {
          final item = viewModel.lastRoundDisplayItems[index];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StereoscopicContainer(
                baseColor: item.cardColor.withOpacity(0.9),
                shadowColor: Colors.black12,
                borderRadius: 20,
                depth: 4,
                showDots: true,
                child: Column(
                  children: [
                    // カード名
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
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
                          fontSize: isSmallScreen ? 12 : 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4D331F),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    // 猫アバター
                    _buildCatAvatar(item, size: isSmallScreen ? 56 : 80),
                    const Spacer(),
                    // 結果ラベル
                    _buildCapsuleLabel(
                      item.winnerLabel,
                      color: item.cardColor,
                      textColor: item.winnerTextColor,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    // 詳細スコアテーブル
                    _buildSmallStatsTable(
                      viewModel.myDisplayName,
                      item.myBet.toString(),
                      item.myItem,
                      viewModel.opponentDisplayName,
                      item.opponentBet.toString(),
                      item.opponentItem,
                      isSmallScreen,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSmallStatsTable(
    String name1,
    String val1,
    ItemType? item1,
    String name2,
    String val2,
    ItemType? item2,
    bool isSmallScreen,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4D331F).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildStatRow(name1, val1, item1, isSmallScreen),
          Divider(
            height: isSmallScreen ? 8 : 12,
            thickness: 1,
            color: const Color(0xFF4D331F).withOpacity(0.2),
          ),
          _buildStatRow(name2, val2, item2, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    ItemType? item,
    bool isSmallScreen,
  ) {
    final fishSize = isSmallScreen ? 34.0 : 48.0;
    final itemIconSize = isSmallScreen ? 18.0 : 26.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1段目: プレイヤー名
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4D331F),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 2段目: アイテムと魚
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item != null && item != ItemType.unknown) ...[
                _buildSmallItemIcon(item, size: itemIconSize),
                const SizedBox(width: 8),
              ],
              _buildFishWithNumber(value, size: fishSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallItemIcon(ItemType item, {double size = 21}) {
    return (item.imagePath != null)
        ? Image.asset(
            item.imagePath!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          )
        : Icon(Icons.help_outline, size: size, color: Colors.blueAccent);
  }

  Widget _buildFishWithNumber(String number, {double size = 45}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('🐟', style: TextStyle(fontSize: size, height: 1.0)),
        Text(
          number,
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 4),
              Shadow(color: Colors.white, blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(
    GameScreenViewModel viewModel,
    bool isConfirmed,
    bool isSmallScreen,
  ) {
    final canChase = viewModel.canChaseAway;
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 50 : 72,
      child: StereoscopicButton(
        onPressed: (isConfirmed || canChase)
            ? null
            : () {
                SeService().play('button_buni.mp3');
                viewModel.nextTurn();
              },
        baseColor: const Color(0xFFF57C00),
        shadowColor: const Color(0xFFBF360C),
        borderRadius: 36,
        depth: 8,
        child: Center(
          child: Text(
            canChase
                ? (isSmallScreen ? 'カードを選択' : '追い出すカードを選択してください')
                : (isConfirmed
                      ? '確認待ち...'
                      : (isSmallScreen ? '次へ ▶' : '次のターンへ ▶')),
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- ヘルパー ---

  Widget _buildCapsuleHeader(
    String text, {
    required Color color,
    bool isSmallScreen = false,
  }) {
    final fontSize = isSmallScreen ? 14.0 : 21.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildCapsuleLabel(
    String text, {
    required Color color,
    Color textColor = const Color(0xFF4D331F),
    bool isSmallScreen = false,
  }) {
    final fontSize = isSmallScreen ? 12.0 : 18.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildCircleIcon(String emoji, bool isSmallScreen) {
    final size = isSmallScreen ? 24.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 12 : 16)),
    );
  }

  Widget _buildWonCardsIconListSmall(
    List<FinalResultCardInfo> cards,
    bool isSmallScreen,
  ) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: cards.map((card) {
        return _buildCatAvatarFromCard(card, size: isSmallScreen ? 24 : 32);
      }).toList(),
    );
  }

  Widget _buildCatAvatar(RoundDisplayItem item, {required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: item.imagePath != null
          ? Image.asset(item.imagePath!, fit: BoxFit.contain)
          : Icon(item.catIcon, color: item.catIconColor, size: size * 0.6),
    );
  }

  Widget _buildCatAvatarFromCard(
    FinalResultCardInfo card, {
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: card.imagePath != null
          ? Image.asset(card.imagePath!, fit: BoxFit.contain)
          : Icon(card.icon, color: card.color, size: size * 0.6),
    );
  }
}

class StripePainter extends CustomPainter {
  final Color color;
  final double stripeWidth;

  StripePainter({required this.color, required this.stripeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth;

    for (double i = -size.height; i < size.width; i += stripeWidth * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
