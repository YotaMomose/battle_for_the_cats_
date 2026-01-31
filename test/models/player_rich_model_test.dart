import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/bets.dart';

void main() {
  group('Player Rich Domain Model Tests', () {
    test('addFish should increment fishCount', () {
      final player = Player(id: 'p1', fishCount: 10);
      player.addFish(5);
      expect(player.fishCount, 15);
    });

    test('recordDiceRoll should set values and add fish', () {
      final player = Player(id: 'p1', fishCount: 10);
      player.recordDiceRoll(4);
      expect(player.diceRoll, 4);
      expect(player.rolled, isTrue);
      expect(player.fishCount, 14);
    });

    test('placeBets should set currentBets and ready flag', () {
      final player = Player(id: 'p1');
      final betsMap = {'0': 2, '1': 3, '2': 0};
      player.placeBets(betsMap);
      expect(player.currentBets, Bets(betsMap));
      expect(player.ready, isTrue);
    });

    test('addWonCat should add to catsWon list', () {
      final player = Player(id: 'p1');
      player.addWonCat('Mike', 3);
      expect(player.catsWon.count, 1);
      expect(player.catsWon.all.first.name, 'Mike');
      expect(player.catsWon.all.first.cost, 3);
      expect(player.totalWonCatCost, 3);
    });

    test('prepareForNextTurn should reset flags and subtract bets', () {
      final player = Player(id: 'p1', fishCount: 10);
      player.recordDiceRoll(2); // fishCount: 12
      player.placeBets({'0': 5, '1': 2, '2': 0}); // totalBet: 7
      player.confirmedRoll = true;
      player.confirmedRoundResult = true;

      player.prepareForNextTurn();

      expect(player.fishCount, 5); // 12 - 7
      expect(player.currentBets, Bets.empty());
      expect(player.ready, isFalse);
      expect(player.diceRoll, isNull);
      expect(player.rolled, isFalse);
      expect(player.confirmedRoll, isFalse);
      expect(player.confirmedRoundResult, isTrue);
    });
  });
}
