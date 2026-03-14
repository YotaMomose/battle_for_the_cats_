import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/cat_inventory.dart';
import '../../../models/item.dart';
import '../../../models/cards/game_card.dart';
import '../game_screen_view_model.dart';

/// 賭けフェーズ画面
class BettingPhaseView extends StatelessWidget {
  final GameRoom room;

  const BettingPhaseView({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final playerData = viewModel.playerData!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 40.0,
      ), // 上下パディングを少し詰め
      child: Column(
        children: [
          // ターン情報 (最上部)
          Text(
            'ターン ${room.currentTurn}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          // 対戦相手セクション
          Expanded(
            flex: 3,
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
            ),
          ),

          // 3匹の猫カードとお皿のエリア (中央)
          Expanded(
            flex: 5,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCatCard(viewModel, card),
                        const SizedBox(height: 4),
                        _buildDishArea(
                          viewModel: viewModel,
                          catIndex: catIndex,
                          currentBet: currentBet,
                          placedItem: placedItem,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // 自分セクション
          Expanded(
            flex: 3,
            child: _buildPlayerSection(
              context,
              isOpponent: false,
              displayName: viewModel.myDisplayName,
              iconEmoji: viewModel.myIconEmoji,
              fishCount: playerData.myFishCount,
              inventory: playerData.myCatsWon,
              viewModel: viewModel,
              isReady: viewModel.isMyReady,
            ),
          ),

          // 確定ボタン
          if (!viewModel.isMyReady)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: SizedBox(
                height: 44, // 高さを固定して安定させる
                width: 160,
                child: ElevatedButton(
                  onPressed: viewModel.hasPlacedBet || viewModel.isMyReady
                      ? null
                      : () {
                          SeService().play('button_buni.mp3');
                          viewModel.placeBets();
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
                    style: const TextStyle(
                      fontSize: 16,
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

  /// プレイヤー情報のセクション (デモ画像の上部/下部ピンクエリアに相当)
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
  }) {
    final iconAndCardsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // アイコンと名前
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(iconEmoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 60,
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // 獲得カード一覧 (高さを少しアップ)
        Expanded(
          child: Container(
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildWonCatsList(inventory, viewModel, isCompact: true),
          ),
        ),
      ],
    );

    final fishAndItemsRow = Row(
      children: [
        const SizedBox(width: 4),
        // 魚の数
        Text(
          '🐟 ${isOpponent ? fishCount : (fishCount - viewModel.totalBet)}/$fishCount',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(width: 16),
        // 所持アイテム一覧 (高さを少しアップ)
        Expanded(
          child: SizedBox(
            height: isOpponent ? 50 : 90,
            child: isOpponent
                ? _buildOpponentItems(viewModel)
                : _buildMyItemsList(viewModel),
          ),
        ),
      ],
    );

    final bgColor = isOpponent ? Colors.red.shade50 : Colors.pink.shade50;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 順序を入れ替え (相手はアイコンが上、自分は魚が上)
          if (isOpponent) iconAndCardsRow else fishAndItemsRow,
          const SizedBox(height: 6),
          if (isOpponent) fishAndItemsRow else iconAndCardsRow,
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
    );
  }

  /// 猫カード (画像 + 魚コストアイコン)
  Widget _buildCatCard(GameScreenViewModel viewModel, GameCard card) {
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _buildCatAvatar(
            viewModel,
            card.displayName,
            size: 100,
          ), // 少し小さくして全体のバランスを取る
          const SizedBox(height: 2),
          // 魚アイコンによるコスト表示
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 1,
            children: List.generate(
              card.baseCost,
              (_) => const Text('🐟', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// お皿エリア (背景 dish.png + 操作 + アイテムスロット)
  Widget _buildDishArea({
    required GameScreenViewModel viewModel,
    required String catIndex,
    required int currentBet,
    required ItemType? placedItem,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // お皿画像
        Image.asset('assets/images/dish.png', width: 300, fit: BoxFit.contain),
        // コンテンツ
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 賭け数操作 (- 🐟 +)
            if (!viewModel.isMyReady)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactIconButton(
                    icon: Icons.remove,
                    onPressed: viewModel.hasPlacedBet || currentBet == 0
                        ? null
                        : () => viewModel.updateBet(catIndex, currentBet - 1),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$currentBet',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Text('🐟', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 2),
                  _buildCompactIconButton(
                    icon: Icons.add,
                    onPressed:
                        viewModel.hasPlacedBet ||
                            viewModel.totalBet >=
                                (viewModel.playerData?.myFishCount ?? 0)
                        ? null
                        : () => viewModel.updateBet(catIndex, currentBet + 1),
                  ),
                ],
              )
            else
              Text(
                '$currentBet 🐟',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            // アイテムスロット
            _buildItemSlot(catIndex, placedItem, viewModel),
          ],
        ),
      ],
    );
  }

  /// 自分のアイテムリスト (ドラッグ可能)
  Widget _buildMyItemsList(GameScreenViewModel viewModel) {
    return DragTarget<String>(
      onWillAccept: (data) => !viewModel.hasPlacedBet,
      onAccept: (catIndex) => viewModel.updateItemPlacement(catIndex, null),
      builder: (context, candidateData, rejectedData) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDraggableItem(ItemType.catTeaser, viewModel),
            _buildDraggableItem(ItemType.surpriseHorn, viewModel),
            _buildDraggableItem(ItemType.matatabi, viewModel),
          ],
        );
      },
    );
  }

  /// 相手のアイテム表示
  Widget _buildOpponentItems(GameScreenViewModel viewModel) {
    final inventory = viewModel.playerData?.opponentInventory;
    if (inventory == null) return const SizedBox();

    return Row(
      children: ItemType.values.where((t) => t != ItemType.unknown).map((type) {
        final count = inventory.count(type);
        if (count <= 0) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: _buildItemIcon(type, size: 24, showLabel: false),
        );
      }).toList(),
    );
  }

  Widget _buildDraggableItem(ItemType type, GameScreenViewModel viewModel) {
    final count = viewModel.playerData?.myInventory.count(type) ?? 0;
    bool isPlaced = false;
    for (int i = 0; i < 3; i++) {
      if (viewModel.getPlacedItem(i.toString()) == type) {
        isPlaced = true;
        break;
      }
    }
    final bool isUnavailable = count <= 0 || isPlaced;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: isUnavailable
          ? Opacity(
              opacity: 0.3,
              child: _buildItemIcon(type, isPlaced: true, size: 44),
            )
          : Draggable<ItemType>(
              data: type,
              feedback: Material(
                color: Colors.transparent,
                child: _buildItemIcon(type, isFeedback: true, size: 44),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildItemIcon(type, size: 44),
              ),
              child: _buildItemIcon(type, size: 44),
            ),
    );
  }

  Widget _buildItemIcon(
    ItemType type, {
    bool isFeedback = false,
    bool isPlaced = false,
    double size = 32,
    bool showLabel = true,
  }) {
    final color = _getItemColor(type);
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: isFeedback
            ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItemImage(type, size: size),
          if (showLabel)
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
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
    GameScreenViewModel viewModel,
  ) {
    return DragTarget<Object>(
      onWillAccept: (data) => !viewModel.hasPlacedBet,
      onAccept: (data) {
        if (data is ItemType) {
          viewModel.updateItemPlacement(catIndex, data);
        } else if (data is String) {
          final fromIndex = data;
          if (fromIndex == catIndex) return;
          final item = viewModel.getPlacedItem(fromIndex);
          if (item != null) {
            viewModel.updateItemPlacement(fromIndex, null);
            viewModel.updateItemPlacement(catIndex, item);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.yellow.withOpacity(0.3)
                : Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade400,
              style: placedItem == null ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
          child: Center(
            child: placedItem != null
                ? Draggable<String>(
                    data: catIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildItemImage(placedItem, size: 36),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildItemImage(placedItem, size: 32),
                    ),
                    child: _buildItemImage(placedItem, size: 32),
                  )
                : Icon(Icons.add, color: Colors.grey.shade400, size: 14),
          ),
        );
      },
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
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCatAvatar(viewModel, cat.name, size: 20),
              Text(
                '★${cat.cost}',
                style: const TextStyle(fontSize: 8, color: Colors.red),
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

  Widget _buildCompactIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: onPressed == null ? Colors.grey : Colors.blue,
        ),
      ),
    );
  }
}
