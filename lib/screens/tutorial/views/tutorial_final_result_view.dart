import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../../../widgets/user_icon_widget.dart';
import '../../../models/user_profile.dart';
import '../tutorial_view_model.dart';
import '../../../services/se_service.dart';

class TutorialFinalResultView extends StatefulWidget {
  const TutorialFinalResultView({super.key});

  @override
  State<TutorialFinalResultView> createState() =>
      _TutorialFinalResultViewState();
}

class _TutorialFinalResultViewState extends State<TutorialFinalResultView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeService().play('victory.mp3');
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TutorialViewModel>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    return Container(
      color: const Color(0xFFFFF9E6), // 背景色
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: isSmallScreen ? 120.0 : 160.0, // ダイアログ分の余白
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 勝利者のバナーヘッダー（WIN!）
              _buildWinnerBanner('WIN！', Colors.green),
              const SizedBox(height: 16),

              // 最終スコアセクション
              _buildPopSection(
                title: '最終スコア',
                titleColor: const Color(0xFFFFCE35),
                child: Column(
                  children: [
                    _buildPopPlayerScore(
                      context,
                      viewModel,
                      viewModel.myDisplayName,
                      viewModel.myIconEmoji,
                      _getWonCardDetails(viewModel, true),
                    ),
                    const SizedBox(height: 16),
                    _buildPopPlayerScore(
                      context,
                      viewModel,
                      viewModel.opponentDisplayName,
                      viewModel.opponentIconEmoji,
                      _getWonCardDetails(viewModel, false),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '全2ターン終了',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4D331F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<_CardInfo> _getWonCardDetails(TutorialViewModel viewModel, bool isMy) {
    final inventory = isMy
        ? viewModel.playerData.myCatsWon
        : viewModel.playerData.opponentCatsWon;

    return inventory.countByName().entries.map((e) {
      final catName = e.key;
      final count = e.value;
      // チュートリアルでは 3種類集めているのですべて勝利カード扱い
      return _CardInfo(
        name: catName,
        cost: count * (catName.contains('茶トラ') ? 1 : 3), // 概算コスト
        color: viewModel.getCatIconColor(catName),
        icon: viewModel.getCatIconData(catName),
        imagePath: viewModel.getCatImagePath(catName),
        isWinningCard: isMy, // 自分がすべて取得して勝利
      );
    }).toList();
  }

  Widget _buildWinnerBanner(String text, Color color) {
    return StereoscopicContainer(
      baseColor: color,
      shadowColor: const Color(0xFF2E7D32),
      borderRadius: 40,
      depth: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        width: double.infinity,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPopSection({
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: titleColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4D331F), width: 2),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF4D331F),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFB38E5D), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPopPlayerScore(
    BuildContext context,
    TutorialViewModel viewModel,
    String name,
    String emoji,
    List<_CardInfo> cards,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4D4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                UserIconWidget(
                  icon: UserIcon.fromId(
                    name == viewModel.myDisplayName
                        ? viewModel.playerData.myIconId
                        : viewModel.playerData.opponentIconId,
                  ),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4D331F),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCE35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4D331F),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '🐟 ${cards.fold<int>(0, (sum, card) => sum + card.cost)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4D331F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cards.map((card) => _buildPopCardChip(card)).toList(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'カードなし',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopCardChip(_CardInfo card) {
    return Stack(
      children: [
        StereoscopicContainer(
          baseColor: Colors.white,
          shadowColor: card.isWinningCard
              ? card.color.withOpacity(0.5)
              : Colors.grey.shade300,
          borderRadius: 8,
          depth: card.isWinningCard ? 4 : 2,
          showStripes: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              border: card.isWinningCard
                  ? Border.all(color: card.color, width: 2)
                  : Border.all(color: Colors.grey.shade200, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCatAvatarFromCard(card, size: 28),
                const SizedBox(height: 2),
                Text(
                  '🐟${card.cost}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: card.isWinningCard
                        ? const Color(0xFF4D331F)
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (card.isWinningCard)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCatAvatarFromCard(_CardInfo card, {required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: card.imagePath != null
          ? Image.asset(card.imagePath!, fit: BoxFit.contain)
          : Icon(card.icon, color: card.color, size: size * 0.6),
    );
  }
}

class _CardInfo {
  final String name;
  final int cost;
  final Color color;
  final IconData icon;
  final String? imagePath;
  final bool isWinningCard;

  const _CardInfo({
    required this.name,
    required this.cost,
    required this.color,
    required this.icon,
    this.imagePath,
    required this.isWinningCard,
  });
}
