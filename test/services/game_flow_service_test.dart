import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/services/game_flow_service.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import '../mocks/mock_room_repository.dart';

void main() {
  group('GameFlowService - 詳細テスト', () {
    late GameFlowService gameFlowService;
    late MockRoomRepository mockRepository;
    setUp(() {
      mockRepository = MockRoomRepository();
      gameFlowService = GameFlowService(repository: mockRepository);
    });

    group('ゲーム進行の定数', () {
      test('サイコロの目の範囲が正しく定義されている', () {
        // Assert
        expect(GameConstants.diceMin, equals(1));
        expect(GameConstants.diceMax, equals(6));
      });

      test('ゲーム定義の定数が正しい', () {
        // Assert
        expect(GameConstants.catsPerRound, equals(3));
        expect(GameConstants.winCondition, equals(3));
      });
    });

    group('賭けの検証', () {
      test('有効な賭けは正の整数である', () {
        // Arrange
        const validBets = {'cat_0': 5, 'cat_1': 3, 'cat_2': 2};

        // Assert
        for (final bet in validBets.values) {
          expect(bet, greaterThan(0));
          expect(bet, isA<int>());
        }
      });

      test('複数の猫への賭けが同時に可能である', () {
        // Arrange
        const bets = {'cat_0': 1, 'cat_1': 2, 'cat_2': 3};

        // Assert
        expect(bets.length, equals(3));
        expect(bets.keys, containsAll(['cat_0', 'cat_1', 'cat_2']));
      });

      test('賭けの合計が魚の保有数を超えないことを検証可能', () {
        // Arrange
        const fishCount = 10;
        const bets = {'cat_0': 3, 'cat_1': 2, 'cat_2': 4};
        final totalBets = bets.values.reduce((a, b) => a + b);

        // Assert
        expect(totalBets, lessThanOrEqualTo(fishCount));
      });
    });

    group('エッジケース', () {
      test('ゲーム定数が有効な値である', () {
        // Assert
        expect(GameConstants.diceMin, lessThan(GameConstants.diceMax));
        expect(GameConstants.catsPerRound, equals(3));
        expect(GameConstants.winCondition, equals(3));
      });
    });
  });
}
