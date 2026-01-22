import 'card_type.dart';
import 'card_effect.dart';
import 'regular_cat.dart';

/// ゲーム内の全カード（猫、犬、漁師など）が実装すべきインターフェース
abstract class GameCard {
  /// カードの一意なID
  String get id;

  /// 画面表示用の名前
  String get displayName;

  /// カードのタイプ（ネコ、犬など）
  CardType get cardType;

  /// 特殊効果
  CardEffect get effect;

  /// このカードを獲得するのに必要な魚の数
  /// 通常ネコは1-4のランダム、特殊カードは固定値
  int get baseCost;

  /// Firestore保存用のMap化
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'cardType': cardType.value,
      'effect': effect.value,
      'baseCost': baseCost,
    };
  }

  /// Firestore復元用のファクトリコンストラクタ
  static GameCard fromMap(Map<String, dynamic> map) {
    final type = map['cardType'] as String?;
    if (type == CardType.regularCat.value) {
      return RegularCat.fromMap(map);
    }
    // 将来的に他のカードタイプが追加されたらここに分岐を追加
    return RegularCat.fromMap(map);
  }
}
