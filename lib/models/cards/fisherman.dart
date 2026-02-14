import 'dart:math';

import '../../constants/game_constants.dart';
import 'game_card.dart';
import 'card_type.dart';
import 'card_effect.dart';

/// 漁師カード
/// 獲得するとサイコロの出目にボーナス魚が加算される（永続効果）
class Fisherman implements GameCard {
  @override
  final String id;

  @override
  final String displayName;

  /// このインスタンスのコスト（作成時に1-4で決定される）
  @override
  final int baseCost;

  @override
  final CardType cardType = CardType.fisherman;

  @override
  final CardEffect effect = CardEffect.fishermanEffect;

  /// Fisherman のコンストラクタ
  const Fisherman({
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
  factory Fisherman.fromMap(Map<String, dynamic> map) {
    return Fisherman(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '漁師',
      baseCost: map['baseCost'] ?? 1,
    );
  }

  /// ランダムな漁師を生成する
  /// [index]: 生成順序（IDに含める）
  factory Fisherman.random(int index) {
    final random = Random();
    // 漁師は1-4のランダムコスト
    final cost = random.nextInt(GameConstants.maxCatCost) + 1;

    return Fisherman(
      id: 'fisherman_${DateTime.now().millisecondsSinceEpoch}_$index',
      displayName: '漁師',
      baseCost: cost,
    );
  }
}
