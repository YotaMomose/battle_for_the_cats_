import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/cat_inventory.dart';
import '../../../models/item.dart';
import '../../../models/cards/game_card.dart';
import '../game_screen_view_model.dart';

final GlobalKey _myHandFishKey = GlobalKey();
final GlobalKey _myItemsKey = GlobalKey();

/// 賭けフェーズ画面
class BettingPhaseView extends StatelessWidget {
  final GameRoom room;

  const BettingPhaseView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: isSmallScreen ? 2.0 : 4.0,
      ),
      child: Column(
        children: [
          // ターン情報 (最上部)
          Text(
            'ターン ${room.currentTurn}',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 対戦相手セクション
          Expanded(
            flex: isSmallScreen ? 4 : 4,
            child: _buildPlayerSection(
              context,
              isOpponent: true,
              displayName: viewModel.opponentDisplayName,
              iconEmoji: viewModel.opponentIconEmoji,
              fishCount: playerData.opponentFishCount,
              inventory: playerData.opponentCatsWon,
              viewModel: viewModel,
              statusLabel: viewModel.opponentReadyStatusLabel,
              statusColor: viewModel.opponentReadyStatusColor,
              isSmallScreen: isSmallScreen,
            ),
          ),

          // 3匹の猫カードとお皿のエリア (中央)
          Expanded(
            flex: isSmallScreen ? 6 : 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(3, (index) {
                final catIndex = index.toString();
                final cards = room.currentRound?.toList() ?? [];
                if (cards.isEmpty || index >= cards.length) {
                  return const Expanded(child: SizedBox());
                }

                final card = cards[index];
                final currentBet = viewModel.bets[catIndex] ?? 0;
                final placedItem = viewModel.getPlacedItem(catIndex);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 4.0 : 8.0,
                      horizontal: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        228,
                        9,
                        9,
                      ).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCatCard(viewModel, card, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 2 : 8),
                          _buildDishArea(
                            viewModel: viewModel,
                            catIndex: catIndex,
                            currentBet: currentBet,
                            placedItem: placedItem,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ),
                    ),
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
              fishCount: playerData.myFishCount,
              inventory: playerData.myCatsWon,
              viewModel: viewModel,
              isReady: viewModel.isMyReady,
              isSmallScreen: isSmallScreen,
            ),
          ),

          // 確定ボタン
          if (!viewModel.isMyReady)
            Padding(
              padding: EdgeInsets.only(
                top: isSmallScreen ? 2.0 : 4.0,
                bottom: isSmallScreen ? 2.0 : 4.0,
              ),
              child: SizedBox(
                height: isSmallScreen ? 36 : 44,
                width: isSmallScreen ? 140 : 160,
                child: ElevatedButton(
                  onPressed: viewModel.hasPlacedBet || viewModel.isMyReady
                      ? null
                      : () {
                          SeService().play('button_buni.mp3');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              alignment: Alignment.bottomCenter,
                              title: const Text(
                                '確定しますか？',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'この内容で確定しますか？\n（確定後は他のプレイヤーを待ちます）',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'キャンセル',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink.shade400,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    SeService().play('button_buni.mp3');
                                    Navigator.of(context).pop();
                                    viewModel.placeBets();
                                  },
                                  child: const Text(
                                    '確定する',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    viewModel.confirmBetsButtonLabel,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// プレイヤー情報のセクション
  Widget _buildPlayerSection(
    BuildContext context, {
    required bool isOpponent,
    required String displayName,
    required String iconEmoji,
    required int fishCount,
    required CatInventory inventory,
    required GameScreenViewModel viewModel,
    String? statusLabel,
    Color? statusColor,
    bool isReady = false,
    bool isSmallScreen = false,
  }) {
    final bgColor = isOpponent ? Colors.red.shade50 : Colors.blue.shade50;
    final iconSize = isSmallScreen ? 28.0 : 50.0;
    final fishIconSize = isSmallScreen ? 28.0 : 48.0;

    final iconAndCardsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                iconEmoji,
                style: TextStyle(fontSize: isSmallScreen ? 16 : 28),
              ),
            ),
            if (!isSmallScreen) const SizedBox(height: 4),
            SizedBox(
              width: isSmallScreen ? 40 : 60,
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        SizedBox(width: isSmallScreen ? 4 : 12),
        // 獲得カード一覧
        Container(
          width: isSmallScreen ? 180 : 240,
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: isSmallScreen ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '合計コスト：${inventory.totalCost}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              if (!isSmallScreen) const SizedBox(height: 2),
              SizedBox(
                height: isSmallScreen ? 30 : 60,
                child: _buildWonCatsList(
                  inventory,
                  viewModel,
                  isCompact: true,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final fishAndItemsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        // 魚の数 (自分ならドラッグ＆ドロップ用)
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
        Container(
          width: isSmallScreen ? 160 : 200,
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: isSmallScreen ? 1 : 4,
          ),
          decoration: BoxDecoration(
            color: isOpponent ? Colors.red.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOpponent ? Colors.red.shade200 : Colors.blue.shade200,
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
      ],
    );

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: isSmallScreen ? 2.0 : 8.0,
      ),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOpponent) ...[
              iconAndCardsRow,
              SizedBox(height: isSmallScreen ? 2 : 6),
              fishAndItemsRow,
            ] else ...[
              fishAndItemsRow,
              SizedBox(height: isSmallScreen ? 2 : 6),
              iconAndCardsRow,
            ],
            if (statusLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isReady && !isOpponent)
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  '準備完了：結果を待っています...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // 自分セクションの場合は、全体を魚/アイテム返却用のドロップエリアにする
    if (!isOpponent) {
      return DragTarget<String>(
        onWillAccept: (data) =>
            !viewModel.hasPlacedBet &&
            data != null &&
            (data.startsWith('fish_from_') || data.startsWith('item_from_')),
        onAccept: (data) {
          if (data.startsWith('fish_from_')) {
            final catIndex = data.replaceFirst('fish_from_', '');
            if (catIndex != 'hand') {
              final currentBet = viewModel.bets[catIndex] ?? 0;
              if (currentBet > 0) {
                viewModel.updateBet(catIndex, currentBet - 1);
                SeService().play('button_buni.mp3');
              }
            }
          } else if (data.startsWith('item_from_')) {
            final catIndex = data.replaceFirst('item_from_', '');
            viewModel.updateItemPlacement(catIndex, null);
            SeService().play('button_buni.mp3');
          }
        },
        builder: (context, candidateData, rejectedData) {
          // ドロップ可能アイテムが上にあるときは少し色を変えてフィードバック
          return Container(
            foregroundDecoration: candidateData.isNotEmpty
                ? BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue, width: 2),
                  )
                : null,
            child: content,
          );
        },
      );
    }

    return content;
  }

  /// 自分の魚表示エリア (ドラッグ＆ドロップ対応)
  Widget _buildMyFishDraggableArea(
    int totalFish,
    GameScreenViewModel viewModel,
    bool isSmallScreen,
  ) {
    final remaining = totalFish - viewModel.totalBet;
    final canDrag = !viewModel.hasPlacedBet && remaining > 0;
    final fishSize = isSmallScreen ? 36.0 : 48.0;

    // 魚エリア単体のDragTargetは廃止し（上位のPlayerSectionで受けるため）、
    // 見た目とDraggable（投げる側）だけを残す
    return Container(
      key: _myHandFishKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: canDrag
          ? Draggable<String>(
              data: 'fish_from_hand',
              feedback: Material(
                color: Colors.transparent,
                child: _buildFishWithNumber('$remaining', size: fishSize * 1.3),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildFishWithNumber('$remaining', size: fishSize),
              ),
              child: _buildFishWithNumber('$remaining', size: fishSize),
            )
          : Opacity(
              opacity: 0.5,
              child: _buildFishWithNumber('$remaining', size: fishSize),
            ),
    );
  }
}

/// 猫カード
Widget _buildCatCard(
  GameScreenViewModel viewModel,
  GameCard card,
  bool isSmallScreen,
) {
  final avatarSize = isSmallScreen ? 50.0 : 100.0;
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.lightGreen.shade200,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade300, width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.displayName,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        _buildCatAvatar(viewModel, card.displayName, size: avatarSize),
        SizedBox(height: isSmallScreen ? 1 : 2),
        // 魚アイコンによるコスト表示
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 1,
          children: List.generate(
            card.baseCost,
            (_) =>
                Text('🐟', style: TextStyle(fontSize: isSmallScreen ? 12 : 16)),
          ),
        ),
      ],
    ),
  );
}

/// お皿エリア
Widget _buildDishArea({
  required GameScreenViewModel viewModel,
  required String catIndex,
  required int currentBet,
  required ItemType? placedItem,
  bool isSmallScreen = false,
}) {
  return DragTarget<Object>(
    onWillAccept: (data) => !viewModel.hasPlacedBet,
    onAccept: (data) {
      if (data == 'fish_from_hand') {
        // 手元からの魚
        final totalFish = viewModel.playerData?.myFishCount ?? 0;
        if (viewModel.totalBet < totalFish) {
          viewModel.updateBet(catIndex, currentBet + 1);
          SeService().play('button_buni.mp3');
        }
      } else if (data is String && data.startsWith('fish_from_')) {
        // 他のお皿からの魚
        final fromIndex = data.replaceFirst('fish_from_', '');
        if (fromIndex != catIndex && fromIndex != 'hand') {
          final fromBet = viewModel.bets[fromIndex] ?? 0;
          if (fromBet > 0) {
            viewModel.updateBet(fromIndex, fromBet - 1);
            viewModel.updateBet(catIndex, currentBet + 1);
            SeService().play('button_buni.mp3');
          }
        }
      } else if (data is ItemType) {
        // 手元からのアイテム
        viewModel.updateItemPlacement(catIndex, data);
        SeService().play('button_buni.mp3');
      } else if (data is String && data.startsWith('item_from_')) {
        // 他のお皿からのアイテム
        final fromIndex = data.replaceFirst('item_from_', '');
        if (fromIndex != catIndex) {
          final item = viewModel.getPlacedItem(fromIndex);
          if (item != null) {
            viewModel.updateItemPlacement(fromIndex, null);
            viewModel.updateItemPlacement(catIndex, item);
            SeService().play('button_buni.mp3');
          }
        }
      }
    },
    builder: (context, candidateData, rejectedData) {
      final isTarget = candidateData.isNotEmpty;
      Offset tapPosition = Offset.zero;
      final dishWidth = isSmallScreen ? 55.0 : 100.0;
      final fishSize = isSmallScreen ? 32.0 : 48.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // お皿画像
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
              // 魚の賭け数表示
              Transform.translate(
                offset: Offset(0, isSmallScreen ? -10 : -15),
                child: (!viewModel.isMyReady)
                    ? (currentBet > 0 && !viewModel.hasPlacedBet
                          ? Draggable<String>(
                              data: 'fish_from_$catIndex',
                              feedback: Material(
                                color: const Color.fromARGB(0, 141, 43, 43),
                                child: _buildFishWithNumber(
                                  '$currentBet',
                                  size: fishSize * 1.3,
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
                                onTapDown: (details) {
                                  tapPosition = details.globalPosition;
                                },
                                onTap: () {
                                  if (currentBet > 0) {
                                    if (tapPosition != Offset.zero) {
                                      _flyFishAnimation(
                                        context,
                                        tapPosition,
                                        '1',
                                      );
                                    }
                                    viewModel.updateBet(
                                      catIndex,
                                      currentBet - 1,
                                    );
                                    SeService().play('button_buni.mp3');
                                  }
                                },
                                child: _buildFishWithNumber(
                                  '$currentBet',
                                  size: fishSize,
                                ),
                              ),
                            )
                          : _buildFishWithNumber('$currentBet', size: fishSize))
                    : _buildFishWithNumber('$currentBet', size: fishSize),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          // アイテムスロット（お皿と被らないように下に配置）
          _buildItemSlot(
            catIndex,
            placedItem,
            viewModel,
            isSmallScreen: isSmallScreen,
          ),
        ],
      );
    },
  );
}

/// 自分のアイテムリスト
Widget _buildMyItemsList(
  GameScreenViewModel viewModel, {
  bool isSmallScreen = false,
}) {
  // 個別のDragTargetは廃止し、上位のPlayerSectionで受ける
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

/// 相手のアイテム表示
Widget _buildOpponentItems(
  GameScreenViewModel viewModel, {
  double iconSize = 32,
}) {
  final inventory = viewModel.playerData?.opponentInventory;
  if (inventory == null) return const SizedBox();

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [ItemType.catTeaser, ItemType.surpriseHorn, ItemType.matatabi]
        .map((type) {
          final count = inventory.count(type);
          final isUsed = count <= 0;
          return Opacity(
            opacity: isUsed ? 0.3 : 1.0,
            child: _buildItemIcon(
              type,
              size: iconSize,
              showLabel: false,
              isPlaced: isUsed,
            ),
          );
        })
        .toList(),
  );
}

Widget _buildDraggableItem(
  ItemType type,
  GameScreenViewModel viewModel, {
  bool isSmallScreen = false,
}) {
  final count = viewModel.playerData?.myInventory.count(type) ?? 0;
  bool isPlaced = false;
  for (int i = 0; i < 3; i++) {
    if (viewModel.getPlacedItem(i.toString()) == type) {
      isPlaced = true;
      break;
    }
  }
  final bool isUnavailable = count <= 0 || isPlaced;
  final itemSize = isSmallScreen ? 28.0 : 40.0;

  return isUnavailable
      ? Opacity(
          opacity: 0.3,
          child: _buildItemIcon(type, isPlaced: true, size: itemSize),
        )
      : Draggable<ItemType>(
          data: type,
          feedback: Material(
            color: Colors.transparent,
            child: _buildItemIcon(type, isFeedback: true, size: itemSize * 1.2),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildItemIcon(type, size: itemSize),
          ),
          child: _buildItemIcon(type, size: itemSize),
        );
}

Widget _buildItemIcon(
  ItemType type, {
  bool isFeedback = false,
  bool isPlaced = false,
  double size = 32,
  bool showLabel = false, // デフォルトでオフにする
}) {
  final color = _getItemColor(type);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.5)),
      boxShadow: isFeedback
          ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
          : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildItemImage(type, size: size),
        if (showLabel)
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 8,
              color: isPlaced ? Colors.grey : color,
            ),
          ),
      ],
    ),
  );
}

Widget _buildItemSlot(
  String catIndex,
  ItemType? placedItem,
  GameScreenViewModel viewModel, {
  bool isSmallScreen = false,
}) {
  final slotSize = isSmallScreen ? 32.0 : 40.0;
  final itemIconSize = isSmallScreen ? 26.0 : 32.0;

  return Container(
    width: slotSize,
    height: slotSize,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.5),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.grey.shade400,
        style: placedItem == null ? BorderStyle.none : BorderStyle.solid,
      ),
    ),
    child: Center(
      child: placedItem != null
          ? (!viewModel.hasPlacedBet
                ? Builder(
                    builder: (context) {
                      Offset tapPosition = Offset.zero;
                      return Draggable<String>(
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
                          child: _buildItemImage(
                            placedItem,
                            size: itemIconSize,
                          ),
                        ),
                        child: GestureDetector(
                          onTapDown: (details) {
                            tapPosition = details.globalPosition;
                          },
                          onTap: () {
                            if (tapPosition != Offset.zero) {
                              _flyItemAnimation(
                                context,
                                tapPosition,
                                placedItem,
                              );
                            }
                            viewModel.updateItemPlacement(catIndex, null);
                            SeService().play('button_buni.mp3');
                          },
                          child: _buildItemImage(
                            placedItem,
                            size: itemIconSize,
                          ),
                        ),
                      );
                    },
                  )
                : _buildItemImage(placedItem, size: itemIconSize))
          : Icon(
              Icons.add,
              color: Colors.grey.shade400,
              size: isSmallScreen ? 12 : 14,
            ),
    ),
  );
}

Widget _buildItemImage(ItemType type, {double size = 32}) {
  if (type.imagePath != null) {
    return Image.asset(
      type.imagePath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(_getItemIcon(type), size: size, color: _getItemColor(type)),
    );
  }
  return Icon(_getItemIcon(type), size: size, color: _getItemColor(type));
}

IconData _getItemIcon(ItemType type) {
  switch (type) {
    case ItemType.catTeaser:
      return Icons.auto_awesome;
    case ItemType.surpriseHorn:
      return Icons.campaign;
    case ItemType.matatabi:
      return Icons.savings;
    default:
      return Icons.help_outline;
  }
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

Widget _buildWonCatsList(
  CatInventory inventory,
  GameScreenViewModel viewModel, {
  bool isCompact = false,
  bool isSmallScreen = false,
}) {
  final cats = inventory.all;
  if (cats.isEmpty) {
    return const Center(
      child: Text('なし', style: TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: cats.length,
    itemBuilder: (context, index) {
      final cat = cats[index];
      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCatAvatar(viewModel, cat.name, size: isSmallScreen ? 24 : 36),
            Text(
              '🐟${cat.cost}',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCatAvatar(
  GameScreenViewModel viewModel,
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
      errorBuilder: (context, error, stackTrace) => Icon(
        viewModel.getCatIconData(catName),
        size: size,
        color: viewModel.getCatIconColor(catName),
      ),
    );
  }
  return Icon(
    viewModel.getCatIconData(catName),
    size: size,
    color: viewModel.getCatIconColor(catName),
  );
}

void _flyFishAnimation(BuildContext context, Offset start, String number) {
  final RenderBox? handBox =
      _myHandFishKey.currentContext?.findRenderObject() as RenderBox?;
  if (handBox == null) return;

  final Offset end = handBox.localToGlobal(handBox.size.center(Offset.zero));

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
        onEnd: () {
          entry.remove();
        },
        builder: (context, value, child) {
          final pos = Offset.lerp(start, end, value)!;
          return Positioned(
            left: pos.dx - 24, // 魚アイコンの半分のサイズで中心を合わせる
            top: pos.dy - 24,
            child: IgnorePointer(child: _buildFishWithNumber(number, size: 48)),
          );
        },
      );
    },
  );
  overlay.insert(entry);
}

void _flyItemAnimation(BuildContext context, Offset start, ItemType type) {
  final RenderBox? handBox =
      _myItemsKey.currentContext?.findRenderObject() as RenderBox?;
  if (handBox == null) return;

  final Offset end = handBox.localToGlobal(handBox.size.center(Offset.zero));

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
        onEnd: () {
          entry.remove();
        },
        builder: (context, value, child) {
          final pos = Offset.lerp(start, end, value)!;
          return Positioned(
            left: pos.dx - 16, // アイコンサイズ(32)の半分
            top: pos.dy - 16,
            child: IgnorePointer(child: _buildItemImage(type, size: 32)),
          );
        },
      );
    },
  );
  overlay.insert(entry);
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
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 4),
            Shadow(color: Colors.white, blurRadius: 4),
            Shadow(color: Colors.white, blurRadius: 4),
          ],
        ),
      ),
    ],
  );
}
