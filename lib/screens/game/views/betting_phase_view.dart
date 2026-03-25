import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../../../models/game_room.dart';
import '../../../models/cat_inventory.dart';
import '../../../models/item.dart';
import '../../../models/cards/game_card.dart';
import '../game_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';

final GlobalKey _myHandFishKey = GlobalKey();
final GlobalKey _myItemsKey = GlobalKey();
final Map<ItemType, GlobalKey> _itemTypeKeys = {
  ItemType.catTeaser: GlobalKey(),
  ItemType.surpriseHorn: GlobalKey(),
  ItemType.matatabi: GlobalKey(),
};

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

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: Column(
            children: [
              // ターン情報 (最上部)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
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
                      'ターン ${room.currentTurn}',
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      child: DragTarget<Object>(
                        onWillAccept: (data) => !viewModel.hasPlacedBet,
                        onAccept: (data) {
                          _handleDrop(viewModel, catIndex, data, currentBet);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isTarget = candidateData.isNotEmpty;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 2.0 : 8.0,
                              horizontal: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ).withOpacity(isTarget ? 0.9 : 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTarget
                                    ? Colors.yellow
                                    : Colors.grey.shade300,
                                width: isTarget ? 3 : 1,
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start, // Changed to start for better alignment
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: isSmallScreen ? 110 : 150, // 余裕を持たせた高さに修正
                                        child: _buildCatCard(
                                          viewModel,
                                          card,
                                          isSmallScreen,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 8),
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
                  fishCount: playerData.myFishCount,
                  inventory: playerData.myCatsWon,
                  viewModel: viewModel,
                  isReady: viewModel.isMyReady,
                  isSmallScreen: isSmallScreen,
                ),
              ),

              // 確定ボタン
              Padding(
                padding: EdgeInsets.only(
                  top: isSmallScreen ? 2.0 : 4.0,
                  bottom: isSmallScreen ? 2.0 : 4.0,
                ),
                child: Center(
                  child: SizedBox(
                    height: (isSmallScreen ? 36.0 : 44.0) + 6.0,
                    width: isSmallScreen ? 140.0 : 160.0,
                    child: StereoscopicButton(
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    StereoscopicButton(
                                      baseColor: Colors.pink.shade400,
                                      shadowColor: Colors.pink.shade900,
                                      borderRadius: 12,
                                      depth: 4,
                                      onPressed: () {
                                        SeService().play('button_buni.mp3');
                                        Navigator.of(context).pop();
                                        viewModel.placeBets();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '確定する',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      baseColor: viewModel.isMyReady
                          ? Colors.grey.shade400
                          : Colors.pink.shade400,
                      shadowColor: viewModel.isMyReady
                          ? Colors.grey.shade600
                          : Colors.pink.shade900,
                      borderRadius: 22,
                      depth: viewModel.isMyReady ? 2 : 6,
                      child: Center(
                        child: Text(
                          viewModel.confirmBetsButtonLabel,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ヘルプボタン (右下)
        Positioned(
          bottom: 12,
          right: 4,
          child: _buildHelpButton(context, isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildHelpButton(BuildContext context, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        SeService().play('button_buni.mp3');
        _showGameGuideDialog(context, isSmallScreen);
      },
      child: StereoscopicWidget(
        baseColor: Colors.white,
        shadowColor: Colors.orange.shade200,
        borderRadius: 50,
        depth: 4,
        showStripes: false,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          child: Icon(
            Icons.question_mark,
            size: isSmallScreen ? 14 : 20,
            color: Colors.orange.shade700,
          ),
        ),
      ),
    );
  }

  void _showGameGuideDialog(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedTab = 0; // 0: アイテム, 1: キャラクター
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              titlePadding: EdgeInsets.zero,
              title: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ヘッダー
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 48, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.question_mark, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'アイテム・キャラクター',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // タブ
                      Row(
                        children: [
                          _buildTabButton(
                            text: 'アイテム',
                            isSelected: selectedTab == 0,
                            onTap: () => setState(() => selectedTab = 0),
                          ),
                          _buildTabButton(
                            text: 'キャラクター',
                            isSelected: selectedTab == 1,
                            onTap: () => setState(() => selectedTab = 1),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: isSmallScreen ? 320 : 380,
                height: isSmallScreen ? 400 : 550,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: selectedTab == 0
                      ? _buildGuideList([
                          _GuideItem(
                            'ねこじゃらし',
                            'assets/images/nekojarashi.png',
                            '相手が魚を置いていなければ、その猫をタダで獲得できる。読み勝ちの一手。',
                            tagColor: Colors.red.shade50,
                            tagTextColor: Colors.red.shade400,
                          ),
                          _GuideItem(
                            'びっくりホーン',
                            'assets/images/horn.png',
                            '両者が置いた魚をすべて無効化。相手に取られたくない時に有効！',
                            tagColor: Colors.blue.shade50,
                            tagTextColor: Colors.blue.shade400,
                          ),
                          _GuideItem(
                            'またたび',
                            'assets/images/matatabi.png',
                            'その猫を獲得するために必要な魚の数が2倍になる。狙われている猫を守るのに使える。',
                            tagColor: Colors.purple.shade50,
                            tagTextColor: Colors.purple.shade400,
                          ),
                        ])
                      : _buildGuideList([
                          _GuideItem(
                            '茶トラねこ・白ねこ・黒ねこ',
                            null,
                            '3種類または同じ色3匹集めると勝利！基本となるカード。',
                            imagePaths: [
                              'assets/images/tyatoranekopng.png',
                              'assets/images/sironeko.png',
                              'assets/images/kuroneko.png',
                            ],
                            tagColor: Colors.orange.shade50,
                            tagTextColor: Colors.orange.shade600,
                          ),
                          _GuideItem(
                            '漁師',
                            'assets/images/ryousi.png',
                            '仲間にした後のターンから、毎ターンさかなが1つおまけで貰えるようになる。',
                            tagColor: Colors.orange.shade50,
                            tagTextColor: Colors.orange.shade600,
                          ),
                          _GuideItem(
                            'いぬ',
                            'assets/images/inu.png',
                            '相手が持っているキャラクターを強制的に逃がす事ができる。',
                            tagColor: Colors.orange.shade50,
                            tagTextColor: Colors.orange.shade600,
                          ),
                          _GuideItem(
                            'アイテム屋',
                            'assets/images/shop.png',
                            '仲間にした時、使ったアイテムを1つ復活させることができる。',
                            tagColor: Colors.orange.shade50,
                            tagTextColor: Colors.orange.shade600,
                          ),
                        ]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            Container(
              height: 2,
              color: isSelected ? Colors.black87 : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideList(List<_GuideItem> items) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイコン画像
              Container(
                width: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.imagePaths != null && item.imagePaths!.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: item.imagePaths!
                            .map(
                              (path) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Image.asset(
                                  path,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: item.imagePath != null
                            ? Image.asset(item.imagePath!, fit: BoxFit.contain)
                            : (item.fallbackIcon != null
                                  ? Icon(item.fallbackIcon)
                                  : const Icon(Icons.help_outline)),
                      ),
              ),
              const SizedBox(width: 12),
              // 説明テキスト
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    if (item.tag != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.tagColor ?? Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.tag!,
                          style: TextStyle(
                            fontSize: 10,
                            color: item.tagTextColor ?? Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    final bgColor = isOpponent
        ? const Color.fromARGB(255, 245, 143, 158)
        : const Color.fromARGB(255, 143, 208, 245);
    final iconSize = isSmallScreen ? 28.0 : 50.0;
    final fishIconSize = isSmallScreen ? 28.0 : 48.0;

    final iconAndCardsRow = SizedBox(
      width: isSmallScreen ? 280 : 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // アイコンとユーザー名
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
          Expanded(
            child: Container(
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
                    height: isSmallScreen ? 45 : 60,
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
          ),
        ],
      ),
    );

    final fishAndItemsRow = SizedBox(
      width: isSmallScreen ? 280 : 380,
      child: Row(
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
          // ドット柄背景 (セクション全体に広がる)
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(
                dotColor: Colors.white.withOpacity(0.4),
                spacing: 12,
              ),
            ),
          ),
          // 元のレイアウト構造を維持したコンテンツ
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
                      SizedBox(height: isSmallScreen ? 1 : 6),
                      fishAndItemsRow,
                    ] else ...[
                      fishAndItemsRow,
                      SizedBox(height: isSmallScreen ? 1 : 6),
                      iconAndCardsRow,
                    ],
                    if (statusLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBF5F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4D331F),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF4D331F),
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusLabel.endsWith('...')
                                    ? statusLabel.replaceFirst('...', '')
                                    : statusLabel,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (statusLabel.endsWith('...'))
                                AnimatedWaitingDots(
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
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
                    border: Border.all(
                      color: const Color.fromARGB(255, 165, 173, 180),
                      width: 2,
                    ),
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
                child: Text(
                  '🐟',
                  style: TextStyle(fontSize: fishSize * 1.3, height: 1.0),
                ),
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
          showStripes: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              card.displayName,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
Widget _buildDishArea(
  BuildContext context, {
  required GameScreenViewModel viewModel,
  required String catIndex,
  required int currentBet,
  required ItemType? placedItem,
  bool isSmallScreen = false,
  bool isTarget = false,
}) {
  final dishWidth = isSmallScreen ? 60.0 : 100.0;
  final fishSize = isSmallScreen ? 35.0 : 50.0;
  final dishKey = GlobalObjectKey('dish_fish_$catIndex');

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
                            color: Colors.transparent,
                            child: Text(
                              '🐟',
                              style: TextStyle(
                                fontSize: fishSize * 1.3,
                                height: 1.0,
                              ),
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
                              if (currentBet > 0) {
                                final RenderBox? box =
                                    dishKey.currentContext?.findRenderObject()
                                        as RenderBox?;
                                if (box != null) {
                                  final center = box.localToGlobal(
                                    box.size.center(Offset.zero),
                                  );
                                  _flyFishAnimation(
                                    context,
                                    center,
                                    '1',
                                    size: fishSize,
                                  );
                                }
                                viewModel.updateBet(catIndex, currentBet - 1);
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
}

void _handleDrop(
  GameScreenViewModel viewModel,
  String catIndex,
  Object? data,
  int currentBet,
) {
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
      : IndexedStack(
          index: 0,
          children: [
            Draggable<ItemType>(
              key: _itemTypeKeys[type],
              data: type,
              feedback: Material(
                color: Colors.transparent,
                child: _buildItemIcon(
                  type,
                  isFeedback: true,
                  size: itemSize * 1.2,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildItemIcon(type, size: itemSize),
              ),
              child: _buildItemIcon(type, size: itemSize),
            ),
          ],
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

  return StereoscopicContainer(
    baseColor: Colors.white,
    shadowColor: color.withOpacity(0.3),
    borderRadius: 12,
    depth: 4,
    showStripes: false,
    showHighlight: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
    ),
  );
}

Widget _buildItemSlot(
  String catIndex,
  ItemType? placedItem,
  GameScreenViewModel viewModel, {
  bool isSmallScreen = false,
}) {
  final itemIconSize = isSmallScreen ? 24.0 : 36.0; // 配置先を少し小さく
  final slotKey = GlobalObjectKey('item_slot_$catIndex');

  final color = placedItem != null ? _getItemColor(placedItem) : Colors.white;
  final shadowColor = placedItem != null
      ? _getItemColor(placedItem).withOpacity(0.8)
      : Colors.grey.shade300;

  return SizedBox(
    width: itemIconSize + 16,
    height: itemIconSize + 16,
    child: StereoscopicContainer(
      baseColor: placedItem != null ? color : Colors.white.withOpacity(0.5),
      shadowColor: shadowColor,
      borderRadius: 8,
      depth: 4,
      showStripes: placedItem != null,
      showDots: placedItem == null,
      child: Center(
        child: placedItem != null
            ? (!viewModel.hasPlacedBet
                  ? Builder(
                      builder: (context) {
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
                            key: slotKey,
                            onTap: () {
                              final RenderBox? box =
                                  slotKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (box != null) {
                                final center = box.localToGlobal(
                                  box.size.center(Offset.zero),
                                );
                                _flyItemAnimation(
                                  context,
                                  center,
                                  placedItem,
                                  size: itemIconSize,
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
                size: isSmallScreen ? 14 : 18,
              ),
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
      return StereoscopicContainer(
        baseColor: Colors.white,
        shadowColor: Colors.grey.shade300,
        borderRadius: 6,
        depth: 2,
        showStripes: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCatAvatar(
                viewModel,
                cat.name,
                size: isSmallScreen ? 24 : 36,
              ),
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

void _flyFishAnimation(
  BuildContext context,
  Offset start,
  String number, {
  double size = 48,
}) {
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
            left: pos.dx,
            top: pos.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(
                child: _buildFishWithNumber(number, size: size),
              ),
            ),
          );
        },
      );
    },
  );
  overlay.insert(entry);
}

void _flyItemAnimation(
  BuildContext context,
  Offset start,
  ItemType type, {
  double size = 32,
}) {
  final targetKey = _itemTypeKeys[type];
  final RenderBox? itemBox =
      targetKey?.currentContext?.findRenderObject() as RenderBox?;

  // 指定のアイテムが見つからない場合は従来の _myItemsKey をフォールバックに使用
  final RenderBox? fallBackBox =
      _myItemsKey.currentContext?.findRenderObject() as RenderBox?;

  final targetRenderBox = itemBox ?? fallBackBox;
  if (targetRenderBox == null) return;

  final Offset end = targetRenderBox.localToGlobal(
    targetRenderBox.size.center(Offset.zero),
  );

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
            left: pos.dx,
            top: pos.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(child: _buildItemImage(type, size: size)),
            ),
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

class _GuideItem {
  final String name;
  final String? imagePath;
  final String description;
  final List<String>? imagePaths;
  final IconData? fallbackIcon;
  final String? tag;
  final Color? tagColor;
  final Color? tagTextColor;

  _GuideItem(
    this.name,
    this.imagePath,
    this.description, {
    this.imagePaths,
    this.fallbackIcon,
    this.tag,
    this.tagColor,
    this.tagTextColor,
  });
}

/// 背景のドット柄を描画するペインター
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
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
