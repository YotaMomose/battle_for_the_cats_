import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../game_screen_view_model.dart';
import '../player_data.dart';
import '../../../widgets/stereoscopic_ui.dart';
import 'dart:math' as math;

/// つりフェーズ画面
class FishingPhaseView extends StatelessWidget {
  final GameRoom room;

  const FishingPhaseView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ターン情報 (ポップなバブル)
              _buildTurnHeader(isSmallScreen),
              const SizedBox(height: 16),

              // 相手の状態
              _buildOpponentState(viewModel, playerData, isSmallScreen),
              const SizedBox(height: 16),

              // タイトル
              const Text(
                '🌊 つりフェーズ 🌊',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A73E8),
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 自分のつり場
              _buildMyFishingArea(
                viewModel,
                playerData,
                context,
                isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnHeader(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFBF5F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4D331F), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4D331F), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFFF9800), size: 18),
          const SizedBox(width: 8),
          Text(
            'ターン ${room.currentTurn}',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, color: Color(0xFFFF9800), size: 18),
        ],
      ),
    );
  }

  Widget _buildOpponentState(
    GameScreenViewModel viewModel,
    PlayerData playerData,
    bool isSmallScreen,
  ) {
    return StereoscopicContainer(
      baseColor: const Color.fromARGB(255, 245, 143, 158).withOpacity(0.9),
      shadowColor: const Color.fromARGB(255, 180, 80, 100),
      borderRadius: 24,
      depth: 6,
      showDots: true,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 320,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${viewModel.opponentIconEmoji} ',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  viewModel.opponentDisplayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (viewModel.shouldShowOpponentRollResult) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('🐟', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '${playerData.opponentDiceRoll}${playerData.opponentFishermanCount > 0 ? ' + ${playerData.opponentFishermanCount}' : ''}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (playerData.opponentRolled)
              const Text(
                '準備完了！',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.green, blurRadius: 4)],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${viewModel.opponentDisplayName}が釣りをしています',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4D331F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const AnimatedWaitingDots(
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4D331F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyFishingArea(
    GameScreenViewModel viewModel,
    PlayerData playerData,
    BuildContext context,
    bool isSmallScreen,
  ) {
    return StereoscopicContainer(
      baseColor: const Color.fromARGB(255, 143, 208, 245).withOpacity(0.9),
      shadowColor: const Color.fromARGB(255, 80, 140, 180),
      borderRadius: 32,
      depth: 6,
      showDots: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        width: 320,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${viewModel.myIconEmoji} ',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  viewModel.myDisplayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // つり演出エリア
            SizedBox(
              height: 160, // 少し高さを確保
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 水面 (右側に寄せる)
                  Positioned(
                    right: 10,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade300,
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (viewModel.isFishingEffect)
                    const _FishingActionAnimation()
                  else if (viewModel.shouldShowMyRollResult)
                    Positioned(
                      right: 35, // 水面の中心あたり
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '獲物ゲット！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4D331F),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🐟', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Text(
                                '${playerData.myDiceRoll! + playerData.myFishermanCount}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.blue,
                                      offset: Offset(0, 3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // 待機状態 (竿だけ)
                    const Positioned(
                      left: 70,
                      child: Text('🎣', style: TextStyle(fontSize: 60)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (viewModel.shouldShowMyRollResult) ...[
              if (playerData.myFishermanCount > 0)
                Text(
                  '(漁師ボーナス +${playerData.myFishermanCount} 🐟)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4D331F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              if (viewModel.canProceedFromRoll)
                StereoscopicButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.confirmRoll();
                  },
                  baseColor: Colors.pink.shade400,
                  shadowColor: Colors.pink.shade900,
                  borderRadius: 30,
                  depth: 6,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    child: Text(
                      '次へ進む',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '相手を待っています...',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4D331F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ] else ...[
              StereoscopicButton(
                onPressed: (viewModel.hasRolled || viewModel.isFishingEffect)
                    ? null
                    : () {
                        SeService().play('button_buni.mp3');
                        viewModel.catchFish();
                      },
                baseColor: const Color(0xFF1A73E8),
                shadowColor: const Color(0xFF0D47A1),
                borderRadius: 30,
                depth: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.catching_pokemon,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        viewModel.fishButtonLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FishingActionAnimation extends StatefulWidget {
  const _FishingActionAnimation();

  @override
  State<_FishingActionAnimation> createState() =>
      _FishingActionAnimationState();
}

class _FishingActionAnimationState extends State<_FishingActionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // 1秒周期
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // ウキの沈み込み (0.8以上の時にピクッとする)
        final double progress = _controller.value;
        final bool isPulling = progress > 0.8;
        final double bobberOffset = isPulling
            ? 15.0
            : math.sin(progress * math.pi * 2) * 5.0;
        final double rodAngle = isPulling ? -0.1 : 0.0;

        return Stack(
          children: [
            // 1. 釣り竿と糸 (CustomPaint)
            Positioned.fill(
              child: CustomPaint(
                painter: _FishingLinePainter(
                  catPos: const Offset(80, 80),
                  bobberPos: Offset(210, 80 + bobberOffset),
                  rodAngle: rodAngle,
                ),
              ),
            ),

            // 3. ウキ (右側、水面の中。Offsetを調整)
            Positioned(
              right: 50,
              top: 40 + bobberOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔴', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 4),
                  if (isPulling)
                    const Text(
                      'ピクッ！',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4D331F),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 釣り竿と釣り糸を描画するペインター
class _FishingLinePainter extends CustomPainter {
  final Offset catPos;
  final Offset bobberPos;
  final double rodAngle;

  _FishingLinePainter({
    required this.catPos,
    required this.bobberPos,
    required this.rodAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rodPaint = Paint()
      ..color = const Color(0xFF4D331F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 竿の描画 (猫の手元から斜め上に)
    final Offset rodStart = catPos + const Offset(30, 0);
    final Offset rodEnd =
        rodStart +
        Offset(
          50 * math.cos(rodAngle - math.pi / 4),
          50 * math.sin(rodAngle - math.pi / 4),
        );
    canvas.drawLine(rodStart, rodEnd, rodPaint);

    // 糸の描画 (竿の先からウキのOffset位置へ)
    final Path path = Path();
    path.moveTo(rodEnd.dx, rodEnd.dy);

    // 糸のたわみを表現 (二次ベジェ曲線)
    final controlPoint = Offset(
      (rodEnd.dx + bobberPos.dx) / 2,
      math.max(rodEnd.dy, bobberPos.dy) + 20,
    );
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      bobberPos.dx,
      bobberPos.dy,
    );

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _FishingLinePainter oldDelegate) {
    return oldDelegate.bobberPos != bobberPos ||
        oldDelegate.rodAngle != rodAngle;
  }
}
