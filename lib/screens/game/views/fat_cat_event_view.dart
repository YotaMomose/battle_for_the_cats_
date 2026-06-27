import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../../../widgets/fish_icon.dart';

class FatCatEventView extends StatefulWidget {
  final GameRoom room;
  final VoidCallback onConfirm;

  const FatCatEventView({
    super.key,
    required this.room,
    required this.onConfirm,
  });

  @override
  State<FatCatEventView> createState() => _FatCatEventViewState();
}

class _FatCatEventViewState extends State<FatCatEventView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 巨大サイズから元のサイズへ急速に落下するアニメーション
    _scaleAnimation = Tween<double>(begin: 8.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.bounceOut),
      ),
    );

    _controller.forward();

    // 効果音（ドスン！という衝撃音の代わり）
    SeService().play('button_buni.mp3');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.red.shade900;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 画面揺れ (インパクト後、0.4〜0.8の区間)
          double shakeX = 0.0;
          double shakeY = 0.0;
          if (_controller.value > 0.4 && _controller.value < 0.8) {
            final shakeProgress = (_controller.value - 0.4) / 0.4; // 0.0 to 1.0
            final intensity = 20 * (1 - shakeProgress);
            shakeX = math.sin(shakeProgress * math.pi * 40) * intensity;
            shakeY = math.cos(shakeProgress * math.pi * 50) * intensity;
          }

          return Stack(
            children: [
              // 集中線背景
              Positioned.fill(
                child: CustomPaint(
                  painter: ActionLinesPainter(
                    color: Colors.red.shade700.withOpacity(0.6),
                    backgroundColor: bgColor,
                  ),
                ),
              ),

              // 飛び散るさかな
              ...List.generate(30, (index) {
                final random = math.Random(index);
                final startX =
                    random.nextDouble() * MediaQuery.of(context).size.width;
                // インパクト時(0.4)から降り始める
                final delay = 0.4 + random.nextDouble() * 0.2;
                final duration = 0.4 + random.nextDouble() * 0.4;
                final dropProgress = math.max(
                  0.0,
                  (_controller.value - delay) / duration,
                );

                if (dropProgress <= 0 || dropProgress >= 1)
                  return const SizedBox();

                final dropY =
                    -50 +
                    dropProgress * MediaQuery.of(context).size.height * 1.2;
                final rotation =
                    dropProgress * math.pi * 8 * (random.nextBool() ? 1 : -1);

                return Positioned(
                  left: startX,
                  top: dropY,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Opacity(
                      opacity:
                          1.0 -
                          (dropProgress > 0.8 ? (dropProgress - 0.8) * 5 : 0.0),
                      child: FishIcon(size: 24 + random.nextDouble() * 16),
                    ),
                  ),
                );
              }),

              // メインコンテンツ（揺れエフェクト適用）
              SafeArea(
                child: Transform.translate(
                  offset: Offset(shakeX, shakeY),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: math.min(
                            400.0,
                            MediaQuery.of(context).size.width - 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 巨大化から降ってくるふとっちょにゃんこ
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Opacity(
                                  opacity: _controller.value > 0.05 ? 1.0 : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.yellowAccent
                                              .withOpacity(
                                                0.5 * _controller.value,
                                              ),
                                          blurRadius: 40,
                                          spreadRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/fatcat.png',
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 被害報告パネル
                              AnimatedOpacity(
                                opacity: _controller.value > 0.6 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                child: AnimatedScale(
                                  scale: _controller.value > 0.6 ? 1.0 : 0.8,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  child: StereoscopicContainer(
                                    baseColor: Colors.white,
                                    shadowColor: Colors.black26,
                                    borderRadius: 24,
                                    depth: 8,
                                    showStripes: true,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'ふとっちょにゃんこ\n襲来！！',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.red,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'ふとっちょにゃんこがさかなを\n全部食べてしまいました！\n\n両プレイヤーのさかなが 0 になります。',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Divider(
                                                  color: Colors.red.shade200,
                                                  thickness: 1.5,
                                                ),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  '【食べられたさかなの数】',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    // ホスト側の数
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            widget.room.host
                                                                .displayName,
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const FishIcon(
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                '${widget.room.hostFatCatEatenFish}',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .red,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (widget.room.guest !=
                                                        null) ...[
                                                      Container(
                                                        width: 1.5,
                                                        height: 36,
                                                        color: Colors
                                                            .red.shade200,
                                                      ),
                                                      // ゲスト側の数
                                                      Expanded(
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              widget
                                                                  .room
                                                                  .guest!
                                                                  .displayName,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const FishIcon(
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  '${widget.room.guestFatCatEatenFish}',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .red,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // OKボタン
                              AnimatedOpacity(
                                opacity: _controller.value > 0.9 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                child: AnimatedScale(
                                  scale: _controller.value > 0.9 ? 1.0 : 0.8,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  child: StereoscopicButton(
                                    onPressed: () {
                                      SeService().play('button_buni.mp3');
                                      widget.onConfirm();
                                    },
                                    baseColor: const Color(0xFFFF5252),
                                    shadowColor: const Color(0xFFD32F2F),
                                    borderRadius: 30,
                                    depth: 8,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'OK',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ActionLinesPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;

  ActionLinesPainter({required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 1.5;

    // 集中線を描画
    for (int i = 0; i < 72; i++) {
      if (i % 2 == 0) continue; // 間隔を空ける

      final angle1 = i * 5 * math.pi / 180;
      final angle2 = (i + 1) * 5 * math.pi / 180;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(angle1),
          center.dy + radius * math.sin(angle1),
        )
        ..lineTo(
          center.dx + radius * math.cos(angle2),
          center.dy + radius * math.sin(angle2),
        )
        ..close();

      canvas.drawPath(path, paint);
    }

    // 中心を隠して集中線を外側だけにする
    final rect = Rect.fromCircle(center: center, radius: size.width * 0.8);
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [backgroundColor, backgroundColor.withOpacity(0.0)],
        stops: const [0.3, 1.0],
      ).createShader(rect);

    canvas.drawRect(Offset.zero & size, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
