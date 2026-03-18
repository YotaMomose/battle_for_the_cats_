import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/item.dart';
import '../game_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../../../widgets/paw_background.dart';

/// ラウンド結果画面
class RoundResultView extends StatelessWidget {
  final GameRoom room;

  const RoundResultView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final displayTurn = viewModel.displayTurn;
    final isConfirmed = viewModel.isRoundResultConfirmed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ヘッダー
                _buildHeader(displayTurn),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      // 犬の効果の通知メッセージ
                      ...viewModel.dogEffectNotifications.map((message) => _buildDogNotification(message)),
                      if (viewModel.dogEffectNotifications.isNotEmpty)
                        const SizedBox(height: 16),

                      // 累計結果
                      _buildCumulativeResult(context, viewModel),
                      const SizedBox(height: 16),

                      // 特殊効果UI (復活/追い出し)
                      if (viewModel.canReviveItem) ...[
                        _buildReviveSection(context, viewModel),
                        const SizedBox(height: 16),
                      ],
                      if (viewModel.canChaseAway) ...[
                        _buildChaseAwaySection(context, viewModel),
                        const SizedBox(height: 16),
                      ],

                      // 猫カードの横並び
                      _buildCatCardRow(context, viewModel),
                      const SizedBox(height: 32),

                      // 次のターンへボタン
                      _buildNextButton(viewModel, isConfirmed),
                      const SizedBox(height: 100), // PawBackgroundが見えるように
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

  Widget _buildHeader(int turn) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
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
                const Icon(Icons.star, color: Color(0xFFE58900), size: 24),
                const SizedBox(width: 16),
                Text(
                  'ターン $turn けっか！',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331F),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Color(0xFFE58900), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogNotification(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300, width: 2),
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
    );
  }

  Widget _buildCumulativeResult(BuildContext context, GameScreenViewModel viewModel) {
    return StereoscopicContainer(
      baseColor: const Color(0xFFC8E6C9), // 薄い緑
      shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
      borderRadius: 24,
      showDots: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCapsuleHeader('累計', color: const Color(0xFF66BB6A)),
            const SizedBox(height: 16),
            _buildPlayerCumulativeRow(
              viewModel.myIconEmoji,
              viewModel.myDisplayName,
              viewModel.myWonCardDetails,
            ),
            const SizedBox(height: 10),
            _buildPlayerCumulativeRow(
              viewModel.opponentIconEmoji,
              viewModel.opponentDisplayName,
              viewModel.opponentWonCardDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviveSection(BuildContext context, GameScreenViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            '✨ アイテム復活効果発動！ ✨',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '使用済みのアイテムを復活できます（残り ${viewModel.playerData?.myPendingItemRevivals ?? 0}回）',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (viewModel.revivableItems.isEmpty)
            const Text(
              '復活できるアイテムがありません',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: viewModel.revivableItems.map((item) {
                return StereoscopicButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.reviveItem(item);
                  },
                  baseColor: Colors.white,
                  shadowColor: Colors.purple.shade200,
                  borderRadius: 12,
                  depth: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          item.displayName,
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w900,
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

  Widget _buildChaseAwaySection(BuildContext context, GameScreenViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '🐶 犬の効果発動中！ (残り ${viewModel.remainingDogChases}回)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '相手のキャラクターを1枚選んで追い出せます',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              children: viewModel.availableTargetsForDog.map((catName) {
                return StereoscopicButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.chaseAwayCard(catName);
                  },
                  baseColor: Colors.white,
                  shadowColor: Colors.red.shade200,
                  borderRadius: 12,
                  depth: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      catName,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => viewModel.chaseAwayCard(null),
            icon: const Icon(Icons.skip_next, size: 18),
            label: const Text('すべての効果をスキップする'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCumulativeRow(
    String emoji,
    String name,
    List<FinalResultCardInfo> cards,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Row(
        children: [
          _buildCircleIcon(emoji),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF4D331F),
              ),
            ),
          ),
          if (cards.isEmpty)
            const Text(
              'なし',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            _buildWonCardsIconListSmall(cards),
        ],
      ),
    );
  }

  Widget _buildCatCardRow(BuildContext context, GameScreenViewModel viewModel) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          viewModel.lastRoundDisplayItems.length,
          (index) {
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4D331F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 猫アバター
                      _buildCatAvatar(item, size: 64),
                      const Spacer(),
                      // 結果ラベル
                      _buildCapsuleLabel(
                        item.winnerLabel,
                        color: const Color(0xFFFFB74D),
                      ),
                      const SizedBox(height: 12),
                      // 詳細スコアテーブル
                      _buildSmallStatsTable(
                        viewModel.myDisplayName,
                        item.myBet.toString(),
                        viewModel.opponentDisplayName,
                        item.opponentBet.toString(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmallStatsTable(String name1, String val1, String name2, String val2) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4D331F).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildStatRow(name1, val1),
          const Divider(height: 4, thickness: 0.5),
          _buildStatRow(name2, val2),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildNextButton(GameScreenViewModel viewModel, bool isConfirmed) {
    final canChase = viewModel.canChaseAway;
    return SizedBox(
      width: double.infinity,
      height: 72,
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
                ? '追い出すカードを選択してください'
                : (isConfirmed ? '相手の確認待ち...' : '次のターンへ ▶'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- ヘルパー ---

  Widget _buildCapsuleHeader(String text, {required Color color}) {
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCapsuleLabel(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF4D331F),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextCapsule(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4D331F)),
      ),
    );
  }

  Widget _buildCircleIcon(String emoji) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildWonCardsIconListSmall(List<FinalResultCardInfo> cards) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: cards.map((card) {
        return _buildCatAvatarFromCard(card, size: 24);
      }).toList(),
    );
  }

  Widget _buildCatAvatar(RoundDisplayItem item, {double size = 56}) {
    if (item.imagePath != null) {
      return Image.asset(
        item.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(item.catIcon, size: size, color: item.catIconColor),
      );
    }
    return Icon(item.catIcon, size: size, color: item.catIconColor);
  }

  Widget _buildCatAvatarFromCard(FinalResultCardInfo card, {double size = 18}) {
    if (card.imagePath != null) {
      return Image.asset(
        card.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(card.icon, size: size, color: card.color),
      );
    }
    return Icon(card.icon, size: size, color: card.color);
  }
}

class StripePainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double gap;

  StripePainter({required this.color, this.stripeWidth = 20, this.gap = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width; i += stripeWidth + gap) {
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
