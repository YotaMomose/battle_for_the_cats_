import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/won_cat.dart';
import 'package:battle_for_the_cats/models/bets.dart';
import 'package:battle_for_the_cats/models/cat_inventory.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';
import 'package:battle_for_the_cats/models/round_result.dart';
import 'package:battle_for_the_cats/models/round_winners.dart';

void main() {
  group('GameRoom - 初期化', () {
    test('最小限の引数で初期化できる', () {
      final room = GameRoom(
        roomId: 'room-123',
        host: Player(id: 'host-456'),
      );

      expect(room.roomId, equals('room-123'));
      expect(room.hostId, equals('host-456'));
      expect(room.guestId, isNull);
    });

    test('デフォルト値が正しく設定される', () {
      final room = GameRoom(
        roomId: 'room-123',
        host: Player(id: 'host-456'),
      );

      // ゲーム状態
      expect(room.status, equals(GameStatus.waiting));
      expect(room.currentTurn, equals(1));

      // ホスト側
      expect(room.host.catsWon.all, isEmpty);
      expect(room.guest, isNull);
      expect(room.host.fishCount, equals(0));

      // サイコロ
      expect(room.host.diceRoll, isNull);
      expect(room.host.rolled, isFalse);

      // 準備状態
      expect(room.host.ready, isFalse);

      // 退出状態
      expect(room.host.abandoned, isFalse);
    });

    test('デフォルト currentRound が null で初期化される', () {
      final room = GameRoom(
        roomId: 'room-123',
        host: Player(id: 'host-456'),
      );

      expect(room.currentRound, isNull);
    });

    test('デフォルト賭けが初期化される', () {
      final room = GameRoom(
        roomId: 'room-123',
        host: Player(id: 'host-456'),
      );

      expect(room.host.currentBets, equals(Bets.empty()));
    });

    test('カスタム値で初期化できる', () {
      final roundCards = RoundCards.random();
      final room = GameRoom(
        roomId: 'room-123',
        host: Player(id: 'host-456', fishCount: 10),
        guest: Player(id: 'guest-789', fishCount: 8),
        status: GameStatus.playing,
        currentTurn: 2,
        currentRound: roundCards,
      );

      expect(room.guestId, equals('guest-789'));
      expect(room.status, equals(GameStatus.playing));
      expect(room.currentTurn, equals(2));
      expect(room.currentRound, equals(roundCards));
      expect(room.host.fishCount, equals(10));
      expect(room.guest?.fishCount, equals(8));
    });
    group('GameRoom - メソッド', () {
      test('status を変更できる', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
        );

        expect(room.status, equals(GameStatus.waiting));

        room.status = GameStatus.rolling;
        expect(room.status, equals(GameStatus.rolling));
      });

      test('currentTurn を更新できる', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
        );

        expect(room.currentTurn, equals(1));

        room.currentTurn = 2;
        expect(room.currentTurn, equals(2));
      });
    });

    group('GameRoom - シリアライズ (toMap/fromMap)', () {
      test('toMap() で完全に変換される (Playerオブジェクトを含む)', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(
            id: 'host-456',
            fishCount: 10,
            rolled: true,
            diceRoll: 4,
            ready: true,
          ),
          guest: Player(id: 'guest-789', fishCount: 8, diceRoll: 3),
          status: GameStatus.playing,
          currentTurn: 2,
        );

        final map = room.toMap();

        expect(map['roomId'], equals('room-123'));
        expect(map['status'], equals(GameStatus.playing.value));
        expect(map['currentTurn'], equals(2));

        // Playerの検証
        final hostMap = map['host'] as Map<String, dynamic>;
        expect(hostMap['id'], equals('host-456'));
        expect(hostMap['fishCount'], equals(10));
        expect(hostMap['rolled'], isTrue);
        expect(hostMap['diceRoll'], equals(4));
        expect(hostMap['currentBets'], isA<Map<String, dynamic>>());
        expect(hostMap['catsWon'], isA<List<dynamic>>());
        expect(hostMap['ready'], isTrue);

        final guestMap = map['guest'] as Map<String, dynamic>;
        expect(guestMap['id'], equals('guest-789'));
        expect(guestMap['fishCount'], equals(8));
        expect(guestMap['diceRoll'], equals(3));
      });

      test('fromMap() で復元できる', () {
        final originalMap = {
          'roomId': 'room-123',
          'host': {
            'id': 'host-456',
            'fishCount': 10,
            'diceRoll': 4,
            'rolled': true,
            'ready': true,
            'currentBets': {'0': 3, '1': 2, '2': 1},
            'catsWon': [
              {'name': '茶トラねこ', 'cost': 2},
              {'name': '白ねこ', 'cost': 3},
            ],
          },
          'guest': {
            'id': 'guest-789',
            'fishCount': 8,
            'diceRoll': 3,
            'rolled': true,
            'ready': false,
            'currentBets': {'0': 1, '1': 2, '2': 3},
            'catsWon': [
              {'name': '黒ねこ', 'cost': 1},
            ],
          },
          'status': 'playing',
          'currentTurn': 2,
        };

        final room = GameRoom.fromMap(originalMap);

        print('Debug: expected id=host-456, actual id=${room.host.id}');
        print('Debug: expected status=playing, actual status=${room.status}');

        expect(room.roomId, equals('room-123'));
        expect(room.host.id, equals('host-456'));
        expect(room.guest?.id, equals('guest-789'));
        expect(room.status, equals(GameStatus.playing));
        expect(room.currentTurn, equals(2));
        expect(room.host.fishCount, equals(10));
        expect(room.guest?.fishCount, equals(8));
        expect(room.host.diceRoll, equals(4));
        expect(room.guest?.diceRoll, isNull);
        expect(room.host.ready, isTrue);
        expect(room.guest?.ready, isFalse);

        // Betsの検証
        expect(room.host.currentBets.getBet('0'), equals(3));
        expect(room.host.currentBets.getBet('1'), equals(2));
        expect(room.host.currentBets.getBet('2'), equals(1));
        expect(room.guest?.currentBets.getBet('0'), equals(1));
        expect(room.guest?.currentBets.getBet('1'), equals(2));
        expect(room.guest?.currentBets.getBet('2'), equals(3));

        // CatInventoryの検証
        expect(room.host.catsWon.count, equals(2));
        expect(room.host.catsWon.all[0].name, equals('茶トラねこ'));
        expect(room.host.catsWon.all[1].name, equals('白ねこ'));
        expect(room.guest?.catsWon.count, equals(1));
        expect(room.guest?.catsWon.all[0].name, equals('黒ねこ'));
      });

      test('round-trip (toMap → fromMap) で値が保存される', () {
        final original = GameRoom(
          roomId: 'room-123',
          host: Player(
            id: 'host-456',
            fishCount: 15,
            catsWon: CatInventory([
              WonCat(name: '茶トラねこ', cost: 2),
              WonCat(name: '白ねこ', cost: 3),
            ]),
            diceRoll: 5,
            rolled: true,
            ready: true,
            currentBets: Bets({'0': 3, '1': 2, '2': 1}),
          ),
          guest: Player(
            id: 'guest-789',
            fishCount: 12,
            catsWon: CatInventory([WonCat(name: '黒ねこ', cost: 1)]),
            diceRoll: 2,
            rolled: true,
            ready: true,
            currentBets: Bets({'0': 1, '1': 2, '2': 3}),
          ),
          status: GameStatus.roundResult,
          currentTurn: 3,
          currentRound: RoundCards.random(),
        );

        // toMap → fromMap
        final map = original.toMap();
        final restored = GameRoom.fromMap(map);

        // すべての重要フィールドが保存されているか確認
        expect(restored.roomId, equals(original.roomId));
        expect(restored.host.id, equals(original.host.id));
        expect(restored.guest?.id, equals(original.guest?.id));
        expect(restored.status, equals(original.status));
        expect(restored.currentTurn, equals(original.currentTurn));
        expect(restored.host.fishCount, equals(original.host.fishCount));
        expect(restored.guest?.fishCount, equals(original.guest?.fishCount));
        expect(
          restored.host.catsWon.count,
          equals(original.host.catsWon.count),
        );
        expect(restored.host.totalWonCatCost, equals(5));
        expect(restored.guest?.totalWonCatCost, equals(1));
        expect(restored.host.diceRoll, equals(original.host.diceRoll));
        expect(restored.guest?.diceRoll, equals(original.guest?.diceRoll));
        // オブジェクトの等価性ではなく、内容(Map)で比較
        expect(
          restored.host.currentBets.toMap(),
          equals(original.host.currentBets.toMap()),
        );
        expect(
          restored.guest?.currentBets.toMap(),
          equals(original.guest?.currentBets.toMap()),
        );
      });

      test('null 値が正しく処理される', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
        );

        final map = room.toMap();
        final restored = GameRoom.fromMap(map);

        expect(restored.guest, isNull);
        expect(restored.host.diceRoll, isNull);
        expect(restored.winners, isNull);
        expect(restored.finalWinner, isNull);
        expect(restored.host.currentBets.total, equals(0));
        expect(restored.host.catsWon.count, equals(0));
      });
    });

    group('GameRoom - ゲーム進行', () {
      test('複数ラウンドで状態が正しく引き継がれる', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
          guest: Player(id: 'guest-456'),
        );

        // ラウンド1
        room.currentTurn = 1;
        room.host.addWonCat('茶トラねこ', 2);
        room.guest?.addWonCat('白ねこ', 1);

        // ラウンド2に進む
        room.currentTurn = 2;
        room.host.addWonCat('黒ねこ', 3);
        room.guest?.addWonCat('茶トラねこ', 2);

        // 累積を確認
        expect(room.currentTurn, equals(2));
        expect(room.host.wonCatNames, equals(['茶トラねこ', '黒ねこ']));
        expect(room.guest?.wonCatNames, equals(['白ねこ', '茶トラねこ']));
        expect(room.host.totalWonCatCost, equals(5));
        expect(room.guest?.totalWonCatCost, equals(3));
      });

      test('前回のラウンド情報が記録される', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
        );

        room.lastRoundResult = RoundResult(
          cats: [
            WonCat(name: '茶トラねこ', cost: 2),
            WonCat(name: '白ねこ', cost: 3),
            WonCat(name: '黒ねこ', cost: 1),
          ],
          winners: RoundWinners({
            '0': Winner.host,
            '1': Winner.guest,
            '2': Winner.draw,
          }),
          hostBets: Bets({'0': 3, '1': 2, '2': 1}),
          guestBets: Bets({'0': 2, '1': 3, '2': 2}),
        );

        expect(
          room.lastRoundResult?.cats.map((c) => c.name),
          equals(['茶トラねこ', '白ねこ', '黒ねこ']),
        );
        expect(
          room.lastRoundResult?.cats.map((c) => c.cost),
          equals([2, 3, 1]),
        );
        expect(
          room.lastRoundResult?.winners,
          equals(
            RoundWinners({
              '0': Winner.host,
              '1': Winner.guest,
              '2': Winner.draw,
            }),
          ),
        );
      });

      test('確定フラグが各段階で機能する', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
          guest: Player(id: 'guest-456'),
        );

        // サイコロ確定
        expect(room.host.confirmedRoll, isFalse);
        expect(room.guest?.confirmedRoll, isFalse);

        room.host.confirmedRoll = true;
        room.guest?.confirmedRoll = true;

        expect(room.host.confirmedRoll, isTrue);
        expect(room.guest?.confirmedRoll, isTrue);

        // ラウンド結果確定
        expect(room.host.confirmedRoundResult, isFalse);
        expect(room.guest?.confirmedRoundResult, isFalse);

        room.host.confirmedRoundResult = true;
        expect(room.host.confirmedRoundResult, isTrue);
      });
    });
  });
}
