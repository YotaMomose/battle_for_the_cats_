import '../domain/dice.dart';
import 'won_cat.dart';

/// Playerモデル
/// プレイヤー（ホストまたはゲスト）の状態を保持するデータモデル
class Player {
  final String id;
  int fishCount;
  List<WonCat> catsWon;
  int? diceRoll;
  bool rolled;
  bool confirmedRoll;
  bool confirmedRoundResult;
  Map<String, int> currentBets;
  bool ready;
  bool abandoned;

  Player({
    required this.id,
    this.fishCount = 0,
    List<WonCat>? catsWon,
    this.diceRoll,
    this.rolled = false,
    this.confirmedRoll = false,
    this.confirmedRoundResult = false,
    Map<String, int>? currentBets,
    this.ready = false,
    this.abandoned = false,
  }) : catsWon = catsWon ?? [],
       currentBets = currentBets ?? {'0': 0, '1': 0, '2': 0};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fishCount': fishCount,
      'catsWon': catsWon.map((c) => c.toMap()).toList(),
      'diceRoll': diceRoll,
      'rolled': rolled,
      'confirmedRoll': confirmedRoll,
      'confirmedRoundResult': confirmedRoundResult,
      'currentBets': currentBets,
      'ready': ready,
      'abandoned': abandoned,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      fishCount: map['fishCount'] ?? 0,
      catsWon:
          (map['catsWon'] as List?)
              ?.map((c) => WonCat.fromMap(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
      diceRoll: map['diceRoll'],
      rolled: map['rolled'] ?? false,
      confirmedRoll: map['confirmedRoll'] ?? false,
      confirmedRoundResult: map['confirmedRoundResult'] ?? false,
      currentBets: Map<String, int>.from(
        map['currentBets'] ?? {'0': 0, '1': 0, '2': 0},
      ),
      ready: map['ready'] ?? false,
      abandoned: map['abandoned'] ?? false,
    );
  }

  // ===== Domain Methods =====

  /// 獲得した全猫の合計コスト
  int get totalWonCatCost => catsWon.fold(0, (sum, cat) => sum + cat.cost);

  /// 獲得した猫の名前リスト（後方互換性用、必要に応じて使用）
  List<String> get wonCatNames => catsWon.map((c) => c.name).toList();

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

  /// 賭けを設定する
  void placeBets(Map<String, int> bets) {
    currentBets = Map<String, int>.from(bets);
    ready = true;
  }

  /// 獲得した猫を記録する
  void addWonCat(String name, int cost) {
    catsWon.add(WonCat(name: name, cost: cost));
  }

  /// 現在の賭け金を支払い、リソースを消費する
  void payBets() {
    final totalBet = currentBets.values.fold(0, (a, b) => a + b);
    fishCount -= totalBet;
  }

  /// 次のターンのために状態をリセットし、残りの魚を算出する
  void prepareForNextTurn() {
    payBets();
    currentBets = {'0': 0, '1': 0, '2': 0};
    ready = false;
    diceRoll = null;
    rolled = false;
    confirmedRoll = false;
  }
}
