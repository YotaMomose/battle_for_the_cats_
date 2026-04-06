import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/item.dart';
import '../game_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';

/// ラウンド結果画面
class RoundResultView extends StatefulWidget {
  final GameRoom room;

  const RoundResultView({super.key, required this.room});

  @override
  State<RoundResultView> createState() => _RoundResultViewState();
}

class _RoundResultViewState extends State<RoundResultView> {
  int _step = 0; // 0:初期, 1:左カウント, 2:左開示, 3:中カウント, 4:中開示, 5:右カウント, 6:右開示
  Set<int> _revealedItemIndices = {}; // 各カードのアイテムが表示されたかどうかを管理
  Set<int> _revealedMultiplierIndices = {}; // またたびの「x2」が表示されたかどうかを管理
  Set<int> _blownAwayIndices = {}; // びっくりホーンで吹き飛んだかどうかを管理
  Timer? _revealTimer;
  Timer? _itemTimer; // アイテム表示用のセカンドタイマー

  @override
  void initState() {
    super.initState();
    _startRevealAnimation();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _itemTimer?.cancel();
    super.dispose();
  }

  void _startRevealAnimation() {
    // 最初のカードのカウントアップを開始する
    _playNextSequence();
  }

  void _playNextSequence() {
    _revealTimer?.cancel();
    _itemTimer?.cancel();
    if (!mounted || _step >= 7) return;

    final viewModel = context.read<GameScreenViewModel>();

    // step 6 (3枚目の判定が終わった後) の分岐はそのまま
    if (_step == 6 && viewModel.finalWinner != null) {
      viewModel.nextTurn();
      return;
    }

    if (_step % 2 == 0) {
      final index = (_step) ~/ 2;
      final displayItems = viewModel.lastRoundDisplayItems;
      int maxBetForThisCard = 0;
      if (index < displayItems.length) {
        final item = displayItems[index];
        final val1 = item.myBet;
        final val2 = item.opponentBet;
        maxBetForThisCard = val1 > val2 ? val1 : val2;
      }

      // 第1段階: カウントアップ終了まで待つ
      final animationDuration = maxBetForThisCard * 800;
      final countWait = 800 + animationDuration;

      setState(() {
        _step++; // カウント開始
      });

      _revealTimer = Timer(Duration(milliseconds: countWait), () {
        if (mounted) {
          // 第2段階: アイテムをぽんっと出す
          setState(() {
            _revealedItemIndices.add(index);
          });

          // またたびがある場合、少し遅れて ×2 を表示 (500ms後)
          final items = viewModel.lastRoundDisplayItems;
          if (index < items.length) {
            final item = items[index];
            if (item.myItem == ItemType.matatabi ||
                item.opponentItem == ItemType.matatabi) {
              Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _revealedMultiplierIndices.add(index);
                  });
                }
              });
            }

            // びっくりホーンがある場合、少し遅れて魚を吹き飛ばす (300ms後)
            if (item.myItem == ItemType.surpriseHorn ||
                item.opponentItem == ItemType.surpriseHorn) {
              Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    _blownAwayIndices.add(index);
                  });
                }
              });
            }
          }

          // 第3段階: 1秒後に判定スタンプを出す
          _itemTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _step++; // 偶数になる(判定確定)
                SeService().play('button_buni.mp3');
              });

              // 3枚目(Step 6)の判定後の自動遷移ロジックはここ
              if (_step == 6 && viewModel.finalWinner != null) {
                Timer(const Duration(milliseconds: 1000), () {
                  if (mounted) viewModel.nextTurn();
                });
              }
            }
          });
        }
      });
    } else {
      // 演出途中（奇数ステップ）で押された場合、即座に現在のカードを確定させ、
      // まだ次のカードがあるならそのまま次のカードの演出を開始する
      final index = (_step - 1) ~/ 2;
      final items = viewModel.lastRoundDisplayItems;

      setState(() {
        _revealedItemIndices.add(index);

        // 実際にアイテムがある場合のみフラグを立てる
        if (index < items.length) {
          final item = items[index];
          if (item.myItem == ItemType.matatabi ||
              item.opponentItem == ItemType.matatabi) {
            _revealedMultiplierIndices.add(index);
          }
          if (item.myItem == ItemType.surpriseHorn ||
              item.opponentItem == ItemType.surpriseHorn) {
            _blownAwayIndices.add(index);
          }
        }

        _step++; // 一旦「確定」状態にする（偶数になる）
        SeService().play('button_buni.mp3');
      });

      // まだ3枚目（Step 6）に達していない、かつ次のカードがあるなら即座に次へ進める
      // 判定スタンプ（WinningStampなど）を確認できるよう、少し長めのディレイ(800ms)を置く
      if (_step < 6) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _playNextSequence();
        });
      } else if (_step == 6 && viewModel.finalWinner != null) {
        // 最終勝者が決まっている場合は結果画面へ
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) viewModel.nextTurn();
        });
      }
    }
  }

  void _skipAllAnimation() {
    if (mounted) {
      setState(() {
        _step = 7;
        _revealedItemIndices = {0, 1, 2}; // すべて表示済みに
        _revealedMultiplierIndices = {0, 1, 2};
        _revealTimer?.cancel();
        _itemTimer?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final displayTurn = viewModel.displayTurn;
    final isConfirmed = viewModel.isRoundResultConfirmed;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    // 犬の効果通知がある場合、ビルド後にポップアップを表示（アニメーション終了後）
    if (_step >= 7 && viewModel.dogEffectNotifications.isNotEmpty) {
      final notifications = List<DogEffectNotification>.from(
        viewModel.dogEffectNotifications,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 表示直前にクリアすることで、再ビルドによる重複表示を防ぐ
        viewModel.clearDogNotifications();
        _showDogEffectPopup(context, notifications, isSmallScreen, viewModel);
      });
    }

    // アイテム復活が1つの場合は自動復活（ポップアップ表示）（アニメーション終了後）
    if (_step >= 7 &&
        viewModel.canReviveItem &&
        viewModel.revivableItems.length == 1) {
      final item = viewModel.revivableItems.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 先に復活処理を実行（再表示を防ぐ）
        viewModel.reviveItem(item);
        // ポップアップを表示
        _showAutoRevivePopup(context, item, isSmallScreen);
      });
    }

    final canRevive = viewModel.canReviveItem;
    final canChase = viewModel.canChaseAway;
    final shouldScroll = canRevive || canChase;

    Widget mainContent = Column(
      children: [
        // ヘッダー
        _buildHeader(displayTurn, isSmallScreen),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: shouldScroll ? (isSmallScreen ? 12 : 20) : 8,
          ),
          child: Column(
            children: [
              if (_step < 7) ...[
                // ステップ数から現在判定中のカードインデックスを計算
                // 1,2 -> 0番目, 3,4 -> 1番目, 5,6 -> 2番目
                ClipRect(
                  // スライドが画面外に出ないように領域を制限
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    // 横にスライドしながら切り替わる
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final isEntering =
                              (child.key as ValueKey<int>).value ==
                              (_step == 0 ? 0 : (_step - 1) ~/ 2);

                          // 入る時は右から(1,0)、出る時は左へ(-1,0)
                          final offsetAnimation = Tween<Offset>(
                            begin: isEntering
                                ? const Offset(1.2, 0.0)
                                : const Offset(-1.2, 0.0),
                            end: Offset.zero,
                          ).animate(animation);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                    child: Container(
                      key: ValueKey<int>(_step == 0 ? 0 : (_step - 1) ~/ 2),
                      child: _buildSingleLargeCard(
                        context,
                        viewModel,
                        isSmallScreen,
                        _step == 0 ? 0 : (_step - 1) ~/ 2,
                        _step,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: shouldScroll ? (isSmallScreen ? 16 : 32) : 8),
              ] else ...[
                // 累計結果
                _buildCumulativeResult(context, viewModel, isSmallScreen),
                SizedBox(height: shouldScroll ? (isSmallScreen ? 16 : 32) : 8),

                // 猫カードの横並び一覧
                _buildCatCardRow(context, viewModel, isSmallScreen, _step),
                SizedBox(height: shouldScroll ? (isSmallScreen ? 12 : 24) : 8),
              ],

              // 特殊効果UI (復活/追い出し) - すべての結果が出た後に表示
              if (_step >= 7 &&
                  canRevive &&
                  viewModel.revivableItems.length > 1) ...[
                _buildReviveSection(context, viewModel, isSmallScreen),
                SizedBox(height: isSmallScreen ? 12 : 20),
              ],
              if (_step >= 7 && canChase) ...[
                _buildChaseAwaySection(context, viewModel, isSmallScreen),
                SizedBox(height: isSmallScreen ? 12 : 20),
              ],

              // アニメーション中のみアクションボタンを表示
              if (_step < 7)
                _buildRevealActionButtons(isSmallScreen)
              else
                _buildNextButton(viewModel, isConfirmed, isSmallScreen),

              if (shouldScroll)
                const SizedBox(height: 120)
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            // 特殊効果がない時はスクロールを極力発生させない
            physics: shouldScroll
                ? const BouncingScrollPhysics()
                : const ClampingScrollPhysics(),
            child: mainContent,
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

  void _showAutoRevivePopup(
    BuildContext context,
    ItemType item,
    bool isSmallScreen,
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
              shadowColor: Colors.purple.shade200,
              borderRadius: 24,
              depth: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/shop.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'アイテム屋の効果発動！',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.imagePath != null)
                          Image.asset(
                            item.imagePath!,
                            width: isSmallScreen ? 40 : 50,
                            height: isSmallScreen ? 40 : 50,
                            fit: BoxFit.contain,
                          )
                        else
                          const Icon(Icons.refresh, color: Colors.purple),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${item.displayName} 復活！',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4D331F),
                            ),
                          ),
                        ),
                      ],
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
                  size: isSmallScreen ? 16 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ターン $turn けっか！',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4D331F),
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              style: TextStyle(
                color: Color(0xFF4D331F),
                fontWeight: FontWeight.bold,
              ),
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
          if (viewModel.availableTargetsForDog.isNotEmpty) ...[
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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
            // カードリスト部分を一定の幅でスクロール可能にする
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isSmallScreen ? 160 : 220),
              child: _buildWonCardsIconListSmall(cards, isSmallScreen),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleLargeCard(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
    int index,
    int step,
  ) {
    if (index >= viewModel.lastRoundDisplayItems.length)
      return const SizedBox();

    final item = viewModel.lastRoundDisplayItems[index];
    final isCounting = step == index * 2 + 1;
    final isRevealed = step >= index * 2 + 2;
    // シングル表示中は常に true 扱いにして表を表示しつつ、Fishの数だけを数える
    final showStats = isCounting || isRevealed;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSmallScreen ? 240 : 320),
        child: AnimatedScale(
          // カード自体のサイズは変えない
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: StereoscopicContainer(
            baseColor: isRevealed
                ? item.cardColor.withOpacity(0.9)
                : Colors.grey.shade100,
            shadowColor: Colors.black12,
            borderRadius: 24,
            depth: isCounting ? 12 : 6,
            showDots: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // カード名（大きく）
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
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
                      fontSize: isSmallScreen ? 18 : 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4D331F),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 20),
                // 猫アバター（大きく）と勝敗の全体スタンプ
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildCatAvatar(item, size: isSmallScreen ? 100 : 160),
                    // ドン！と表示される巨大な勝敗テキスト（スタンプ風）
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
                            border: Border.all(
                              color: item.winnerTextColor,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.winnerTextColor.withOpacity(0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            item.winnerLabel,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 40 : 56,
                              fontWeight: FontWeight.w900,
                              color: item.winnerTextColor,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 必要コストの表示（猫アバターの下）
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
                        '${item.catCost}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4D331F),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🐟', style: TextStyle(fontSize: 14)),
                      // またたびの演出：表示フラグが立っているか、判定完了後なら表示
                      if (_revealedMultiplierIndices.contains(index) ||
                          isRevealed)
                        if (item.myItem == ItemType.matatabi ||
                            item.opponentItem == ItemType.matatabi)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Text(
                                  ' ×2',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 詳細スコアテーブルとの間隔
                SizedBox(height: isSmallScreen ? 16 : 24),

                // 詳細スコアテーブル（アイテム画像は常に表示）
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSmallStatsTable(
                    viewModel.myDisplayName,
                    item.myBet,
                    item.myItem,
                    viewModel.opponentDisplayName,
                    item.opponentBet,
                    item.opponentItem,
                    isSmallScreen,
                    showStats,
                    index,
                    isCounting,
                    isRevealed,
                    isRevealed, // 判定確定時(偶数ステップ)はカウントをスキップして即座に表示
                    true, // canBlowAway
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatCardRow(
    BuildContext context,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
    int step,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(viewModel.lastRoundDisplayItems.length, (
          index,
        ) {
          final item = viewModel.lastRoundDisplayItems[index];
          final isCounting = step == index * 2 + 1;
          final isRevealed = step >= 7 || step >= index * 2 + 2;
          final showStats = isCounting || isRevealed;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedScale(
                scale: isCounting ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Opacity(
                  opacity: (step < 7 && !showStats) ? 0.7 : 1.0,
                  child: StereoscopicContainer(
                    baseColor: isRevealed
                        ? item.cardColor.withOpacity(0.9)
                        : Colors.grey.shade100,
                    shadowColor: Colors.black12,
                    borderRadius: 20,
                    depth: isCounting ? 8 : 4,
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
                        SizedBox(height: isSmallScreen ? 6 : 10),
                        // 猫アバター
                        _buildCatAvatar(item, size: isSmallScreen ? 56 : 80),

                        const SizedBox(height: 4),
                        // 必要コストの表示（猫アバターの下）
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4D331F),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.catCost}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4D331F),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '🐟',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
                              if (_revealedMultiplierIndices.contains(index) ||
                                  isRevealed)
                                if (item.myItem == ItemType.matatabi ||
                                    item.opponentItem == ItemType.matatabi)
                                  Text(
                                    '×2',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // 結果ラベル
                        AnimatedOpacity(
                          opacity: isRevealed ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _buildCapsuleLabel(
                            isRevealed ? item.winnerLabel : '?',
                            color: isRevealed ? item.cardColor : Colors.grey,
                            textColor: isRevealed
                                ? item.winnerTextColor
                                : Colors.white,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        // 詳細スコアテーブル
                        AnimatedOpacity(
                          opacity: showStats ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _buildSmallStatsTable(
                            viewModel.myDisplayName,
                            item.myBet,
                            item.myItem,
                            viewModel.opponentDisplayName,
                            item.opponentBet,
                            item.opponentItem,
                            isSmallScreen,
                            showStats,
                            index,
                            isCounting,
                            isRevealed,
                            true, // isImmediate
                            false, // canBlowAway: 一覧時は吹き飛ばさない
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRevealActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        // 次へボタン
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 50 : 72,
          child: StereoscopicButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              _playNextSequence();
            },
            baseColor: Colors.orange,
            shadowColor: Colors.orange.shade700,
            borderRadius: 36,
            depth: 8,
            child: Center(
              child: Text(
                '次へ ▶',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 全部スキップボタン
        SizedBox(
          width: 180, // スキップボタンは少し小さく中央に
          height: isSmallScreen ? 36 : 48,
          child: StereoscopicButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              _skipAllAnimation();
            },
            baseColor: Colors.grey.shade300,
            shadowColor: Colors.grey.shade500,
            borderRadius: 24,
            depth: 4,
            child: Center(
              child: Text(
                '全部スキップ ⏩',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),
      ],
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
    bool isImmediate,
    bool canBlowAway,
  ) {
    // 両プレイヤーの最大値を計算（同期カウントアップ用）
    final maxTargetValue = [val1, val2].reduce((a, b) => a > b ? a : b);

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
          _buildStatRow(
            name1,
            val1,
            item1,
            isSmallScreen,
            startCounting,
            cardIndex,
            isCounting,
            isRevealed,
            isImmediate,
            maxTargetValue,
            canBlowAway,
          ),
          Divider(
            height: isSmallScreen ? 8 : 12,
            thickness: 1,
            color: const Color(0xFF4D331F).withOpacity(0.2),
          ),
          _buildStatRow(
            name2,
            val2,
            item2,
            isSmallScreen,
            startCounting,
            cardIndex,
            isCounting,
            isRevealed,
            isImmediate,
            maxTargetValue,
            canBlowAway,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    int targetValue,
    ItemType? item,
    bool isSmallScreen,
    bool startCounting,
    int cardIndex,
    bool isCounting,
    bool isRevealed,
    bool isImmediate,
    int maxTargetValue,
    bool canBlowAway,
  ) {
    final hasItem = item != null && item != ItemType.unknown;

    // カウントアップ中は大きく、それ以外は通常サイズ
    final fishSize = isCounting
        ? (isSmallScreen ? 40.0 : 52.0) // 1.2倍程度の大きさに緩和
        : (hasItem
              ? (isSmallScreen ? 24.0 : 36.0)
              : (isSmallScreen ? 34.0 : 48.0));

    final itemIconSize = isSmallScreen ? 14.0 : 20.0;
    // 表の高さがずれないように高さを固定する
    final rowHeight = isSmallScreen ? 55.0 : 75.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        height: rowHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1段目: プレイヤー名
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4D331F),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 2段目: アイテムと魚（カウント中のみ拡大）
            AnimatedScale(
              scale: (isCounting && !isImmediate) ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasItem &&
                      (isRevealed ||
                          _revealedItemIndices.contains(cardIndex))) ...[
                    // アイテムの登場を華やかにするためのスタック
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 背後の光彩演出（Glow Aura）
                        AnimatedOpacity(
                          opacity:
                              (isRevealed ||
                                  _revealedItemIndices.contains(cardIndex))
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            width: itemIconSize * 1.5,
                            height: itemIconSize * 1.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD54F,
                                  ).withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 弾むようなポップアップ（Elastic Pop）
                        AnimatedScale(
                          scale:
                              (isRevealed ||
                                  _revealedItemIndices.contains(cardIndex))
                              ? 1.0
                              : 0.0,
                          duration: const Duration(
                            milliseconds: 1000,
                          ), // 弾みの余韻のために長めに設定
                          curve: Curves.elasticOut,
                          child: AnimatedOpacity(
                            opacity:
                                (isRevealed ||
                                    _revealedItemIndices.contains(cardIndex))
                                ? 1.0
                                : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: _buildSmallItemIcon(
                              item,
                              size: itemIconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ],
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end:
                          (canBlowAway && _blownAwayIndices.contains(cardIndex))
                          ? 1.0
                          : 0.0,
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCirc,
                    builder: (context, blowValue, child) {
                      if (blowValue == 0) return child!;

                      final int numFish = targetValue.clamp(1, 8);
                      final opacity = (1.0 - blowValue).clamp(0.0, 1.0);

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // 元の数値（早めにフェードアウト）
                          Opacity(
                            opacity: (1.0 - blowValue * 2).clamp(0.0, 1.0),
                            child: child,
                          ),
                          // 四方八方に散る魚たち
                          for (int i = 0; i < numFish; i++)
                            Builder(
                              builder: (context) {
                                final double angle =
                                    (2 * 3.14159 * i / numFish) - (3.14159 / 2);
                                // 吹き飛ぶ距離
                                final double dist = blowValue * 120;
                                final double simpleDx =
                                    math.cos(angle) * dist * 1.8;
                                final double simpleDy =
                                    math.sin(angle) * dist * 1.8;

                                return Transform.translate(
                                  offset: Offset(simpleDx, simpleDy),
                                  child: Transform.rotate(
                                    angle: angle + (3.14159 / 2),
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Text(
                                        '🐟',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(
                        'bet_anim_${cardIndex}_${label}_$isImmediate',
                      ),
                      tween: Tween<double>(
                        begin: -1.0, // スライド完了まで 0 を維持するための遊び
                        // maxTargetValueまでアニメーションさせ、表示時に自身の目標値で止める
                        end: startCounting ? maxTargetValue.toDouble() : 0,
                      ),
                      duration: isImmediate
                          ? Duration.zero
                          : Duration(
                              milliseconds: 800 + (maxTargetValue * 800),
                            ),
                      builder: (context, val, child) {
                        // マイナスの間は 0 にクランプ
                        int displayValue = val.toInt();
                        if (displayValue < 0) displayValue = 0;
                        // 自分の本来の目標値でさらにクランプ
                        if (displayValue > targetValue)
                          displayValue = targetValue;

                        return _buildFishWithNumber(
                          displayValue.toString(),
                          size: fishSize,
                        );
                      },
                    ),
                  ),
                ],
              ),
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

  Widget _buildNextButton(
    GameScreenViewModel viewModel,
    bool isConfirmed,
    bool isSmallScreen,
  ) {
    final canChase = viewModel.canChaseAway;
    final canRevive = viewModel.canReviveItem;
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 50 : 72,
      child: StereoscopicButton(
        onPressed:
            (isConfirmed ||
                (canChase && viewModel.availableTargetsForDog.isNotEmpty) ||
                canRevive)
            ? null
            : () {
                SeService().play('button_buni.mp3');
                if (canChase && viewModel.availableTargetsForDog.isEmpty) {
                  viewModel.chaseAwayCard(null);
                } else {
                  viewModel.nextTurn();
                }
              },
        baseColor: const Color(0xFFF57C00),
        shadowColor: const Color(0xFFBF360C),
        borderRadius: 36,
        depth: 8,
        child: Center(
          child: Builder(
            builder: (context) {
              final String labelText;
              bool showDots = false;

              if (canChase) {
                if (viewModel.availableTargetsForDog.isEmpty) {
                  labelText = '次へ進む';
                } else {
                  labelText = 'キャラ選択待ち';
                }
              } else if (canRevive) {
                labelText = isSmallScreen ? 'アイテムを選択' : 'アイテムを選択してください';
              } else if (isConfirmed) {
                labelText = '確認待ち';
                showDots = true;
              } else {
                labelText = isSmallScreen ? '次へ ▶' : '次のターンへ ▶';
              }

              final textStyle = TextStyle(
                fontSize: (canChase || canRevive || showDots)
                    ? (isSmallScreen ? 16 : 24)
                    : (isSmallScreen ? 20 : 36),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              );

              if (showDots) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(labelText, style: textStyle),
                    AnimatedWaitingDots(style: textStyle),
                  ],
                );
              }
              return Text(labelText, style: textStyle);
            },
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
    double fontSizeScale = 1.0,
  }) {
    final fontSize = (isSmallScreen ? 12.0 : 18.0) * fontSizeScale;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * fontSizeScale,
        vertical: 4 * fontSizeScale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: _buildCatAvatarFromCard(card, size: isSmallScreen ? 24 : 32),
          );
        }).toList(),
      ),
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
