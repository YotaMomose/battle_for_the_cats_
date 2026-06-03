import '../constants/game_constants.dart';
import '../models/bets.dart';
import 'cat_inventory.dart';
import 'item_inventory.dart';
import '../domain/dice.dart';
import '../models/item.dart';

/// Playerモデル
/// プレイヤー（ホストまたはゲスト）の状態を保持するデータモデル
class Player {
  final String id;
  String displayName;
  String iconId;
  int fishCount;
  CatInventory catsWon;
  int? diceRoll;
  bool rolled;
  bool confirmedRoll;
  bool confirmedRoundResult;
  Bets currentBets;
  ItemInventory items;
  bool ready;
  bool abandoned;
  int pendingItemRevivals;
  int fishermanCount;
  int pendingDogChases;
  bool confirmedFatCatEvent;
  bool isActive;
  int lastActiveAt;

  Player({
    required this.id,
    this.displayName = 'ゲスト',
    this.iconId = 'cat_orange',
    this.fishCount = 0,
    CatInventory? catsWon,
    this.diceRoll,
    this.rolled = false,
    this.confirmedRoll = false,
    this.confirmedRoundResult = false,
    Bets? currentBets,
    ItemInventory? items,
    this.ready = false,
    this.abandoned = false,
    this.pendingItemRevivals = 0,
    this.fishermanCount = 0,
    this.pendingDogChases = 0,
    this.confirmedFatCatEvent = false,
    this.isActive = true,
    int? lastActiveAt,
  }) : catsWon = catsWon ?? CatInventory(),
       currentBets = currentBets ?? Bets(),
       items = items ?? ItemInventory.initial(),
       lastActiveAt = lastActiveAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'iconId': iconId,
      'fishCount': fishCount,
      'catsWon': catsWon.toMapList(),
      'diceRoll': diceRoll,
      'rolled': rolled,
      'confirmedRoll': confirmedRoll,
      'confirmedRoundResult': confirmedRoundResult,
      'currentBets': currentBets.toMap(),
      'itemPlacements': currentBets.itemsToMap(),
      'items': items.toMap(),
      'ready': ready,
      'abandoned': abandoned,
      'pendingItemRevivals': pendingItemRevivals,
      'fishermanCount': fishermanCount,
      'pendingDogChases': pendingDogChases,
      'confirmedFatCatEvent': confirmedFatCatEvent,
      'isActive': isActive,
      'lastActiveAt': lastActiveAt,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'ゲスト',
      iconId: map['iconId'] ?? 'cat_orange',
      fishCount: map['fishCount'] ?? 0,
      catsWon: CatInventory.fromMapList(map['catsWon'] as List?),
      diceRoll: map['diceRoll'],
      rolled: map['rolled'] ?? false,
      confirmedRoll: map['confirmedRoll'] ?? false,
      confirmedRoundResult: map['confirmedRoundResult'] ?? false,
      currentBets: Bets.fromMap(
        Map<String, dynamic>.from(
          map['currentBets'] ?? {'0': 0, '1': 0, '2': 0},
        ),
        Map<String, dynamic>.from(
          map['itemPlacements'] ?? {'0': null, '1': null, '2': null},
        ),
      ),
      items: ItemInventory.fromMap(map['items'] as Map<String, dynamic>?),
      ready: map['ready'] ?? false,
      abandoned: map['abandoned'] ?? false,
      pendingItemRevivals: map['pendingItemRevivals'] ?? 0,
      fishermanCount: map['fishermanCount'] ?? 0,
      pendingDogChases: map['pendingDogChases'] ?? 0,
      confirmedFatCatEvent: map['confirmedFatCatEvent'] ?? false,
      isActive: map['isActive'] ?? true,
      lastActiveAt: map['lastActiveAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ===== Domain Methods =====

  /// 獲得した全にゃんこの合計コスト
  int get totalWonCatCost => catsWon.totalCost;

  /// 獲得したにゃんこの名前リスト
  List<String> get wonCatNames => catsWon.names;

  /// 獲得した漁師の数
  int get currentFishermanCount => fishermanCount;

  /// さかなを増やす
  void addFish(int amount) {
    fishCount += amount;
  }

  /// サイコロを振る
  void roll(Dice dice) {
    recordDiceRoll(dice.roll());
  }

  /// サイコロの目を記録する
  void recordDiceRoll(int value) {
    diceRoll = value;
    rolled = true;
    // サイコロの目 + 漁師の数だけさかなを追加
    addFish(value + fishermanCount);
  }

  /// 賭けとアイテムを設定する
  void placeBetsWithItems(
    Map<String, int> bets,
    Map<String, ItemType?> itemPlacements,
  ) {
    currentBets = Bets(bets, itemPlacements);
    ready = true;
  }

  /// 獲得したにゃんこを記録する
  void addWonCat(String name, int cost) {
    catsWon.addCat(name, cost);
  }

  /// 獲得したにゃんこを削除する（犬の効果などで使用）
  void removeWonCat(String name) {
    final beforeCount = catsWon.count;
    catsWon.removeByName(name);
    final afterCount = catsWon.count;

    // 実際に削除された場合、漁師ならカウントを減らす
    if (beforeCount > afterCount && name == GameConstants.fisherman) {
      fishermanCount = (fishermanCount - 1).clamp(0, 99);
    }
  }

  /// 現在の賭け金を支払い、リソースを消費する
  void payCosts() {
    fishCount -= currentBets.total;

    // アイテムを消費する
    for (int i = 0; i < 3; i++) {
      final item = currentBets.getItem(i.toString());
      if (item != null) {
        // アイテム使用時はスロットから削除
        items.consume(item);
      }
    }
  }

  /// 次のターンのために状態をリセットし、残りのさかなを算出する
  void resetRoundState() {
    currentBets = Bets.empty();
    ready = false;
    diceRoll = null;
    rolled = false;
    confirmedRoll = false;
    pendingItemRevivals = 0;
    pendingDogChases = 0;
    confirmedFatCatEvent = false;
  }
}
