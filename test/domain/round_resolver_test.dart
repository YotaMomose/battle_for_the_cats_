import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/round_resolver.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';

class MockRandom extends Fake implements Random {
  double nextDoubleValue = 0.0;
  @override
  double nextDouble() => nextDoubleValue;
}

void main() {
  group('RoundResolver - 遷移ロジックテスト', () {
    late RoundResolver resolver;
    late GameRoom room;
    late MockRandom mockRandom;

    setUp(() {
      mockRandom = MockRandom();
      resolver = RoundResolver(random: mockRandom);
      room = GameRoom(
        roomId: 'test',
        host: Player(id: 'h'),
        guest: Player(id: 'g'),
      );
      room.status = GameStatus.roundResult;
    });

    test('advanceFromRoundResult - 両者が承認していない場合は何もしない', () {
      room.host.confirmedRoundResult = true;
      room.guest?.confirmedRoundResult = false;

      resolver.advanceFromRoundResult(room);

      expect(room.status, GameStatus.roundResult);
    });

    test('advanceFromRoundResult - 確率に基づき通常遷移する', () {
      room.host.confirmedRoundResult = true;
      room.guest?.confirmedRoundResult = true;
      mockRandom.nextDoubleValue = 0.6; // 確率(0.5)より大きい

      resolver.advanceFromRoundResult(room);

      expect(room.status, GameStatus.rolling);
      expect(room.currentTurn, 2);
    });

    test('advanceFromRoundResult - 確率に基づき太っちょネコイベントが発生する', () {
      room.host.confirmedRoundResult = true;
      room.guest?.confirmedRoundResult = true;
      room.host.fishCount = 10;
      room.guest?.fishCount = 5;
      mockRandom.nextDoubleValue = 0.4; // 確率(0.5)より小さい

      resolver.advanceFromRoundResult(room);

      expect(room.status, GameStatus.fatCatEvent);
      expect(room.host.fishCount, 0);
      expect(room.guest?.fishCount, 0);
    });

    test('advanceFromFatCatEvent - 両者が承認したら次のターンへ進む', () {
      room.status = GameStatus.fatCatEvent;
      room.host.confirmedFatCatEvent = true;
      room.guest?.confirmedFatCatEvent = true;

      resolver.advanceFromFatCatEvent(room);

      expect(room.status, GameStatus.rolling);
      expect(room.currentTurn, 2);
    });
  });
}
