import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../services/se_service.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../tutorial_view_model.dart';

/// チュートリアル用の判定結果画面（タイマーステップと完全に同期する）
class TutorialRoundResultView extends StatefulWidget {
  const TutorialRoundResultView({super.key});

  @override
  State<TutorialRoundResultView> createState() =>
      _TutorialRoundResultViewState();
}

class _TutorialRoundResultViewState extends State<TutorialRoundResultView> {
  Set<int> _revealedItemIndices = {};
  Set<int> _revealedMultiplierIndices = {};
  Set<int> _stampedIndices = {};

  int _animatingIndex = -1;
  int? _lastStep;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStepChange(context.read<TutorialViewModel>().currentStep);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleStepChange(int step) {
    if (!mounted) return;
    final viewModel = context.read<TutorialViewModel>();

    _timer?.cancel();

    setState(() {
      // ステップに応じた演出の「開始」トリガーのみを管理
      if (step == 11) {
        // カード1の演出開始
        _startCardAnimation(0, viewModel);
      } else if (step == 12) {
        // カード1を完了、カード2はまだ開始しない（表示切り替え待ち）
        _forceCompleteCard(0);
        viewModel.setAnimationFinished(true);
      } else if (step == 13) {
        // カード2を表示し、演出開始
        _forceCompleteCard(0);
        _startCardAnimation(1, viewModel);
      } else if (step == 14) {
        // カード3を表示し、演出開始（スタンプ前で止める）
        _forceCompleteCard(0);
        _forceCompleteCard(1);
        _startCardAnimation(2, viewModel, pauseBeforeStamp: true);
      } else if (step == 15) {
        // カード3のアイテム解説中にスタンプを表示
        _forceCompleteCard(1);
        _revealedItemIndices.add(2);
        _revealedMultiplierIndices.add(2);
        _startStampOnly(2, viewModel);
      } else if (step == 16) {
        // カード3の結果解説
        _forceCompleteCard(1);
        _forceCompleteCard(2);
        viewModel.setAnimationFinished(true);
      } else if (step >= 17 && step < 30) {
        _forceCompleteCard(0);
        _forceCompleteCard(1);
        _forceCompleteCard(2);
        viewModel.setAnimationFinished(true);
      } else if (step == 31) {
        // カード0 演出開始 (しろねこ・びっくりホーン)
        _revealedItemIndices.clear();
        _revealedMultiplierIndices.clear();
        _stampedIndices.clear();
        _startCardAnimation(0, viewModel);
      } else if (step == 32) {
        // カード0 結果確認
        _forceCompleteCard(0);
        viewModel.setAnimationFinished(true);
      } else if (step == 33) {
        // カード1 演出開始 (しろねこ・自分3 vs 相手4)
        _forceCompleteCard(0);
        _startCardAnimation(1, viewModel);
      } else if (step == 34 || step == 35) {
        // カード1 結果確認・解説
        _forceCompleteCard(1);
        viewModel.setAnimationFinished(true);
      } else if (step == 36) {
        // カード2 演出開始 (茶トラ)
        _forceCompleteCard(1);
        _startCardAnimation(2, viewModel);
      } else if (step == 37) {
        // カード2 結果確認
        _forceCompleteCard(2);
        viewModel.setAnimationFinished(true);
      } else if (step >= 38) {
        _forceCompleteCard(0);
        _forceCompleteCard(1);
        _forceCompleteCard(2);
        viewModel.setAnimationFinished(true);
      }
    });
  }

  void _startCardAnimation(
    int index,
    TutorialViewModel viewModel, {
    bool pauseBeforeStamp = false,
  }) {
    if (_stampedIndices.contains(index)) {
      viewModel.setAnimationFinished(true);
      return;
    }

    _animatingIndex = index;
    viewModel.setAnimationFinished(false);

    final items = viewModel.roundResultItems;
    final item = items[index];
    final maxBet = item.myBet > item.opponentBet
        ? item.myBet
        : item.opponentBet;

    // カウントアップ開始
    _timer = Timer(Duration(milliseconds: 800 + (maxBet * 800)), () {
      if (!mounted) return;
      setState(() {
        _revealedItemIndices.add(index);
      });

      // アイテム登場
      if (item.myItem == ItemType.matatabi ||
          item.opponentItem == ItemType.matatabi) {
        _timer = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _revealedMultiplierIndices.add(index);
          });
          _afterItemReveal(index, viewModel, pauseBeforeStamp);
        });
      } else {
        _afterItemReveal(index, viewModel, pauseBeforeStamp);
      }
    });
  }

  // スタンプ演出のみを単独で開始
  void _startStampOnly(int index, TutorialViewModel viewModel) {
    if (_stampedIndices.contains(index)) {
      viewModel.setAnimationFinished(true);
      return;
    }
    _animatingIndex = -1; // カウントアップはなし
    viewModel.setAnimationFinished(false);
    _afterItemReveal(index, viewModel, false);
  }

  void _afterItemReveal(
    int index,
    TutorialViewModel viewModel,
    bool pauseBeforeStamp,
  ) {
    if (pauseBeforeStamp) {
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        viewModel.setAnimationFinished(true);
      });
      return;
    }

    // スタンプ
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      SeService().play('button_buni.mp3');
      setState(() {
        _stampedIndices.add(index);
      });

      _timer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        viewModel.setAnimationFinished(true);
      });
    });
  }

  void _forceCompleteCard(int index) {
    _revealedItemIndices.add(index);
    _stampedIndices.add(index);
    final viewModel = context.read<TutorialViewModel>();
    final items = viewModel.roundResultItems;
    if (index < items.length) {
      final item = items[index];
      if (item.myItem == ItemType.matatabi ||
          item.opponentItem == ItemType.matatabi) {
        _revealedMultiplierIndices.add(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TutorialViewModel>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;
    final step = viewModel.currentStep;

    if (_lastStep != step) {
      _lastStep = step;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleStepChange(step);
      });
    }

    final displayIndex = _getCurrentDisplayIndex(step);

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFD5),
      body: Column(
        children: [
          _buildHeader(viewModel, isSmallScreen),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (step < 16 || (step >= 31 && step <= 36))
                    ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              // フェードインと共にスライド
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.3, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                        child: Container(
                          key: ValueKey<int>(displayIndex),
                          child: _buildSingleLargeCard(
                            context,
                            viewModel,
                            isSmallScreen,
                            displayIndex,
                            step,
                          ),
                        ),
                      ),
                    )
                  else
                    _buildCatCardRow(context, viewModel, isSmallScreen),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentDisplayIndex(int step) {
    if (step <= 11) return 0;
    if (step == 13) return 1;
    if (step >= 14 && step <= 15) return 2;

    // 第2ラウンド
    if (step == 31 || step == 32) return 0;
    if (step >= 33 && step <= 34) return 1;
    if (step >= 36) return 2;

    return 0;
  }

  Widget _buildHeader(TutorialViewModel viewModel, bool isSmallScreen) {
    final headerHeight = isSmallScreen ? 30.0 : 50.0;
    final fontSize = isSmallScreen ? 20.0 : 30.0;

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
              painter: _StripePainter(
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
                  size: isSmallScreen ? 16 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'ターン ${viewModel.round} けっか！',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4D331F),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.star,
                  color: const Color(0xFFE58900),
                  size: isSmallScreen ? 16 : 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLargeCard(
    BuildContext context,
    TutorialViewModel viewModel,
    bool isSmallScreen,
    int index,
    int step,
  ) {
    final items = viewModel.roundResultItems;
    if (index >= items.length) return const SizedBox();

    final item = items[index];
    final isCounting =
        _animatingIndex == index && !_revealedItemIndices.contains(index);
    final isRevealed = _stampedIndices.contains(index);
    final showStats =
        _animatingIndex == index || _revealedItemIndices.contains(index);

    Color cardColor;
    Color winnerTextColor;
    String winnerLabel;

    if (item.winStatus == 'win') {
      cardColor = const Color.fromARGB(255, 243, 63, 9);
      winnerTextColor = const Color.fromARGB(255, 224, 12, 12);
      winnerLabel = 'GET!';
    } else if (item.winStatus == 'lose') {
      cardColor = const Color(0xFF90CAF9);
      winnerTextColor = const Color(0xFF0D47A1);
      winnerLabel = 'LOST..';
    } else {
      cardColor = Colors.grey.shade100;
      winnerTextColor = Colors.grey;
      winnerLabel = 'DRAW';
    }

    final catCost = _getCatCost(item.catName);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSmallScreen ? 240 : 320),
        child: StereoscopicContainer(
          baseColor: isRevealed
              ? cardColor.withOpacity(0.9)
              : Colors.grey.shade100,
          shadowColor: Colors.black12,
          borderRadius: 24,
          depth: isCounting ? 12 : 6,
          showDots: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Text(
                  item.catName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4D331F),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildCatAvatar(
                    viewModel,
                    item.catName,
                    size: isSmallScreen ? 100 : 160,
                  ),
                  AnimatedScale(
                    scale: isRevealed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: winnerTextColor, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: winnerTextColor.withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Text(
                          winnerLabel,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 40 : 56,
                            fontWeight: FontWeight.w900,
                            color: winnerTextColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4D331F),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$catCost',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4D331F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🐟', style: TextStyle(fontSize: 14)),
                    if (_revealedMultiplierIndices.contains(index))
                      Text(
                        ' ×2',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSmallStatsTable(
                  viewModel.opponentDisplayName,
                  item.opponentBet,
                  item.opponentItem,
                  viewModel.myDisplayName,
                  item.myBet,
                  item.myItem,
                  isSmallScreen,
                  showStats,
                  index,
                  isCounting,
                  isRevealed,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatCardRow(
    BuildContext context,
    TutorialViewModel viewModel,
    bool isSmallScreen,
  ) {
    final items = viewModel.roundResultItems;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final catCost = _getCatCost(item.catName);
          final isWin = item.winStatus == 'win';
          final cardColor = isWin
              ? const Color.fromARGB(255, 243, 63, 9)
              : Colors.grey.shade100;

          final isRevealed = _stampedIndices.contains(index);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StereoscopicContainer(
                baseColor: isRevealed
                    ? cardColor.withOpacity(0.9)
                    : Colors.grey.shade100,
                shadowColor: Colors.black12,
                borderRadius: 20,
                depth: 4,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        item.catName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildCatAvatar(
                      viewModel,
                      item.catName,
                      size: isSmallScreen ? 56 : 80,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$catCost 🐟',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isRevealed)
                      _buildCapsuleLabel(
                        item.winStatus == 'win'
                            ? 'GET!'
                            : (item.winStatus == 'lose' ? 'LOST..' : 'DRAW'),
                        color: item.winStatus == 'win'
                            ? const Color.fromARGB(255, 243, 63, 9)
                            : (item.winStatus == 'lose'
                                ? Colors.blue
                                : Colors.grey),
                        isSmallScreen: isSmallScreen,
                      )
                    else
                      const SizedBox(height: 24),
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
    int val1,
    ItemType? item1,
    String name2,
    int val2,
    ItemType? item2,
    bool isSmallScreen,
    bool startCounting,
    int cardIndex,
    bool isCounting,
    bool isRevealed,
  ) {
    final maxTarget = val1 > val2 ? val1 : val2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4D331F).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildStatRow(
            name1,
            val1,
            item1,
            isSmallScreen,
            startCounting,
            cardIndex,
            isCounting,
            isRevealed,
            maxTarget,
          ),
          Divider(height: isSmallScreen ? 8 : 12, color: Colors.black12),
          _buildStatRow(
            name2,
            val2,
            item2,
            isSmallScreen,
            startCounting,
            cardIndex,
            isCounting,
            isRevealed,
            maxTarget,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    int target,
    ItemType? item,
    bool isSmallScreen,
    bool start,
    int index,
    bool counting,
    bool revealed,
    int max,
  ) {
    final hasItem = item != null && item != ItemType.unknown;
    final showItem = _revealedItemIndices.contains(index) && hasItem;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: isSmallScreen ? 50 : 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4D331F),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showItem) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD54F).withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      _buildSmallItemIcon(item, size: isSmallScreen ? 20 : 28),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: start ? target.toDouble() : 0,
                  ),
                  duration: Duration(milliseconds: 800 + (target * 800)),
                  builder: (context, val, child) {
                    final bool isStillCounting =
                        val < target.toDouble() && start;
                    return Transform.scale(
                      scale: isStillCounting ? 1.3 : 1.0,
                      child: _buildFishWithNumber(
                        val.toInt().toString(),
                        size: isSmallScreen ? 32 : 40,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildCatAvatar(
    TutorialViewModel viewModel,
    String catName, {
    required double size,
  }) {
    final imagePath = viewModel.getCatImagePath(catName);
    return imagePath != null
        ? Image.asset(imagePath, width: size, height: size, fit: BoxFit.contain)
        : Icon(Icons.pets, size: size, color: Colors.grey);
  }

  Widget _buildCapsuleLabel(
    String text, {
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
    );
  }

  int _getCatCost(String name) {
    if (name.contains('しろ')) return 3;
    if (name.contains('くろ')) return 2;
    return 1;
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  _StripePainter({required this.color, required this.stripeWidth});
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
