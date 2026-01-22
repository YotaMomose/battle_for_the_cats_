import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';
import 'package:battle_for_the_cats/models/cards/regular_cat.dart';

void main() {
  group('GameRoom Rich Domain Model Tests', () {
    late GameRoom room;

    setUp(() {
      room = GameRoom(
        roomId: 'test',
        host: Player(id: 'h'),
        guest: Player(id: 'g'),
      );
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
      room.host.placeBets({'0': 2, '1': 0, '2': 0});
      room.guest?.placeBets({'0': 0, '1': 3, '2': 0});

      room.resolveRound();

      expect(room.host.catsWon, contains('Cat1'));
      expect(room.guest?.catsWon, contains('Cat2'));
      expect(room.status, GameStatus.roundResult);
      expect(room.lastRoundWinners, isNotNull);
      expect(room.host.confirmedRoundResult, isFalse);
      expect(room.guest?.confirmedRoundResult, isFalse);
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
