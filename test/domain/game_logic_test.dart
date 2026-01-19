import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/game_logic.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
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
        final code = gameLogic.generateRoomCode();
        expect(code.length, equals(6));
      });

      test('英数字のみで構成される', () {
        final code = gameLogic.generateRoomCode();
        expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
      });

      test('複数回実行時にほぼユニークなコードが生成される', () {
        final codes = List.generate(100, (_) => gameLogic.generateRoomCode());
        final uniqueCodes = codes.toSet();
        // 100回中95%以上がユニークであるはず
        expect(uniqueCodes.length, greaterThan(94));
      });

      test('許可されていない文字は含まない', () {
        final code = gameLogic.generateRoomCode();
        // 小文字を含まない
        expect(code, isNot(matches(RegExp(r'[a-z]'))));
        // 特殊文字を含まない
        expect(code, isNot(matches(RegExp(r'[!@#$%^&*()]'))));
      });
    });

    group('generateRandomCats', () {
      test('3匹の猫を生成', () {
        final cats = gameLogic.generateRandomCats();
        expect(cats.length, equals(GameConstants.catCount));
      });

      test('定義済みの猫の種類のみを生成', () {
        final cats = gameLogic.generateRandomCats();
        for (final cat in cats) {
          expect(
            GameConstants.catTypes,
            contains(cat),
            reason: '不正な猫のタイプ: $cat',
          );
        }
      });

      test('複数回実行時に異なる組み合わせが生成される', () {
        final catLists = List.generate(50, (_) => gameLogic.generateRandomCats());
        final uniqueCombinations = catLists
            .map((cats) => cats.join(','))
            .toSet();
        // 50回実行で複数の組み合わせが出るはず
        expect(uniqueCombinations.length, greaterThan(10));
      });

      test('重複する猫が含まれることもある', () {
        bool hasDuplicate = false;
        for (int i = 0; i < 100; i++) {
          final cats = gameLogic.generateRandomCats();
          if (cats[0] == cats[1] || cats[1] == cats[2] || cats[0] == cats[2]) {
            hasDuplicate = true;
            break;
          }
        }
        expect(hasDuplicate, isTrue);
      });
    });

    group('generateRandomCosts', () {
      test('指定数のコストを生成', () {
        for (int count in [1, 2, 3, 5]) {
          final costs = gameLogic.generateRandomCosts(count);
          expect(costs.length, equals(count));
        }
      });

      test('1～4の範囲内のコストを生成', () {
        for (int i = 0; i < 100; i++) {
          final costs = gameLogic.generateRandomCosts(3);
          expect(costs, everyElement(greaterThanOrEqualTo(1)));
          expect(costs, everyElement(lessThanOrEqualTo(4)));
        }
      });

      test('複数のコストが生成される', () {
        final costs = List.generate(100, (_) => gameLogic.generateRandomCosts(3));
        final allValues = costs.expand((c) => c).toSet();
        // 1～4の複数の値が出るはず
        expect(allValues.length, greaterThan(2));
      });

      test('0個のコストを生成できる', () {
        final costs = gameLogic.generateRandomCosts(0);
        expect(costs, isEmpty);
      });
    });
  });

  group('GameLogic - 勝利条件判定', () {
    late GameLogic gameLogic;

    setUp(() {
      gameLogic = GameLogic();
    });

    group('checkWinCondition', () {
      test('3匹未満では勝利しない', () {
        expect(gameLogic.checkWinCondition([]), isFalse);
        expect(gameLogic.checkWinCondition(['茶トラねこ']), isFalse);
        expect(gameLogic.checkWinCondition(['茶トラねこ', '白ねこ']), isFalse);
      });

      test('同じ種類の猫が3匹以上で勝利（すべての猫種）', () {
        for (final catType in GameConstants.catTypes) {
          // 同じ種類の猫が3匹
          final cats3 = [catType, catType, catType];
          expect(
            gameLogic.checkWinCondition(cats3),
            isTrue,
            reason: '$catType × 3匹で勝利すべき',
          );
          
          // 同じ種類の猫が4匹
          final cats4 = [catType, catType, catType, catType];
          expect(
            gameLogic.checkWinCondition(cats4),
            isTrue,
            reason: '$catType × 4匹で勝利すべき',
          );
          
          // 同じ種類の猫が5匹
          final cats5 = [catType, catType, catType, catType, catType];
          expect(
            gameLogic.checkWinCondition(cats5),
            isTrue,
            reason: '$catType × 5匹で勝利すべき',
          );
        }
      });

      test('異なる種類の猫が3種類で勝利', () {
        final cats = ['茶トラねこ', '白ねこ', '黒ねこ'];
        expect(gameLogic.checkWinCondition(cats), isTrue);
      });

      test('異なる種類の猫が3種類 + 追加で勝利', () {
        final cats = ['茶トラねこ', '白ねこ', '黒ねこ', '茶トラねこ'];
        expect(gameLogic.checkWinCondition(cats), isTrue);
      });

      test('同じ種類2匹と異なる種類2種類では勝利しない', () {
        final cats = ['茶トラねこ', '茶トラねこ', '白ねこ'];
        expect(gameLogic.checkWinCondition(cats), isFalse);
      });

      test('同じ種類が2匹と異なる種類が2種類（計4匹）では勝利しない', () {
        final cats = [
          '茶トラねこ',
          '茶トラねこ',
          '白ねこ',
          '黒ねこ',
        ];
        expect(gameLogic.checkWinCondition(cats), isTrue);
      });
    });
  });

  group('GameLogic - ラウンド結果判定', () {
    late GameLogic gameLogic;

    setUp(() {
      gameLogic = GameLogic();
    });

    group('猫の獲得判定', () {
      test('ホストが必要魚数以上を賭ければ獲得（ゲストが賭けなければ）', () {
        final room = createTestGameRoom(
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
          hostBets: {'0': 3, '1': 0, '2': 0},
          guestBets: {'0': 2, '1': 0, '2': 0},
        );

        final result = gameLogic.resolveRound(room);

        expect(result.winners['0'], equals('host'));
        expect(result.hostWonCats, contains('茶トラねこ'));
      });

      test('両者が同じ量を賭ければドロー', () {
        final room = createTestGameRoom(
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 2, 2],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '茶トラねこ', '茶トラねこ'],
          catCosts: [1, 1, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [2, 3, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [1, 2, 1],
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
          cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
          catCosts: [1, 1, 1],
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
        cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
        catCosts: [2, 3, 1],
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
        cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
        catCosts: [1, 1, 1],
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
        cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
        catCosts: [1, 1, 1],
        hostBets: {'0': 2, '1': 0, '2': 0},
        guestBets: {'0': 0, '1': 2, '2': 0},
        hostCatsWon: [],
        guestCatsWon: [],
      );

      final result1 = gameLogic.resolveRound(room1);

      // ホスト: 茶トラ獲得、ゲスト: 白獲得

      // 2ラウンド目で、ゲストが黒と白をさらに獲得して3種類に
      final room2 = createTestGameRoom(
        cats: ['黒ねこ', '白ねこ', '茶トラねこ'],
        catCosts: [1, 1, 1],
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
