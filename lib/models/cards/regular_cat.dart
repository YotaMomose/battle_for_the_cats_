import 'dart:math';

import '../player.dart';

import '../../constants/game_constants.dart';
import 'game_card.dart';
import 'card_type.dart';
import 'card_effect.dart';

/// 通常の猫カード
/// 場に出るときにコスト（1-4の魚が必要）がランダムに決定される
final class RegularCat implements GameCard {
  @override
  final String id;

  @override
  final String displayName;

  /// このインスタンスのコスト（作成時に1-4で決定される）
  @override
  final int baseCost;

  @override
  final CardType cardType = CardType.regularCat;

  @override
  final CardEffect effect = CardEffect.none;

  /// RegularCat のコンストラクタ
  /// [id]: このカード固有のID（例: 'round_1_cat_0'）
  /// [displayName]: 表示名（例: '茶トラねこ', '白ねこ'）
  /// [baseCost]: このカードを獲得するのに必要な魚の数（1-4）
  const RegularCat({
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
  factory RegularCat.fromMap(Map<String, dynamic> map) {
    return RegularCat(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '通常ネコ',
      baseCost: map['baseCost'] ?? 1,
    );
  }

  /// ランダムな猫を生成する
  /// [index]: 生成順序（IDに含める）
  factory RegularCat.random(int index) {
    final random = Random();
    final catType =
        GameConstants.catTypes[random.nextInt(GameConstants.catTypes.length)];
    final cost = random.nextInt(GameConstants.maxCatCost) + 1;

    return RegularCat(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}_$index',
      displayName: catType,
      baseCost: cost,
    );
  }

  @override
  void applyAcquisitionEffect(Player player) {
    // 通常の猫には獲得時の特殊効果はない
  }
}
