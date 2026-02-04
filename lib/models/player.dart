import '../models/bets.dart';
import 'cat_inventory.dart';
import 'item_inventory.dart';
import '../domain/dice.dart';
import '../models/item.dart';

/// Playerモデル
/// プレイヤー（ホストまたはゲスト）の状態を保持するデータモデル
class Player {
  final String id;
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

  Player({
    required this.id,
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
  }) : catsWon = catsWon ?? CatInventory(),
       currentBets = currentBets ?? Bets(),
       items = items ?? ItemInventory.initial();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
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
    );
  }

  // ===== Domain Methods =====

  /// 獲得した全猫の合計コスト
  int get totalWonCatCost => catsWon.totalCost;

  /// 獲得した猫の名前リスト
  List<String> get wonCatNames => catsWon.names;

  /// 魚を増やす
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
    addFish(value);
  }

  /// 賭けとアイテムを設定する
  void placeBetsWithItems(
    Map<String, int> bets,
    Map<String, ItemType?> itemPlacements,
  ) {
    currentBets = Bets(bets, itemPlacements);
    ready = true;
  }

  /// 獲得した猫を記録する
  void addWonCat(String name, int cost) {
    catsWon.addCat(name, cost);
  }

  /// 現在の賭け金を支払い、リソースを消費する
  void payBets() {
    fishCount -= currentBets.total;

    // アイテムを消費する
    for (int i = 0; i < 3; i++) {
      final item = currentBets.getItem(i.toString());
      if (item != null) {
        items.consume(item);
      }
    }
  }

  /// 次のターンのために状態をリセットし、残りの魚を算出する
  void prepareForNextTurn() {
    payBets();
    currentBets = Bets.empty();
    ready = false;
    diceRoll = null;
    rolled = false;
    confirmedRoll = false;
  }
}
