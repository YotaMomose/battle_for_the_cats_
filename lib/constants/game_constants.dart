/// ゲーム全体で使用する定数
class GameConstants {
  // ルームコード
  static const int roomCodeLength = 6;
  static const String roomCodeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  // サイコロ
  static const int diceMin = 1;
  static const int diceMax = 6;

  // 猫の種類名
  static const String catOrange = '茶トラねこ';
  static const String catWhite = '白ねこ';
  static const String catBlack = '黒ねこ';
  static const String bossCatOrange = 'ボス茶トラねこ';
  static const String bossCatWhite = 'ボス白ねこ';
  static const String bossCatBlack = 'ボス黒ねこ';

  // 特殊カード名
  static const String fisherman = '漁師';
  static const String itemShop = 'アイテム屋';
  static const String dog = '犬';

  // ゲームルール
  static const int catsPerRound = 3; // 1ターンに登場する猫の数
  static const int maxCatCost = 4; // 猫のコストの最大値（1～4）
  static const int winCondition = 3; // 勝利に必要な猫の数
  static const List<String> catTypes = [catOrange, catWhite, catBlack];
  static const List<String> bossCatTypes = [
    bossCatOrange,
    bossCatWhite,
    bossCatBlack,
  ];

  // マッチング
  static const int matchmakingSearchLimit = 10; // マッチング検索数上限

  // イベント
  static const double fatCatEventProbability = 0.1; // 太っちょネコイベント発生確率

  // フレンド
  static const int maxFriendLimit = 50; // フレンドの上限数
}

/// ゲーム状態
enum GameStatus {
  waiting('waiting'),
  rolling('rolling'),
  playing('playing'),
  roundResult('roundResult'),
  fatCatEvent('fatCatEvent'),
  finished('finished');

  const GameStatus(this.value);
  final String value;

  static GameStatus fromString(String value) {
    return GameStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GameStatus.waiting,
    );
  }
}

/// マッチング状態
enum MatchmakingStatus {
  waiting('waiting'),
  matched('matched');

  const MatchmakingStatus(this.value);
  final String value;

  static MatchmakingStatus fromString(String value) {
    return MatchmakingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchmakingStatus.waiting,
    );
  }
}

/// 勝者
enum Winner {
  host('host'),
  guest('guest'),
  draw('draw');

  const Winner(this.value);
  final String value;

  static Winner fromString(String value) {
    return Winner.values.firstWhere(
      (winner) => winner.value == value,
      orElse: () => Winner.draw,
    );
  }
}
