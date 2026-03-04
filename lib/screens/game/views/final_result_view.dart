import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../constants/game_constants.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/ad_service.dart';
import '../game_screen_view_model.dart';

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
      // 引き分けの場合は現状SEなし（または必要に応じて追加）
    } else if (room.finalWinner == myRole) {
      SeService().play('victory.mp3');
    } else {
      SeService().play('lose.mp3');
    }
  }

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
                                    '${viewModel.myIconEmoji}: ${item.myBet}${item.myItem != null ? '*' : ''} ${viewModel.opponentIconEmoji}: ${item.opponentBet}${item.opponentItem != null ? '*' : ''}',
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
                      '${viewModel.myIconEmoji} ${viewModel.myDisplayName}',
                      viewModel.myWonCardDetails,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    _buildPlayerCards(
                      context,
                      '${viewModel.opponentIconEmoji} ${viewModel.opponentDisplayName}',
                      viewModel.opponentWonCardDetails,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '全${widget.room.currentTurn}ターン終了',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                SeService().play('button_buni.mp3');

                // サポーターかどうかを確認
                final userRepository = Provider.of<UserRepository>(
                  context,
                  listen: false,
                );
                final profile = await userRepository.getProfile(
                  viewModel.playerId,
                );
                final isSupporter = profile?.isSupporter ?? false;

                if (!isSupporter) {
                  // サポーターでない場合は広告を表示
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
                  // サポーターの場合はそのまま戻る
                  viewModel.leaveRoom();
                }
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
