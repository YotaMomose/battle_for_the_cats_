import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';
import 'package:battle_for_the_cats/models/cards/regular_cat.dart';
import 'package:battle_for_the_cats/domain/round_resolver.dart';

void main() {
  group('GameRoom Rich Domain Model Tests', () {
    late GameRoom room;
    late RoundResolver resolver;

    setUp(() {
      room = GameRoom(
        roomId: 'test',
        host: Player(id: 'h'),
        guest: Player(id: 'g'),
      );
      resolver = RoundResolver();
    });

    test('canStartRound should be true when both ready', () {
      expect(room.canStartRound, isFalse);
      room.host.ready = true;
      expect(room.canStartRound, isFalse);
      room.guest?.ready = true;
      expect(room.canStartRound, isTrue);
    });

    test('bothRolled should be true when both rolled', () {
      expect(room.bothRolled, isFalse);
      room.host.rolled = true;
      expect(room.bothRolled, isFalse);
      room.guest?.rolled = true;
      expect(room.bothRolled, isTrue);
    });

    test('resolveRound should update state correctly', () {
      final roundCards = RoundCards(
        card1: RegularCat(id: 'c1', displayName: 'Cat1', baseCost: 1),
        card2: RegularCat(id: 'c2', displayName: 'Cat2', baseCost: 2),
        card3: RegularCat(id: 'c3', displayName: 'Cat3', baseCost: 3),
      );
      room.currentRound = roundCards;
      room.host.placeBetsWithItems(
        {'0': 2, '1': 0, '2': 0},
        {'0': null, '1': null, '2': null},
      );
      room.guest?.placeBetsWithItems(
        {'0': 0, '1': 3, '2': 0},
        {'0': null, '1': null, '2': null},
      );

      resolver.resolve(room);

      expect(room.host.wonCatNames, contains('Cat1'));
      expect(room.guest?.wonCatNames, contains('Cat2'));
      expect(room.status, GameStatus.roundResult);
      expect(room.lastRoundResult?.winners, isNotNull);
      expect(room.host.confirmedRoundResult, isFalse);
      expect(room.guest?.confirmedRoundResult, isFalse);
    });

    test('confirmRoundResult should update individual flags', () {
      room.confirmRoundResult('h');
      expect(room.host.confirmedRoundResult, isTrue);
      expect(room.guest?.confirmedRoundResult, isFalse);

      room.confirmRoundResult('g');
      expect(room.guest?.confirmedRoundResult, isTrue);
    });

    test('triggerFatCatEvent should change status and clear fish', () {
      room.host.fishCount = 5;
      room.guest?.fishCount = 10;

      room.triggerFatCatEvent();

      expect(room.status, GameStatus.fatCatEvent);
      expect(room.host.fishCount, 0);
      expect(room.guest?.fishCount, 0);
    });

    test('confirmFatCatEvent should update individual flags', () {
      room.confirmFatCatEvent('h');
      expect(room.host.confirmedFatCatEvent, isTrue);
      expect(room.guest?.confirmedFatCatEvent, isFalse);

      room.confirmFatCatEvent('g');
      expect(room.guest?.confirmedFatCatEvent, isTrue);
    });

    test('prepareNextTurn should increment turn and reset players', () {
      room.currentTurn = 1;
      room.status = GameStatus.roundResult;
      room.host.rolled = true;

      final nextCards = RoundCards.random();
      room.prepareNextTurn(nextCards);

      expect(room.currentTurn, 2);
      expect(room.status, GameStatus.rolling);
      expect(room.host.rolled, isFalse);
      expect(room.currentRound, nextCards);
    });
  });
}
