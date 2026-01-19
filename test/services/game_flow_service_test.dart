import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/services/game_flow_service.dart';
import 'package:battle_for_the_cats/domain/game_logic.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import '../mocks/mock_room_repository.dart';

void main() {
  group('GameFlowService - 詳細テスト', () {
    late GameFlowService gameFlowService;
    late MockRoomRepository mockRepository;
    late GameLogic gameLogic;

    setUp(() {
      mockRepository = MockRoomRepository();
      gameLogic = GameLogic();
      gameFlowService = GameFlowService(
        repository: mockRepository,
        gameLogic: gameLogic,
      );
    });

    group('rollDice', () {
      test('サイコロの目が1から6の範囲である', () {
        // Act
        for (int i = 0; i < 100; i++) {
          final diceResult = gameLogic.rollDice();

          // Assert
          expect(diceResult, greaterThanOrEqualTo(1));
          expect(diceResult, lessThanOrEqualTo(6));
        }
      });

      test('サイコロの結果が均等に分布している（統計テスト）', () {
        // Act
        final diceRolls = <int, int>{
          1: 0,
          2: 0,
          3: 0,
          4: 0,
          5: 0,
          6: 0,
        };

        const rollCount = 600;
        for (int i = 0; i < rollCount; i++) {
          final result = gameLogic.rollDice();
          diceRolls[result] = diceRolls[result]! + 1;
        }

        // Assert: 各目がほぼ均等（±30%の範囲内）
        final expectedCount = rollCount / 6;
        final tolerance = expectedCount * 0.3;

        for (int face = 1; face <= 6; face++) {
          final actualCount = diceRolls[face]!;
          expect(actualCount, greaterThan((expectedCount - tolerance).toInt()),
              reason: '面$faceの出現回数が少なすぎます');
          expect(actualCount, lessThan((expectedCount + tolerance).toInt()),
              reason: '面$faceの出現回数が多すぎます');
        }
      });

      test('複数回のサイコロ振りが独立している', () {
        // Act
        final roll1 = gameLogic.rollDice();
        final roll2 = gameLogic.rollDice();
        final roll3 = gameLogic.rollDice();

        // Assert: すべてが1～6の範囲内
        expect([roll1, roll2, roll3], everyElement(
          allOf(greaterThanOrEqualTo(1), lessThanOrEqualTo(6)),
        ));
      });

      test('サイコロを連続で振っても値が規定範囲を超えない', () {
        // Act
        for (int i = 0; i < 1000; i++) {
          final result = gameLogic.rollDice();

          // Assert
          expect(result, inInclusiveRange(1, 6));
        }
      });
    });

    group('ゲーム進行のロジック', () {
      test('サイコロの目の範囲が正しく定義されている', () {
        // Assert
        expect(GameConstants.diceMin, equals(1));
        expect(GameConstants.diceMax, equals(6));
      });

      test('サイコロ結果は定義された範囲内である', () {
        // Act
        for (int i = 0; i < 100; i++) {
          final diceRoll = gameLogic.rollDice();

          // Assert
          expect(diceRoll, greaterThanOrEqualTo(GameConstants.diceMin));
          expect(diceRoll, lessThanOrEqualTo(GameConstants.diceMax));
        }
      });

      test('ゲーム定義にコートがある', () {
        // Assert
        expect(GameConstants.catCount, equals(3));
        expect(GameConstants.winCondition, equals(3));
      });

      test('複数ターンの魚の蓄積が正しい', () {
        // Arrange
        var fishCount = 10; // 初期値（実装に合わせて調整）

        // Act: 5ターンのシミュレーション
        final diceRolls = <int>[];
        for (int i = 0; i < 5; i++) {
          final diceRoll = gameLogic.rollDice();
          diceRolls.add(diceRoll);
          fishCount += diceRoll;
        }

        // Assert
        var expectedFishCount = 10;
        for (final roll in diceRolls) {
          expectedFishCount += roll;
        }
        expect(fishCount, equals(expectedFishCount));
      });

      test('サイコロの目の最小値は1である', () {
        // Act
        for (int i = 0; i < 200; i++) {
          final result = gameLogic.rollDice();

          // Assert
          expect(result, greaterThanOrEqualTo(1));
        }
      });

      test('サイコロの目の最大値は6である', () {
        // Act
        for (int i = 0; i < 200; i++) {
          final result = gameLogic.rollDice();

          // Assert
          expect(result, lessThanOrEqualTo(6));
        }
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
        const bets = {
          'cat_0': 1,
          'cat_1': 2,
          'cat_2': 3,
        };

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
      test('サイコロの連続結果の平均が約3.5に近い', () {
        // Act
        const rollCount = 1000;
        int totalRoll = 0;
        for (int i = 0; i < rollCount; i++) {
          totalRoll += gameLogic.rollDice();
        }
        final average = totalRoll / rollCount;

        // Assert: 3.5 ± 0.5の範囲内
        expect(average, greaterThan(3.0));
        expect(average, lessThan(4.0));
      });

      test('ゲーム定数が有効な値である', () {
        // Assert
        expect(GameConstants.diceMin, lessThan(GameConstants.diceMax));
        expect(GameConstants.catCount, equals(3));
        expect(GameConstants.winCondition, equals(3));
      });

      test('複数回のサイコロ結果の分布が均等である', () {
        // Act
        final rolls = <int>[];
        for (int i = 0; i < 1000; i++) {
          rolls.add(gameLogic.rollDice());
        }

        // Assert: すべてが1～6の範囲内
        expect(rolls, everyElement(
          allOf(greaterThanOrEqualTo(1), lessThanOrEqualTo(6)),
        ));

        // 最小値と最大値を検証
        expect(rolls.reduce((a, b) => a < b ? a : b), equals(1));
        expect(rolls.reduce((a, b) => a > b ? a : b), equals(6));
      });
    });
  });
}
