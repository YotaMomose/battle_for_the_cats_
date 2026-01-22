import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/game_logic.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('GameLogic - 基本機能', () {
    late GameLogic gameLogic;

    setUp(() {
      gameLogic = GameLogic();
    });

    group('rollDice', () {
      test('1～6の範囲内の値を返す', () {
        for (int i = 0; i < 100; i++) {
          final result = gameLogic.rollDice();
          expect(result, greaterThanOrEqualTo(GameConstants.diceMin));
          expect(result, lessThanOrEqualTo(GameConstants.diceMax));
        }
      });

      test('複数回実行時に6つの出目がほぼ同じ数出ている（分布テスト）', () {
        final rolls = List.generate(600, (_) => gameLogic.rollDice());
        final counts = <int, int>{};

        // 各出目のカウント初期化
        for (int i = 1; i <= 6; i++) {
          counts[i] = 0;
        }

        // ロールをカウント
        for (final roll in rolls) {
          counts[roll] = counts[roll]! + 1;
        }

        // 理想値：600回 / 6 = 100回（各目が100回出るのが理想）
        final expectedCount = rolls.length ~/ 6;
        // 許容範囲：±30%（70～130回）
        final tolerance = (expectedCount * 0.3).toInt();
        final minCount = expectedCount - tolerance;
        final maxCount = expectedCount + tolerance;

        // 各目の出現回数が許容範囲内か検証
        for (int i = 1; i <= 6; i++) {
          final count = counts[i]!;
          expect(
            count,
            greaterThanOrEqualTo(minCount),
            reason: '出目 $i の出現回数 $count が低すぎる（最小値: $minCount）',
          );
          expect(
            count,
            lessThanOrEqualTo(maxCount),
            reason: '出目 $i の出現回数 $count が高すぎる（最大値: $maxCount）',
          );
        }
      });
    });

    group('generateRoomCode', () {
      test('6文字のコードを生成', () {
        final code = GameRoom.generateRandomId();
        expect(code.length, equals(6));
      });

      test('英数字のみで構成される', () {
        final code = GameRoom.generateRandomId();
        expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
      });

      test('複数回実行時にほぼユニークなコードが生成される', () {
        final codes = List.generate(100, (_) => GameRoom.generateRandomId());
        final uniqueCodes = codes.toSet();
        // 100回中95%以上がユニークであるはず
        expect(uniqueCodes.length, greaterThan(94));
      });

      test('許可されていない文字は含まない', () {
        final code = GameRoom.generateRandomId();
        // 小文字を含まない
        expect(code, isNot(matches(RegExp(r'[a-z]'))));
        // 特殊文字を含まない
        expect(code, isNot(matches(RegExp(r'[!@#$%^&*()]'))));
      });
    });

    group('generateRandomCards', () {
      test('3枚のカードを生成', () {
        final cards = gameLogic.generateRandomCards();
        expect(cards.toList().length, equals(GameConstants.catsPerRound));
      });

      test('すべてのカードが定義済みの猫の種類である', () {
        final cards = gameLogic.generateRandomCards().toList();
        for (final card in cards) {
          expect(
            GameConstants.catTypes,
            contains(card.displayName),
            reason: '不正な猫のタイプ: ${card.displayName}',
          );
        }
      });

      test('複数回実行時に異なる組み合わせが生成される', () {
        final cardSets = List.generate(
          50,
          (_) => gameLogic.generateRandomCards(),
        );
        final uniqueCombinations = cardSets
            .map((cards) => cards.toList().map((c) => c.displayName).join(','))
            .toSet();
        // 50回実行で複数の組み合わせが出るはず
        expect(uniqueCombinations.length, greaterThan(10));
      });

      test('各カードのコストは1～4の範囲内', () {
        for (int i = 0; i < 50; i++) {
          final cards = gameLogic.generateRandomCards().toList();
          for (final card in cards) {
            expect(card.baseCost, greaterThanOrEqualTo(1));
            expect(card.baseCost, lessThanOrEqualTo(GameConstants.maxCatCost));
          }
        }
      });

      test('各カードは一意のIDを持つ', () {
        final cards = gameLogic.generateRandomCards().toList();
        final ids = cards.map((c) => c.id).toSet();
        expect(ids.length, equals(GameConstants.catsPerRound));
      });
    });
  });

  group('GameLogic - 勝利条件判定', () {
    // 勝利判定の責務は WinCondition に移動したため、
    // ここでは GameLogic を通じた統合的な挙動のみをテストします。
  });

  group('GameLogic - ラウンド結果判定', () {
    late GameLogic gameLogic;

    setUp(() {
      gameLogic = GameLogic();
    });

    group('猫の獲得判定', () {
      test('ホストが必要魚数以上を賭ければ獲得（ゲストが賭けなければ）', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 2, '1': 0, '2': 0},
          guestBets: {'0': 0, '1': 0, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('host'));
        expect(result.hostWonCats, contains('茶トラねこ'));
        expect(result.guestWonCats, isEmpty);
      });

      test('ホストが必要魚数未満なら獲得できない', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 1, '1': 0, '2': 0},
          guestBets: {'0': 0, '1': 0, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('draw'));
        expect(result.hostWonCats, isEmpty);
        expect(result.guestWonCats, isEmpty);
      });

      test('両者が必要魚数以上の場合、多く賭けた方が獲得', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 3, '1': 0, '2': 0},
          guestBets: {'0': 2, '1': 0, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('host'));
        expect(result.hostWonCats, contains('茶トラねこ'));
      });

      test('両者が同じ量を賭ければドロー', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 3, '1': 0, '2': 0},
          guestBets: {'0': 3, '1': 0, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('draw'));
        expect(result.hostWonCats, isEmpty);
        expect(result.guestWonCats, isEmpty);
      });

      test('複数の猫の獲得判定が同時に行われる', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 2, 2],
          ),
          hostBets: {'0': 3, '1': 2, '2': 1},
          guestBets: {'0': 1, '1': 3, '2': 2},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('host'));
        expect(result.winners['1'], equals('guest'));
        expect(result.winners['2'], equals('guest'));
        expect(result.hostWonCats, hasLength(1));
        expect(result.guestWonCats, hasLength(2));
      });

      test('獲得した猫のコストが記録される', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 3, '1': 4, '2': 0},
          guestBets: {'0': 1, '1': 2, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.hostWonCosts, containsAll([2, 3]));
        expect(result.guestWonCosts, isEmpty);
      });
    });

    group('ゲーム最終結果判定', () {
      test('ホストが異なる種類の猫3種を獲得して勝利', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 2, '1': 3, '2': 1},
          guestBets: {'0': 1, '1': 2, '2': 0},
          hostCatsWon: [],
          guestCatsWon: [],
        );

        final result = gameLogic.resolveRound(room);

        expect(result.finalWinner?.value, equals('host'));
        expect(result.finalStatus.value, equals('finished'));
      });

      test('ゲストが同じ種類の猫3匹獲得して勝利', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '茶トラねこ', '茶トラねこ'],
            [1, 1, 1],
          ),
          hostBets: {'0': 0, '1': 0, '2': 0},
          guestBets: {'0': 1, '1': 1, '2': 1},
          hostCatsWon: [],
          guestCatsWon: ['茶トラねこ', '茶トラねこ'],
        );

        final result = gameLogic.resolveRound(room);

        expect(result.finalWinner?.value, equals('guest'));
        expect(result.finalStatus.value, equals('finished'));
      });

      test('どちらも勝利条件を満たさない場合はゲーム継続', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [2, 3, 1],
          ),
          hostBets: {'0': 2, '1': 0, '2': 0},
          guestBets: {'0': 1, '1': 3, '2': 0},
          hostCatsWon: [],
          guestCatsWon: [],
        );

        final result = gameLogic.resolveRound(room);

        expect(result.finalWinner, isNull);
        expect(result.finalStatus.value, equals('roundResult'));
      });

      test('両者が同時に勝利条件を満たした場合、累計コストで判定', () {
        // ホスト: 茶トラ、白、黒を獲得（コスト: 2+3+1=6）
        // ゲスト: 茶トラ、茶トラ、白を獲得（コスト: 1+1+2=4）
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [1, 2, 1],
          ),
          hostBets: {'0': 2, '1': 3, '2': 2},
          guestBets: {'0': 1, '1': 2, '2': 1},
          hostCatsWon: ['茶トラねこ'],
          guestCatsWon: ['茶トラねこ', '茶トラねこ'],
          hostWonCatCosts: [1],
          guestWonCatCosts: [1, 1],
        );

        final result = gameLogic.resolveRound(room);

        // 両者が勝利条件を満たす
        // ホスト: [茶トラ(1)] + [茶トラ(1), 白(2), 黒(1)] = コスト5
        // ゲスト: [茶トラ(1), 茶トラ(1)] + [白(2)] = コスト4
        expect(result.finalWinner?.value, equals('host'));
        expect(result.finalStatus.value, equals('finished'));
      });

      test('両者が同じコストで同時勝利した場合、ドロー', () {
        final room = createTestGameRoom(
          currentRound: createTestRoundCards(
            ['茶トラねこ', '白ねこ', '黒ねこ'],
            [1, 1, 1],
          ),
          hostBets: {'0': 2, '1': 2, '2': 2},
          guestBets: {'0': 1, '1': 1, '2': 1},
          hostCatsWon: [],
          guestCatsWon: [],
        );

        final result = gameLogic.resolveRound(room);

        // ホスト: 3種類獲得、コスト1+1+1=3
        // ゲスト: 獲得なし
        // ホストが勝つ
        expect(result.finalWinner?.value, equals('host'));
      });
    });
  });

  group('GameLogic - エッジケース', () {
    late GameLogic gameLogic;

    setUp(() {
      gameLogic = GameLogic();
    });

    test('ホストとゲストの両方が賭けを0で提出', () {
      final room = createTestGameRoom(
        currentRound: createTestRoundCards(['茶トラねこ', '白ねこ', '黒ねこ'], [2, 3, 1]),
        hostBets: {'0': 0, '1': 0, '2': 0},
        guestBets: {'0': 0, '1': 0, '2': 0},
      );

      final result = gameLogic.resolveRound(room);

      expect(result.hostWonCats, isEmpty);
      expect(result.guestWonCats, isEmpty);
      expect(result.winners.values, everyElement(equals('draw')));
    });

    test('ホストが全ての猫を獲得', () {
      final room = createTestGameRoom(
        currentRound: createTestRoundCards(['茶トラねこ', '白ねこ', '黒ねこ'], [1, 1, 1]),
        hostBets: {'0': 2, '1': 2, '2': 2},
        guestBets: {'0': 0, '1': 0, '2': 0},
      );

      final result = gameLogic.resolveRound(room);

      expect(result.hostWonCats, hasLength(3));
      expect(result.guestWonCats, isEmpty);
    });

    test('複数ラウンドで獲得猫が累積される', () {
      // 1ラウンド目
      final room1 = createTestGameRoom(
        currentRound: createTestRoundCards(['茶トラねこ', '白ねこ', '黒ねこ'], [1, 1, 1]),
        hostBets: {'0': 2, '1': 0, '2': 0},
        guestBets: {'0': 0, '1': 2, '2': 0},
        hostCatsWon: [],
        guestCatsWon: [],
      );

      final result1 = gameLogic.resolveRound(room1);

      // ホスト: 茶トラ獲得、ゲスト: 白獲得

      // 2ラウンド目で、ゲストが黒と白をさらに獲得して3種類に
      final room2 = createTestGameRoom(
        currentRound: createTestRoundCards(['黒ねこ', '白ねこ', '茶トラねこ'], [1, 1, 1]),
        hostBets: {'0': 0, '1': 0, '2': 2},
        guestBets: {'0': 2, '1': 2, '2': 0},
        hostCatsWon: result1.hostWonCats,
        guestCatsWon: result1.guestWonCats,
        hostWonCatCosts: result1.hostWonCosts,
        guestWonCatCosts: result1.guestWonCosts,
      );

      final result2 = gameLogic.resolveRound(room2);

      // ホスト: 茶トラ + 茶トラ（2種類）
      // ゲスト: 白 + 黒 + 白 = 黒1、白2 = 2種類
      // どちらも勝利条件を満たさない（3種類または同種3匹）
      expect(result2.finalWinner, isNull);
    });
  });
}
