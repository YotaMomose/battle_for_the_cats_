import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/battle_evaluator.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';
import 'package:battle_for_the_cats/models/cards/regular_cat.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/bets.dart';
import 'package:battle_for_the_cats/models/item.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';

void main() {
  late BattleEvaluator evaluator;

  setUp(() {
    evaluator = BattleEvaluator();
  });

  Player createPlayer(
    String id,
    Map<String, int> bets, [
    Map<String, ItemType?>? items,
  ]) {
    return Player(id: id, currentBets: Bets(bets, items));
  }

  RoundCards createRound(int cost0, int cost1, int cost2) {
    return RoundCards(
      card1: RegularCat(id: '0', displayName: 'Cat0', baseCost: cost0),
      card2: RegularCat(id: '1', displayName: 'Cat1', baseCost: cost1),
      card3: RegularCat(id: '2', displayName: 'Cat2', baseCost: cost2),
    );
  }

  group('BattleEvaluator Basic Logic', () {
    test('Host wins when betting more than cost and more than guest', () {
      final round = createRound(2, 2, 2);
      final host = createPlayer('host', {'0': 3, '1': 0, '2': 0});
      final guest = createPlayer('guest', {'0': 1, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.host);
    });

    test('Guest wins when betting more than cost and more than host', () {
      final round = createRound(2, 2, 2);
      final host = createPlayer('host', {'0': 1, '1': 0, '2': 0});
      final guest = createPlayer('guest', {'0': 3, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.guest);
    });

    test('Draw when both bet same amount above cost', () {
      final round = createRound(2, 2, 2);
      final host = createPlayer('host', {'0': 3, '1': 0, '2': 0});
      final guest = createPlayer('guest', {'0': 3, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw);
    });

    test('Draw when both bet below cost', () {
      final round = createRound(3, 2, 2);
      final host = createPlayer('host', {'0': 2, '1': 0, '2': 0});
      final guest = createPlayer('guest', {'0': 1, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw);
    });
  });

  group('BattleEvaluator Items', () {
    test('Lucky Cat doubles the required cost', () {
      final round = createRound(2, 2, 2);
      // Cost is 2. Lucky Cat makes it 4.
      // Host bets 3, which is enough for base but not for doubled cost.
      final host = createPlayer(
        'host',
        {'0': 3, '1': 0, '2': 0},
        {'0': ItemType.luckyCat},
      );
      final guest = createPlayer('guest', {'0': 0, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw, reason: '3 < 4, so draw');
    });

    test('Surprise Horn invalidates all fish bets', () {
      final round = createRound(1, 1, 1);
      // Both bet enough, but guest uses Surprise Horn.
      final host = createPlayer('host', {'0': 5, '1': 0, '2': 0});
      final guest = createPlayer(
        'guest',
        {'0': 3, '1': 0, '2': 0},
        {'0': ItemType.surpriseHorn},
      );

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw, reason: 'Both bets become 0');
    });

    test('Cat Teaser wins automatically if opponent bets 0', () {
      final round = createRound(5, 5, 5);
      // Cost is 5. Host bets 0 but uses Cat Teaser.
      final host = createPlayer(
        'host',
        {'0': 0, '1': 0, '2': 0},
        {'0': ItemType.catTeaser},
      );
      final guest = createPlayer('guest', {'0': 0, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.host);
    });

    test('Cat Teaser does NOT win if opponent bets > 0', () {
      final round = createRound(5, 5, 5);
      // Guest bets 1, invalidating Cat Teaser automatic win.
      // But neither reaches cost 5.
      final host = createPlayer(
        'host',
        {'0': 0, '1': 0, '2': 0},
        {'0': ItemType.catTeaser},
      );
      final guest = createPlayer('guest', {'0': 1, '1': 0, '2': 0});

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw);
    });

    test('Both use Cat Teaser and both bet 0 results in draw', () {
      final round = createRound(1, 1, 1);
      final host = createPlayer(
        'host',
        {'0': 0, '1': 0, '2': 0},
        {'0': ItemType.catTeaser},
      );
      final guest = createPlayer(
        'guest',
        {'0': 0, '1': 0, '2': 0},
        {'0': ItemType.catTeaser},
      );

      final result = evaluator.evaluate(round, host, guest);

      expect(result.at(0), Winner.draw);
    });
  });
}
