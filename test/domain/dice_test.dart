import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/dice.dart';
import 'package:battle_for_the_cats/domain/game_logic.dart';
import 'dart:math';

class MockDice implements Dice {
  int value = 1;
  @override
  int roll() => value;
}

void main() {
  group('StandardDice Tests', () {
    test('StandardDice should return values between 1 and 6', () {
      final dice = StandardDice();
      for (var i = 0; i < 100; i++) {
        final result = dice.roll();
        expect(result, greaterThanOrEqualTo(1));
        expect(result, lessThanOrEqualTo(6));
      }
    });

    test('StandardDice should use provided Random', () {
      final mockRandom = Random(42); // Seeded random
      final dice = StandardDice(random: mockRandom);
      final expected = Random(42).nextInt(6) + 1;
      expect(dice.roll(), expected);
    });
  });

  group('GameLogic Dice Integration Tests', () {
    test('GameLogic should use injected Dice', () {
      final mockDice = MockDice();
      mockDice.value = 5;
      final logic = GameLogic(dice: mockDice);

      expect(logic.rollDice(), 5);

      mockDice.value = 2;
      expect(logic.rollDice(), 2);
    });
  });
}
