import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import 'package:battle_for_the_cats/models/player.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';

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
      expect(room.host.catsWon, isEmpty);
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

      expect(room.host.currentBets, equals({'0': 0, '1': 0, '2': 0}));
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
            'catsWon': ['茶トラねこ', '白ねこ'],
            'wonCatCosts': [2, 3],
          },
          'guest': {
            'id': 'guest-789',
            'fishCount': 8,
            'diceRoll': 3,
            'rolled': true,
            'ready': false,
            'currentBets': {'0': 1, '1': 2, '2': 3},
            'catsWon': ['黒ねこ'],
            'wonCatCosts': [1],
          },
          'status': 'playing',
          'currentTurn': 2,
          'cats': ['茶トラねこ', '白ねこ', '黒ねこ'],
          'catCosts': [2, 3, 1],
        };

        final room = GameRoom.fromMap(originalMap);

        expect(room.roomId, equals('room-123'));
        expect(room.host.id, equals('host-456'));
        expect(room.guest?.id, equals('guest-789'));
        expect(room.status, equals(GameStatus.playing));
        expect(room.currentTurn, equals(2));
        expect(room.host.fishCount, equals(10));
        expect(room.guest?.fishCount, equals(8));
        expect(room.host.diceRoll, equals(4));
        expect(room.guest?.diceRoll, equals(3));
        expect(room.host.ready, isTrue);
      });

      test('round-trip (toMap → fromMap) で値が保存される', () {
        final original = GameRoom(
          roomId: 'room-123',
          host: Player(
            id: 'host-456',
            fishCount: 15,
            catsWon: ['茶トラねこ', '白ねこ'],
            wonCatCosts: [2, 3],
            diceRoll: 5,
            rolled: true,
            ready: true,
            currentBets: {'0': 3, '1': 2, '2': 1},
          ),
          guest: Player(
            id: 'guest-789',
            fishCount: 12,
            catsWon: ['黒ねこ'],
            wonCatCosts: [1],
            diceRoll: 2,
            rolled: true,
            ready: true,
            currentBets: {'0': 1, '1': 2, '2': 3},
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
        expect(restored.host.catsWon, equals(original.host.catsWon));
        expect(restored.guest?.catsWon, equals(original.guest?.catsWon));
        expect(restored.host.wonCatCosts, equals(original.host.wonCatCosts));
        expect(
          restored.guest?.wonCatCosts,
          equals(original.guest?.wonCatCosts),
        );
        expect(restored.host.diceRoll, equals(original.host.diceRoll));
        expect(restored.guest?.diceRoll, equals(original.guest?.diceRoll));
        expect(restored.host.currentBets, equals(original.host.currentBets));
        expect(
          restored.guest?.currentBets,
          equals(original.guest?.currentBets),
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
        room.host.catsWon.add('茶トラねこ');
        room.guest?.catsWon.add('白ねこ');
        room.host.wonCatCosts.add(2);
        room.guest?.wonCatCosts.add(1);

        // ラウンド2に進む
        room.currentTurn = 2;
        room.host.catsWon.add('黒ねこ');
        room.guest?.catsWon.add('茶トラねこ');
        room.host.wonCatCosts.add(3);
        room.guest?.wonCatCosts.add(2);

        // 累積を確認
        expect(room.currentTurn, equals(2));
        expect(room.host.catsWon, equals(['茶トラねこ', '黒ねこ']));
        expect(room.guest?.catsWon, equals(['白ねこ', '茶トラねこ']));
        expect(room.host.wonCatCosts, equals([2, 3]));
        expect(room.guest?.wonCatCosts, equals([1, 2]));
      });

      test('前回のラウンド情報が記録される', () {
        final room = GameRoom(
          roomId: 'room-123',
          host: Player(id: 'host-456'),
        );

        room.lastRoundCats = ['茶トラねこ', '白ねこ', '黒ねこ'];
        room.lastRoundCatCosts = [2, 3, 1];
        room.lastRoundWinners = {'0': 'host', '1': 'guest', '2': 'draw'};
        room.lastRoundHostBets = {'0': 3, '1': 2, '2': 1};
        room.lastRoundGuestBets = {'0': 2, '1': 3, '2': 2};

        expect(room.lastRoundCats, equals(['茶トラねこ', '白ねこ', '黒ねこ']));
        expect(room.lastRoundCatCosts, equals([2, 3, 1]));
        expect(
          room.lastRoundWinners,
          equals({'0': 'host', '1': 'guest', '2': 'draw'}),
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
