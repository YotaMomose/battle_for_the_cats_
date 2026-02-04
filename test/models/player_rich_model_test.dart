import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/bets.dart';
import 'package:battle_for_the_cats/models/item.dart';

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

    test('placeBetsWithItems should set currentBets and ready flag', () {
      final player = Player(id: 'p1');
      final betsMap = {'0': 2, '1': 3, '2': 0};
      final itemMap = {'0': null, '1': null, '2': null};
      player.placeBetsWithItems(betsMap, itemMap);
      expect(player.currentBets.getBet('0'), 2);
      expect(player.ready, isTrue);
    });

    test('addWonCat should add to catsWon list', () {
      final player = Player(id: 'p1');
      player.addWonCat('茶トラねこ', 3);
      expect(player.catsWon.count, 1);
      expect(player.catsWon.all.first.name, '茶トラねこ');
      expect(player.catsWon.all.first.cost, 3);
    });

    test('prepareForNextTurn should reset flags and subtract bets', () {
      final player = Player(id: 'p1', fishCount: 10);
      player.recordDiceRoll(2); // fishCount: 12
      player.placeBetsWithItems(
        {'0': 5, '1': 2, '2': 0},
        {'0': null, '1': null, '2': null},
      ); // totalBet: 7
      player.confirmedRoll = true;
      player.confirmedRoundResult = true;

      player.prepareForNextTurn();

      expect(player.fishCount, 5); // 12 - 7
      expect(player.currentBets, Bets.empty());
      expect(player.ready, isFalse);
      expect(player.diceRoll, isNull);
      expect(player.rolled, isFalse);
      expect(player.confirmedRoll, isFalse);
    });

    test('prepareForNextTurn should consume used items from inventory', () {
      final player = Player(id: 'p1'); // Initial inventory has 1 catTeaser
      expect(player.items.count(ItemType.catTeaser), 1);

      player.placeBetsWithItems(
        {'0': 0, '1': 0, '2': 0},
        {'0': ItemType.catTeaser, '1': null, '2': null},
      );

      player.prepareForNextTurn();

      expect(player.items.count(ItemType.catTeaser), 0);
    });
  });
}
