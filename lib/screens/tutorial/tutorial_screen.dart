import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../models/cards/game_card.dart';
import '../../models/cat_inventory.dart';
import '../../services/se_service.dart';
import '../../widgets/stereoscopic_ui.dart';
import '../../widgets/tutorial/tutorial_dialogue_widget.dart';
import 'tutorial_view_model.dart';
import '../home/home_screen_view_model.dart';
import 'views/tutorial_round_result_view.dart';

final GlobalKey _myHandFishKey = GlobalKey();
final GlobalKey _myItemsKey = GlobalKey();
final Map<ItemType, GlobalKey> _itemTypeKeys = {
  ItemType.catTeaser: GlobalKey(),
  ItemType.surpriseHorn: GlobalKey(),
  ItemType.matatabi: GlobalKey(),
};

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool _isDialogueDismissed = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TutorialViewModel>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFD5), // バトル画面と同じ背景色
      body: Stack(
        children: [
          // 背景のドット
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(
                dotColor: const Color(0xFFEBD9B4),
                spacing: 12,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ターン情報 (最上部)
                _buildTurnHeader(isSmallScreen),

                // 対戦相手セクション
                Expanded(
                  flex: isSmallScreen ? 4 : 4,
                  child: _buildPlayerSection(
                    context,
                    isOpponent: true,
                    displayName: viewModel.opponentDisplayName,
                    iconEmoji: viewModel.opponentIconEmoji,
                    fishCount: viewModel.playerData.opponentFishCount,
                    inventory: viewModel.playerData.opponentCatsWon,
                    viewModel: viewModel,
                    statusLabel: viewModel.opponentReadyStatusLabel,
                    statusColor: viewModel.opponentReadyStatusColor,
                    isSmallScreen: isSmallScreen,
                  ),
                ),

                // 3匹の猫カードとお皿のエリア (中央)
                Expanded(
                  flex: isSmallScreen ? 6 : 5,
                  child: viewModel.currentStep >= 9
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '獲得フェーズ終了',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4D331F),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final catIndex = index.toString();
                            final cards =
                                viewModel.room.currentRound?.toList() ?? [];
                            if (cards.isEmpty || index >= cards.length) {
                              return const Expanded(child: SizedBox());
                            }

                            final card = cards[index];
                            final currentBet = viewModel.bets[catIndex] ?? 0;
                            final placedItem = viewModel.getPlacedItem(
                              catIndex,
                            );

                            // ステップに応じたハイライト
                            bool isHighlighted = false;
                            if (viewModel.currentStep == 3 && index == 0)
                              isHighlighted = true;
                            if (viewModel.currentStep == 5 && index == 1)
                              isHighlighted = true;
                            if (viewModel.currentStep == 8 && index == 2)
                              isHighlighted = true;

                            return Expanded(
                              child: DragTarget<Object>(
                                onWillAccept: (data) => !viewModel.hasPlacedBet,
                                onAccept: (data) {
                                  _handleDrop(
                                    viewModel,
                                    catIndex,
                                    data,
                                    currentBet,
                                  );
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                      final isTarget = candidateData.isNotEmpty;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                          horizontal: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ).withOpacity(isTarget ? 0.9 : 0.7),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isHighlighted
                                                ? Colors.yellow
                                                : (isTarget
                                                      ? Colors.yellow
                                                            .withOpacity(0.5)
                                                      : Colors.grey.shade300),
                                            width: isHighlighted
                                                ? 4
                                                : (isTarget ? 2 : 1),
                                          ),
                                          boxShadow: isHighlighted
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.yellow
                                                        .withOpacity(0.5),
                                                    blurRadius: 10,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  height: isSmallScreen
                                                      ? 110
                                                      : 150,
                                                  child: _buildCatCard(
                                                    viewModel,
                                                    card,
                                                    isSmallScreen,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                _buildDishArea(
                                                  context,
                                                  viewModel: viewModel,
                                                  catIndex: catIndex,
                                                  currentBet: currentBet,
                                                  placedItem: placedItem,
                                                  isSmallScreen: isSmallScreen,
                                                  isTarget: isTarget,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            );
                          }),
                        ),
                ),

                // 自分セクション
                Expanded(
                  flex: isSmallScreen ? 4 : 4,
                  child: _buildPlayerSection(
                    context,
                    isOpponent: false,
                    displayName: viewModel.myDisplayName,
                    iconEmoji: viewModel.myIconEmoji,
                    fishCount: viewModel.playerData.myFishCount,
                    inventory: viewModel.playerData.myCatsWon,
                    viewModel: viewModel,
                    isReady: viewModel.isMyReady,
                    isSmallScreen: isSmallScreen,
                  ),
                ),

                // アクションボタン
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildActionArea(viewModel, isSmallScreen),
                ),
              ],
            ),
          ),

          // 判定演出画面
          if (viewModel.isResultPhase) const TutorialRoundResultView(),

          // チュートリアル・ダイアログ (上部)
          if (!_isDialogueDismissed)
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              child: SafeArea(
                child: TutorialDialogueWidget(
                  message: viewModel.currentMessage,
                  onNext: () async {
                    if (viewModel.currentStep == 19) {
                      setState(() {
                        _isDialogueDismissed = true;
                      });
                      final homeVm = context.read<HomeScreenViewModel>();
                      await homeVm.completeTutorial();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      viewModel.nextStep();
                    }
                  },
                  isLast: viewModel.currentStep == 19,
                  isEnabled:
                      viewModel.canProgress || viewModel.currentStep == 19,
                  characterImagePath: 'assets/images/kuroneko.png', // 長老ねこ
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnHeader(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          const Icon(Icons.star, color: Color(0xFFFF9800), size: 16),
          const SizedBox(width: 8),
          Text(
            'チュートリアル',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, color: Color(0xFFFF9800), size: 16),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(
    BuildContext context, {
    required bool isOpponent,
    required String displayName,
    required String iconEmoji,
    required int fishCount,
    required CatInventory inventory,
    required TutorialViewModel viewModel,
    String? statusLabel,
    Color? statusColor,
    bool isReady = false,
    bool isSmallScreen = false,
  }) {
    final avatarSize = isSmallScreen ? 45.0 : 60.0;
    final fishIconSize = isSmallScreen ? 36.0 : 48.0;
    final bgColor = isOpponent ? Colors.red.shade50 : Colors.blue.shade50;

    final iconAndCardsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // アイコン
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: isOpponent ? Colors.red.shade100 : Colors.blue.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              iconEmoji,
              style: TextStyle(fontSize: avatarSize * 0.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 名前と獲得猫
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4D331F),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: isSmallScreen ? 34 : 45,
              width: 150,
              child: _buildWonCatsList(
                inventory,
                viewModel,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
      ],
    );

    final fishAndItemsRow = SizedBox(
      width: isSmallScreen ? 280 : 380,
      child: Row(
        children: [
          const SizedBox(width: 4),
          // 魚の数
          if (!isOpponent)
            _buildMyFishDraggableArea(fishCount, viewModel, isSmallScreen)
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: isSmallScreen ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: _buildFishWithNumber('$fishCount', size: fishIconSize),
            ),
          SizedBox(width: isSmallScreen ? 4 : 16),
          // 所持アイテム一覧
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: isSmallScreen ? 1 : 4,
              ),
              decoration: BoxDecoration(
                color: isOpponent ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOpponent
                      ? Colors.red.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSmallScreen)
                    const Text(
                      '所持アイテム',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  isOpponent
                      ? _buildOpponentItems(
                          viewModel,
                          iconSize: isSmallScreen ? 22 : 32,
                        )
                      : _buildMyItemsList(
                          viewModel,
                          isSmallScreen: isSmallScreen,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final content = Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ドット柄背景
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(
                dotColor: Colors.white.withOpacity(0.4),
                spacing: 12,
              ),
            ),
          ),
          // コンテンツ
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: isSmallScreen ? 1.0 : 8.0,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOpponent) ...[
                      iconAndCardsRow,
                      const SizedBox(height: 6),
                      fishAndItemsRow,
                    ] else ...[
                      fishAndItemsRow,
                      const SizedBox(height: 6),
                      iconAndCardsRow,
                    ],
                    if (statusLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildStatusBadge(
                          statusLabel,
                          statusColor ?? Colors.grey,
                          isSmallScreen,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!isOpponent) {
      return DragTarget<String>(
        onWillAccept: (data) =>
            data != null &&
            (data.startsWith('fish_from_') || data.startsWith('item_from_')),
        onAccept: (data) {
          if (data.startsWith('fish_from_')) {
            final catIndex = data.replaceFirst('fish_from_', '');
            if (catIndex != 'hand') {
              final currentBet = viewModel.bets[catIndex] ?? 0;
              viewModel.updateBet(catIndex, currentBet - 1);
            }
          } else if (data.startsWith('item_from_')) {
            final catIndex = data.replaceFirst('item_from_', '');
            viewModel.updateItemPlacement(catIndex, null);
          }
        },
        builder: (context, candidateData, rejectedData) => content,
      );
    }

    return content;
  }

  Widget _buildStatusBadge(String label, Color color, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFBF5F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4D331F), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4D331F), offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.endsWith('...') ? label.replaceFirst('...', '') : label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (label.endsWith('...'))
            AnimatedWaitingDots(
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatCard(
    TutorialViewModel viewModel,
    GameCard card,
    bool isSmallScreen,
  ) {
    final avatarSize = isSmallScreen ? 55.0 : 90.0;
    return Container(
      width: isSmallScreen ? 80 : 110,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StereoscopicContainer(
            baseColor: const Color(0xFFFFBF5F),
            shadowColor: const Color(0xFF4D331F),
            borderRadius: 20,
            depth: 2,
            showHighlight: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                card.displayName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 11,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
              ),
            ),
          ),
          _buildCatAvatar(viewModel, card.displayName, size: avatarSize),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 1,
            children: List.generate(
              card.baseCost,
              (_) => Text(
                '🐟',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatAvatar(
    TutorialViewModel viewModel,
    String catName, {
    double size = 64,
  }) {
    final imagePath = viewModel.getCatImagePath(catName);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(
      viewModel.getCatIconData(catName),
      size: size,
      color: viewModel.getCatIconColor(catName),
    );
  }

  Widget _buildDishArea(
    BuildContext context, {
    required TutorialViewModel viewModel,
    required String catIndex,
    required int currentBet,
    required ItemType? placedItem,
    bool isSmallScreen = false,
    bool isTarget = false,
  }) {
    final dishWidth = isSmallScreen ? 60.0 : 100.0;
    final fishSize = isSmallScreen ? 35.0 : 50.0;
    final dishKey = GlobalObjectKey('t_dish_$catIndex');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: isTarget
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(
                'assets/images/dish.png',
                width: dishWidth,
                fit: BoxFit.contain,
              ),
            ),
            Transform.translate(
              offset: Offset(0, isSmallScreen ? -10 : -15),
              child: currentBet > 0 && !viewModel.hasPlacedBet
                  ? Draggable<String>(
                      data: 'fish_from_$catIndex',
                      feedback: Material(
                        color: Colors.transparent,
                        child: Text(
                          '🐟',
                          style: TextStyle(fontSize: fishSize * 1.3),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildFishWithNumber(
                          '$currentBet',
                          size: fishSize,
                        ),
                      ),
                      child: GestureDetector(
                        key: dishKey,
                        onTap: () {
                          final box =
                              dishKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box != null) {
                            _flyFishAnimation(
                              context,
                              box.localToGlobal(box.size.center(Offset.zero)),
                              '1',
                              size: fishSize,
                            );
                          }
                          viewModel.updateBet(catIndex, -1);
                        },
                        child: _buildFishWithNumber(
                          '$currentBet',
                          size: fishSize,
                        ),
                      ),
                    )
                  : _buildFishWithNumber('$currentBet', size: fishSize),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildItemSlot(
          catIndex,
          placedItem,
          viewModel,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildItemSlot(
    String catIndex,
    ItemType? placedItem,
    TutorialViewModel viewModel, {
    bool isSmallScreen = false,
  }) {
    final itemIconSize = isSmallScreen ? 24.0 : 36.0;
    final color = placedItem != null ? _getItemColor(placedItem) : Colors.white;

    return StereoscopicContainer(
      baseColor: placedItem != null ? color : Colors.white.withOpacity(0.5),
      shadowColor: placedItem != null
          ? color.withOpacity(0.8)
          : Colors.grey.shade300,
      borderRadius: 8,
      depth: 4,
      showStripes: placedItem != null,
      showDots: placedItem == null,
      child: SizedBox(
        width: itemIconSize + 16,
        height: itemIconSize + 16,
        child: Center(
          child: placedItem != null
              ? Draggable<String>(
                  data: 'item_from_$catIndex',
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildItemImage(
                      placedItem,
                      size: itemIconSize * 1.2,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildItemImage(placedItem, size: itemIconSize),
                  ),
                  child: GestureDetector(
                    onTap: () => viewModel.updateItemPlacement(catIndex, null),
                    child: _buildItemImage(placedItem, size: itemIconSize),
                  ),
                )
              : Icon(
                  Icons.add,
                  color: Colors.grey.shade400,
                  size: isSmallScreen ? 14 : 18,
                ),
        ),
      ),
    );
  }

  Widget _buildMyFishDraggableArea(
    int totalFish,
    TutorialViewModel viewModel,
    bool isSmallScreen,
  ) {
    final remaining = totalFish - viewModel.totalBet;
    final fishSize = isSmallScreen ? 36.0 : 48.0;
    final canDrag = !viewModel.hasPlacedBet && remaining > 0;

    // ステップ3でハイライト
    final bool isHighlighted = viewModel.currentStep == 3;

    return Container(
      key: _myHandFishKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.yellow.withOpacity(0.3)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? Colors.yellow : Colors.blue.shade200,
          width: isHighlighted ? 3 : 1,
        ),
      ),
      child: canDrag
          ? Draggable<String>(
              data: 'fish_from_hand',
              feedback: Material(
                color: Colors.transparent,
                child: Text('🐟', style: TextStyle(fontSize: fishSize * 1.3)),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildFishWithNumber('$remaining', size: fishSize),
              ),
              child: _buildFishWithNumber('$remaining', size: fishSize),
            )
          : _buildFishWithNumber('$remaining', size: fishSize),
    );
  }

  Widget _buildMyItemsList(
    TutorialViewModel viewModel, {
    bool isSmallScreen = false,
  }) {
    return Row(
      key: _myItemsKey,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDraggableItem(
          ItemType.catTeaser,
          viewModel,
          isSmallScreen: isSmallScreen,
        ),
        _buildDraggableItem(
          ItemType.surpriseHorn,
          viewModel,
          isSmallScreen: isSmallScreen,
        ),
        _buildDraggableItem(
          ItemType.matatabi,
          viewModel,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildDraggableItem(
    ItemType type,
    TutorialViewModel viewModel, {
    bool isSmallScreen = false,
  }) {
    final count = viewModel.playerData.myInventory.count(type);
    bool isPlaced = false;
    for (int i = 0; i < 3; i++) {
      if (viewModel.getPlacedItem(i.toString()) == type) {
        isPlaced = true;
        break;
      }
    }
    final bool isUnavailable = count <= 0 || isPlaced;
    final itemSize = isSmallScreen ? 28.0 : 40.0;

    // ステップ7でねこじゃらしをハイライト
    final bool isHighlighted =
        viewModel.currentStep == 7 && type == ItemType.catTeaser;

    final content = _buildItemIcon(
      type,
      size: itemSize,
      isPlaced: isUnavailable,
      isHighlighted: isHighlighted,
    );

    return isUnavailable
        ? Opacity(opacity: 0.3, child: content)
        : Draggable<ItemType>(
            key: _itemTypeKeys[type],
            data: type,
            feedback: Material(
              color: Colors.transparent,
              child: _buildItemIcon(
                type,
                size: itemSize * 1.2,
                isFeedback: true,
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: content),
            child: content,
          );
  }

  Widget _buildItemIcon(
    ItemType type, {
    double size = 32,
    bool isPlaced = false,
    bool isFeedback = false,
    bool isHighlighted = false,
  }) {
    final color = _getItemColor(type);
    return StereoscopicContainer(
      baseColor: Colors.white,
      shadowColor: isHighlighted ? Colors.yellow : color.withOpacity(0.3),
      borderRadius: 12,
      depth: 4,
      showHighlight: true,
      child: Container(
        decoration: isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow, width: 3),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: _buildItemImage(type, size: size),
      ),
    );
  }

  Widget _buildOpponentItems(
    TutorialViewModel viewModel, {
    double iconSize = 32,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [ItemType.catTeaser, ItemType.surpriseHorn, ItemType.matatabi]
          .map(
            (type) => Opacity(
              opacity: 0.3,
              child: _buildItemIcon(type, size: iconSize, isPlaced: true),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionArea(TutorialViewModel viewModel, bool isSmallScreen) {
    if (viewModel.currentStep <= 7) return const SizedBox(height: 50);

    // ステップ9で確定ボタンをハイライト
    final bool isConfirmHighlighted = viewModel.currentStep == 9;
    // ステップ10でつりボタンをハイライト
    final bool isFishHighlighted = viewModel.currentStep == 10;

    if (viewModel.currentStep <= 9 && !viewModel.isMyRolled) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 50,
          child: StereoscopicButton(
            onPressed: viewModel.currentStep == 9 ? viewModel.placeBets : null,
            baseColor: isConfirmHighlighted
                ? Colors.yellow
                : (viewModel.hasPlacedBet ? Colors.grey : Colors.pink.shade400),
            shadowColor: isConfirmHighlighted
                ? Colors.yellow.shade800
                : (viewModel.hasPlacedBet
                      ? Colors.grey.shade700
                      : Colors.pink.shade900),
            borderRadius: 12,
            depth: 4,
            child: Center(
              child: Text(
                viewModel.confirmBetsButtonLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (viewModel.currentStep >= 18) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 50,
          child: StereoscopicButton(
            onPressed: viewModel.currentStep == 18 ? viewModel.rollDice : null,
            baseColor: isFishHighlighted
                ? Colors.yellow
                : (viewModel.isMyRolled
                      ? Colors.grey
                      : const Color(0xFFF06292)),
            shadowColor: isFishHighlighted
                ? Colors.yellow.shade800
                : (viewModel.isMyRolled
                      ? Colors.grey.shade700
                      : const Color(0xFFAD1457)),
            borderRadius: 12,
            depth: 4,
            child: Center(
              child: Text(
                viewModel.isMyRolled ? '振りました' : 'サイコロを振る',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 50);
  }

  Widget _buildWonCatsList(
    CatInventory inventory,
    TutorialViewModel viewModel, {
    bool isSmallScreen = false,
  }) {
    final cats = inventory.all;
    if (cats.isEmpty)
      return const Center(
        child: Text('なし', style: TextStyle(color: Colors.grey, fontSize: 10)),
      );
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _buildCatAvatar(
            viewModel,
            cat.name,
            size: isSmallScreen ? 24 : 36,
          ),
        );
      },
    );
  }

  void _handleDrop(
    TutorialViewModel viewModel,
    String catIndex,
    Object? data,
    int currentBet,
  ) {
    if (data == 'fish_from_hand') {
      viewModel.updateBet(catIndex, 1);
      SeService().play('button_buni.mp3');
    } else if (data is ItemType) {
      viewModel.updateItemPlacement(catIndex, data);
      SeService().play('button_buni.mp3');
    }
  }

  Widget _buildFishWithNumber(String number, {double size = 48}) {
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
            shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(ItemType type, {double size = 32}) {
    if (type.imagePath != null) {
      return Image.asset(
        type.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(Icons.help_outline, size: size, color: Colors.grey);
  }

  Color _getItemColor(ItemType type) {
    switch (type) {
      case ItemType.catTeaser:
        return Colors.purple;
      case ItemType.surpriseHorn:
        return Colors.orange;
      case ItemType.matatabi:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _flyFishAnimation(
    BuildContext context,
    Offset start,
    String number, {
    double size = 48,
  }) {
    final box = _myHandFishKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final end = box.localToGlobal(box.size.center(Offset.zero));

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        onEnd: () => entry.remove(),
        builder: (context, value, child) {
          final pos = Offset.lerp(start, end, value)!;
          return Positioned(
            left: pos.dx - size / 2,
            top: pos.dy - size / 2,
            child: IgnorePointer(
              child: _buildFishWithNumber(number, size: size),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
  }
}

class DotPatternPainter extends CustomPainter {
  final Color dotColor;
  final double dotRadius;
  final double spacing;
  DotPatternPainter({
    required this.dotColor,
    this.dotRadius = 1.5,
    this.spacing = 10.0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
