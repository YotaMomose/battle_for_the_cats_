import 'dart:math';

import '../../constants/game_constants.dart';
import 'game_card.dart';
import 'card_type.dart';
import 'card_effect.dart';

/// アイテム屋カード
/// 獲得時に使用済みアイテムを1つ復活させる
class ItemShop implements GameCard {
  @override
  final String id;

  @override
  final String displayName;

  /// このインスタンスのコスト（作成時に1-4で決定される）
  @override
  final int baseCost;

  @override
  final CardType cardType = CardType.itemShop;

  @override
  final CardEffect effect = CardEffect.itemShopEffect;

  /// ItemShop のコンストラクタ
  const ItemShop({
    required this.id,
    required this.displayName,
    required this.baseCost,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'baseCost': baseCost,
      'cardType': cardType.value,
      'effect': effect.value,
    };
  }

  /// Firestore から復元
  factory ItemShop.fromMap(Map<String, dynamic> map) {
    return ItemShop(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'アイテム屋',
      baseCost: map['baseCost'] ?? 1,
    );
  }

  /// ランダムなアイテム屋を生成する
  /// [index]: 生成順序（IDに含める）
  factory ItemShop.random(int index) {
    final random = Random();
    // アイテム屋は1-4のランダムコスト
    final cost = random.nextInt(GameConstants.maxCatCost) + 1;

    return ItemShop(
      id: 'item_shop_${DateTime.now().millisecondsSinceEpoch}_$index',
      displayName: 'アイテム屋',
      baseCost: cost,
    );
  }
}
