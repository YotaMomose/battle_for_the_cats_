import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../constants/game_constants.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/ad_service.dart';
import '../../../models/item.dart';
import '../game_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../../../widgets/user_icon_widget.dart';
import '../../../models/user_profile.dart';

/// 最終結果画面
class FinalResultView extends StatefulWidget {
  final GameRoom room;

  const FinalResultView({super.key, required this.room});

  @override
  State<FinalResultView> createState() => _FinalResultViewState();
}

class _FinalResultViewState extends State<FinalResultView> {
  @override
  void initState() {
    super.initState();
    // 画面表示時に勝敗に応じたSEを再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playResultSound();
    });
  }

  void _playResultSound() {
    if (!mounted) return;
    final viewModel = Provider.of<GameScreenViewModel>(context, listen: false);
    final room = widget.room;

    final myRole = viewModel.isHost ? Winner.host : Winner.guest;
    if (room.finalWinner == Winner.draw) {
      // 引き分けの場合は現状SEなし
    } else if (room.finalWinner == myRole) {
      SeService().play('victory.mp3');
    } else {
      SeService().play('lose.mp3');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final resultColor = viewModel.finalWinnerColor;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    final String popResultText;
    if (widget.room.finalWinner == Winner.draw) {
      popResultText = 'DRAW';
    } else if (widget.room.finalWinner ==
        (viewModel.isHost ? Winner.host : Winner.guest)) {
      popResultText = 'WIN！';
    } else {
      popResultText = 'LOSE...';
    }

    return Container(
      color: const Color(0xFFFFF9E6), // 背景色
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 勝利者のバナーヘッダー（WIN! / LOSE...）
              _buildWinnerBanner(popResultText, resultColor),
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
                      viewModel.myWonCardDetails,
                    ),
                    const SizedBox(height: 16),
                    _buildPopPlayerScore(
                      context,
                      viewModel,
                      viewModel.opponentDisplayName,
                      viewModel.opponentIconEmoji,
                      viewModel.opponentWonCardDetails,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '全${widget.room.currentTurn}ターン終了',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4D331F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 最終ターンの結果セクション（RoundResultViewと同じレイアウト）
              if (viewModel.lastRoundDisplayItems.isNotEmpty)
                _buildPopSection(
                  title: '最終ターンの結果',
                  titleColor: const Color(0xFFFFCE35),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(
                        viewModel.lastRoundDisplayItems.length,
                        (index) {
                          final item = viewModel.lastRoundDisplayItems[index];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: _buildResultCatCard(
                                context,
                                item,
                                viewModel,
                                isSmallScreen,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ホームに戻るボタン
              _buildHomeButton(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  /// 勝利者を表示するバナー（勝敗に応じた色分け）
  Widget _buildWinnerBanner(String text, Color color) {
    // スコアに応じた影の色を計算（簡易的）
    final Color shadowColor = color == Colors.green
        ? const Color(0xFF2E7D32) // 濃い緑
        : color == Colors.red
        ? const Color(0xFFC62828) // 濃い赤
        : const Color(0xFF616161); // 濃いグレー（引き分け）

    final Color textColor = color == Colors.grey
        ? const Color(0xFF4D331F)
        : Colors.white;

    return StereoscopicContainer(
      baseColor: color, // 勝敗に応じた色を採用
      shadowColor: shadowColor,
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
            color: textColor,
            // 文字の視認性を高めるためのシャドウ（特に白文字用）
            shadows: color != Colors.grey
                ? [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 各セクションの白い丸角ボックス
  Widget _buildPopSection({
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Column(
      children: [
        // タイトルラベル
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

  /// 猫のカード（RoundResultViewと同じ詳細レイアウト）
  Widget _buildResultCatCard(
    BuildContext context,
    RoundDisplayItem item,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    return StereoscopicContainer(
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
                fontSize: isSmallScreen ? 10 : 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          // 猫アバター
          _buildCatAvatar(item, size: isSmallScreen ? 45 : 60),
          const Spacer(),
          // 結果ラベル
          _buildCapsuleLabel(
            item.winnerLabel,
            textColor: item.winnerTextColor,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
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
    );
  }

  /// 統計テーブル
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

  /// 統計行
  Widget _buildStatRow(
    String label,
    String value,
    ItemType? item,
    bool isSmallScreen,
  ) {
    final hasItem = item != null && item != ItemType.unknown;
    final fishSize = hasItem
        ? (isSmallScreen ? 18.0 : 26.0)
        : (isSmallScreen ? 24.0 : 36.0);
    final itemIconSize = isSmallScreen ? 12.0 : 16.0;
    final rowHeight = isSmallScreen ? 40.0 : 55.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        height: rowHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasItem) ...[
                  _buildSmallItemIcon(item, size: itemIconSize),
                  const SizedBox(width: 4),
                ],
                _buildFishWithNumber(value, size: fishSize),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 小さなアイテムアイコン
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

  /// 魚アイコンと数字
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

  /// カプセル型ラベル
  Widget _buildCapsuleLabel(
    String text, {
    Color textColor = const Color(0xFF4D331F),
    bool isSmallScreen = false,
  }) {
    final fontSize = isSmallScreen ? 10.0 : 14.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }

  /// プレイヤーごとのスコア表示
  Widget _buildPopPlayerScore(
    BuildContext context,
    GameScreenViewModel viewModel,
    String name,
    String emoji,
    List<FinalResultCardInfo> cards,
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
                // アイコン
                UserIconWidget(
                  icon: UserIcon.fromId(
                    name == viewModel.myDisplayName
                        ? viewModel.myIconId
                        : viewModel.opponentIconId,
                  ),
                  size: 48,
                ),
                const SizedBox(width: 12),
                // 名前
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
                // スコア（魚の合計コスト）
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
          // 獲得したカードのチップ
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

  /// 獲得カードのチップ（バトル画面と同様の、アバター＋コスト表示）
  Widget _buildPopCardChip(FinalResultCardInfo card) {
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
              // 勝利条件カードの場合は、枠線を付けて強調
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
        // 勝利条件の一部である場合にチェックマークを表示
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

  /// ホームに戻るボタン
  Widget _buildHomeButton(BuildContext context, GameScreenViewModel viewModel) {
    return StereoscopicButton(
      baseColor: const Color(0xFF5ABA61), // 緑
      shadowColor: const Color(0xFF3E7F43),
      borderRadius: 30,
      depth: 8,
      onPressed: () async {
        SeService().play('button_buni.mp3');

        final userRepository = Provider.of<UserRepository>(
          context,
          listen: false,
        );
        final profile = await userRepository.getProfile(viewModel.playerId);
        final isSupporter = profile?.isSupporter ?? false;

        if (!isSupporter) {
          if (context.mounted) {
            await AdService().showInterstitialAd(
              onAdClosed: () {
                if (context.mounted) {
                  viewModel.leaveRoom();
                }
              },
            );
          }
        } else {
          viewModel.leaveRoom();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ホームに戻る',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 猫のアバター
  Widget _buildCatAvatar(RoundDisplayItem item, {required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: item.imagePath != null
          ? Image.asset(item.imagePath!, fit: BoxFit.contain)
          : Icon(item.catIcon, color: item.catIconColor, size: size * 0.6),
    );
  }

  /// 猫のアバター（カード用）
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
