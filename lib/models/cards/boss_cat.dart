import 'dart:math';

import '../player.dart';

import '../../constants/game_constants.dart';
import 'game_card.dart';
import 'card_type.dart';
import 'card_effect.dart';

/// ボスねこカード
/// 通常ネコの効果（勝利条件への寄与）とアイテム屋の効果（アイテム復活）を併せ持つ
class BossCat implements GameCard {
  @override
  final String id;

  @override
  final String displayName;

  @override
  final int baseCost;

  @override
  final CardType cardType = CardType.bossKitty;

  @override
  final CardEffect effect = CardEffect.bossEffect;

  const BossCat({
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

  factory BossCat.fromMap(Map<String, dynamic> map) {
    return BossCat(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'ボスねこ',
      baseCost: map['baseCost'] ?? 3,
    );
  }

  /// ランダムなボスねこを生成する
  /// [index]: 生成順序（IDに含める）
  factory BossCat.random(int index) {
    final random = Random();
    // 3種類のボスタイプからランダムに選択
    final bossType = GameConstants
        .bossCatTypes[random.nextInt(GameConstants.bossCatTypes.length)];
    // テスト用にコストは3-4
    final cost = random.nextInt(2) + 3;

    return BossCat(
      id: 'boss_${DateTime.now().millisecondsSinceEpoch}_$index',
      displayName: bossType,
      baseCost: cost,
    );
  }

  @override
  void applyAcquisitionEffect(Player player) {
    player.pendingItemRevivals++;
  }
}
