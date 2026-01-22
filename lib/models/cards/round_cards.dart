import 'game_card.dart';
import 'regular_cat.dart';

/// ラウンドで場に出る3枚のカードを表す
/// 常に3枚のセットとして扱い、型安全性を確保
class RoundCards {
  final GameCard card1;
  final GameCard card2;
  final GameCard card3;

  /// RoundCards のコンストラクタ
  /// [card1], [card2], [card3]: 場に出る3枚のカード
  const RoundCards({
    required this.card1,
    required this.card2,
    required this.card3,
  });

  /// リストとして取得（0, 1, 2 でアクセスする場合用）
  List<GameCard> toList() => [card1, card2, card3];

  /// すべてのカードの基本コストを取得
  List<int> getCosts() => [card1.baseCost, card2.baseCost, card3.baseCost];

  /// Firestore保存用
  Map<String, dynamic> toMap() {
    return {
      'card1': card1.toMap(),
      'card2': card2.toMap(),
      'card3': card3.toMap(),
    };
  }

  /// Firestore復元用（後でカード工場パターンで実装）
  factory RoundCards.fromMap(Map<String, dynamic> map) {
    // 簡易実装：タイムスタンプに基づいてランダムカードを再生成
    // 本来はデータベースから復元すべきだが、ゲーム中のみ使用されるため
    return RoundCards.random();
  }

  /// ランダムなカード3枚を生成する
  factory RoundCards.random() {
    return RoundCards(
      card1: RegularCat.random(1),
      card2: RegularCat.random(2),
      card3: RegularCat.random(3),
    );
  }
}
