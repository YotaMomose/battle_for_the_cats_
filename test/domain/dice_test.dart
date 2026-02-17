import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/dice.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'dart:math';

/// テスト用の偽サイコロ
class FakeDice extends Fake implements Dice {
  int value = 1;

  @override
  int roll() => value;
}

void main() {
  group('StandardDice Tests', () {
    test('StandardDice should return values between diceMin and diceMax', () {
      final dice = StandardDice();
      for (var i = 0; i < 100; i++) {
        final result = dice.roll();
        expect(result, greaterThanOrEqualTo(GameConstants.diceMin));
        expect(result, lessThanOrEqualTo(GameConstants.diceMax));
      }
    });

    test('StandardDice should be reproducible with a seeded Random', () {
      const seed = 42;
      final dice1 = StandardDice(random: Random(seed));
      final dice2 = StandardDice(random: Random(seed));

      for (var i = 0; i < 10; i++) {
        expect(dice1.roll(), equals(dice2.roll()));
      }
    });

    test('StandardDice distribution - all values should eventually appear', () {
      final dice = StandardDice();
      final seenValues = <int>{};

      // 1000回振れば通常は1-6すべて出るはず
      for (var i = 0; i < 1000; i++) {
        seenValues.add(dice.roll());
      }

      expect(
        seenValues.length,
        equals(GameConstants.diceMax - GameConstants.diceMin + 1),
      );
      for (var v = GameConstants.diceMin; v <= GameConstants.diceMax; v++) {
        expect(seenValues, contains(v));
      }
    });
  });

  group('Dice Player Integration Tests', () {
    test('Player should record dice roll and gain fish', () {
      final fakeDice = FakeDice();
      fakeDice.value = 4;

      final player = Player(id: 'test_player', fishCount: 0);

      // 初期状態
      expect(player.rolled, isFalse);
      expect(player.diceRoll, isNull);

      // サイコロを振る
      player.roll(fakeDice);

      // 結果の検証
      expect(player.rolled, isTrue);
      expect(player.diceRoll, equals(4));
      // 魚の獲得: サイコロの目(4) + 漁師の数(初期0) = 4
      expect(player.fishCount, equals(4));
    });

    test('Player should benefit from fisherman bonus when rolling', () {
      final fakeDice = FakeDice();
      fakeDice.value = 3;

      // 漁師を1人持っている状態を模倣（直接プロパティがない場合はaddWonCatなどで調整が必要だが、
      // PlayerData. FishermanCount がどこから来るか確認が必要。
      // Playerクラスには直接 fishermanCount （計算プロパティ）があるはず。
      final player = Player(id: 'test_player', fishCount: 10);
      // catsWon に漁師を追加
      player.addWonCat(GameConstants.fisherman, 1);

      player.roll(fakeDice);

      expect(player.diceRoll, equals(3));
      // 魚の獲得: 3 + 1(漁師) = 4. 合計: 10 + 4 = 14
      expect(player.fishCount, equals(14));
    });
  });
}
