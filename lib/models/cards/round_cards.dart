import 'dart:math';

import 'game_card.dart';
import 'regular_cat.dart';
import 'item_shop.dart';
import 'boss_cat.dart';

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

  /// Firestore復元用
  factory RoundCards.fromMap(Map<String, dynamic> map) {
    return RoundCards(
      card1: GameCard.fromMap(map['card1'] as Map<String, dynamic>),
      card2: GameCard.fromMap(map['card2'] as Map<String, dynamic>),
      card3: GameCard.fromMap(map['card3'] as Map<String, dynamic>),
    );
  }

  /// ランダムなカードを生成するヘルパー
  static GameCard _randomCard(int index) {
    final rand = Random().nextDouble();
    // 50%の確率でボスねこが出現（テスト用）
    if (rand < 0.5) {
      return BossCat.random(index);
    }
    // 10%の確率でアイテム屋が出現
    if (rand < 0.6) {
      return ItemShop.random(index);
    }
    return RegularCat.random(index);
  }

  /// ランダムなカード3枚を生成する
  factory RoundCards.random() {
    return RoundCards(
      card1: _randomCard(1),
      card2: _randomCard(2),
      card3: _randomCard(3),
    );
  }
}
