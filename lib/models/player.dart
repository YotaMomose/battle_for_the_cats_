/// Playerモデル
/// プレイヤー（ホストまたはゲスト）の状態を保持するデータモデル
class Player {
  final String id;
  int fishCount;
  List<String> catsWon;
  List<int> wonCatCosts;
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
    List<String>? catsWon,
    List<int>? wonCatCosts,
    this.diceRoll,
    this.rolled = false,
    this.confirmedRoll = false,
    this.confirmedRoundResult = false,
    Map<String, int>? currentBets,
    this.ready = false,
    this.abandoned = false,
  }) : catsWon = catsWon ?? [],
       wonCatCosts = wonCatCosts ?? [],
       currentBets = currentBets ?? {'0': 0, '1': 0, '2': 0};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fishCount': fishCount,
      'catsWon': catsWon,
      'wonCatCosts': wonCatCosts,
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
      catsWon: List<String>.from(map['catsWon'] ?? []),
      wonCatCosts: List<int>.from(map['wonCatCosts'] ?? []),
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

  /// 魚を増やす
  void addFish(int amount) {
    fishCount += amount;
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
    catsWon.add(name);
    wonCatCosts.add(cost);
  }

  /// 次のターンのために状態をリセットし、残りの魚を算出する
  void prepareForNextTurn() {
    final totalBet = currentBets.values.fold(0, (a, b) => a + b);
    fishCount -= totalBet;
    currentBets = {'0': 0, '1': 0, '2': 0};
    ready = false;
    diceRoll = null;
    rolled = false;
    confirmedRoll = false;
    confirmedRoundResult = false;
  }
}
