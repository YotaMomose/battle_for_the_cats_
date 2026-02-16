import 'dart:math';
import '../../constants/game_constants.dart';
import 'game_card.dart';
import 'card_type.dart';
import 'card_effect.dart';

/// キャラクター「犬」
/// 獲得した場合、そのターンで獲得したネコを含めた相手のキャラクターを1匹逃がすことができる。
class Dog implements GameCard {
  @override
  final String id;

  @override
  final String displayName;

  @override
  final int baseCost;

  @override
  final CardType cardType = CardType.dog;

  @override
  final CardEffect effect = CardEffect.dogEffect;

  Dog({required this.id, required this.displayName, required this.baseCost});

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

  /// Firestoreから復元
  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? GameConstants.dog,
      baseCost: map['baseCost'] ?? 1,
    );
  }

  /// ランダムな犬を生成
  factory Dog.random(int index) {
    final random = Random();
    final cost = random.nextInt(4) + 1; // 1-4
    return Dog(
      id: 'dog_${DateTime.now().millisecondsSinceEpoch}_$index',
      displayName: GameConstants.dog,
      baseCost: cost,
    );
  }
}
