import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/models/game_room.dart';

void main() {
  group('GameRoom - 初期化', () {
    test('最小限の引数で初期化できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.roomId, equals('room-123'));
      expect(room.hostId, equals('host-456'));
      expect(room.guestId, isNull);
    });

    test('デフォルト値が正しく設定される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      // ゲーム状態
      expect(room.status, equals('waiting'));
      expect(room.currentTurn, equals(1));

      // ホスト側
      expect(room.hostCatsWon, isEmpty);
      expect(room.guestCatsWon, isEmpty);
      expect(room.hostFishCount, equals(0));
      expect(room.guestFishCount, equals(0));

      // サイコロ
      expect(room.hostDiceRoll, isNull);
      expect(room.guestDiceRoll, isNull);
      expect(room.hostRolled, isFalse);
      expect(room.guestRolled, isFalse);

      // 準備状態
      expect(room.hostReady, isFalse);
      expect(room.guestReady, isFalse);

      // 退出状態
      expect(room.hostAbandoned, isFalse);
      expect(room.guestAbandoned, isFalse);
    });

    test('デフォルト猫が3匹設定される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.cats, hasLength(3));
      expect(room.cats, everyElement('通常ネコ'));
      expect(room.catCosts, hasLength(3));
      expect(room.catCosts, everyElement(1));
    });

    test('デフォルト賭けが初期化される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.hostBets, equals({'0': 0, '1': 0, '2': 0}));
      expect(room.guestBets, equals({'0': 0, '1': 0, '2': 0}));
    });

    test('カスタム値で初期化できる', () {
      final customCats = ['茶トラねこ', '白ねこ', '黒ねこ'];
      final customCosts = [2, 3, 1];
      final room = GameRoom(
        roomId: 'room-123',
        hostId: 'host-456',
        guestId: 'guest-789',
        status: 'playing',
        currentTurn: 2,
        cats: customCats,
        catCosts: customCosts,
        hostFishCount: 10,
        guestFishCount: 8,
      );

      expect(room.guestId, equals('guest-789'));
      expect(room.status, equals('playing'));
      expect(room.currentTurn, equals(2));
      expect(room.cats, equals(customCats));
      expect(room.catCosts, equals(customCosts));
      expect(room.hostFishCount, equals(10));
      expect(room.guestFishCount, equals(8));
    });
  });

  group('GameRoom - 状態遷移', () {
    test('status を変更できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.status, equals('waiting'));

      room.status = 'rolling';
      expect(room.status, equals('rolling'));

      room.status = 'playing';
      expect(room.status, equals('playing'));

      room.status = 'finished';
      expect(room.status, equals('finished'));
    });

    test('currentTurn を複数回更新できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.currentTurn, equals(1));

      room.currentTurn = 2;
      expect(room.currentTurn, equals(2));

      room.currentTurn = 5;
      expect(room.currentTurn, equals(5));
    });

    test('ホストのサイコロ結果が記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.hostDiceRoll, isNull);
      expect(room.hostRolled, isFalse);

      room.hostDiceRoll = 4;
      room.hostRolled = true;

      expect(room.hostDiceRoll, equals(4));
      expect(room.hostRolled, isTrue);
    });

    test('ゲストのサイコロ結果が記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.guestDiceRoll = 3;
      room.guestRolled = true;

      expect(room.guestDiceRoll, equals(3));
      expect(room.guestRolled, isTrue);
    });

    test('両プレイヤーのサイコロ結果は独立している', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostDiceRoll = 4;
      room.guestDiceRoll = 2;

      expect(room.hostDiceRoll, equals(4));
      expect(room.guestDiceRoll, equals(2));
    });

    test('準備状態が独立して管理される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostReady = true;
      expect(room.hostReady, isTrue);
      expect(room.guestReady, isFalse);

      room.guestReady = true;
      expect(room.hostReady, isTrue);
      expect(room.guestReady, isTrue);
    });

    test('ホストの賭けが記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostBets['0'] = 3;
      room.hostBets['1'] = 2;
      room.hostBets['2'] = 1;

      expect(room.hostBets['0'], equals(3));
      expect(room.hostBets['1'], equals(2));
      expect(room.hostBets['2'], equals(1));
    });

    test('ゲストの賭けが記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.guestBets['0'] = 2;
      room.guestBets['1'] = 3;
      room.guestBets['2'] = 1;

      expect(room.guestBets, equals({'0': 2, '1': 3, '2': 1}));
    });

    test('獲得猫のリストが累積される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostCatsWon.add('茶トラねこ');
      expect(room.hostCatsWon, equals(['茶トラねこ']));

      room.hostCatsWon.add('白ねこ');
      expect(room.hostCatsWon, equals(['茶トラねこ', '白ねこ']));

      room.guestCatsWon.add('黒ねこ');
      expect(room.guestCatsWon, equals(['黒ねこ']));
    });

    test('獲得猫のコストが記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostWonCatCosts.add(2);
      room.hostWonCatCosts.add(3);

      expect(room.hostWonCatCosts, equals([2, 3]));
      expect(room.guestWonCatCosts, isEmpty);
    });
  });

  group('GameRoom - シリアライズ (toMap/fromMap)', () {
    test('toMap() で完全に変換される', () {
      final room = GameRoom(
        roomId: 'room-123',
        hostId: 'host-456',
        guestId: 'guest-789',
        status: 'playing',
        currentTurn: 2,
        hostFishCount: 10,
        guestFishCount: 8,
      );

      room.hostDiceRoll = 4;
      room.guestDiceRoll = 3;
      room.hostReady = true;

      final map = room.toMap();

      expect(map['roomId'], equals('room-123'));
      expect(map['hostId'], equals('host-456'));
      expect(map['guestId'], equals('guest-789'));
      expect(map['status'], equals('playing'));
      expect(map['currentTurn'], equals(2));
      expect(map['hostFishCount'], equals(10));
      expect(map['guestFishCount'], equals(8));
      expect(map['hostDiceRoll'], equals(4));
      expect(map['guestDiceRoll'], equals(3));
      expect(map['hostReady'], isTrue);
    });

    test('fromMap() で復元できる', () {
      final originalMap = {
        'roomId': 'room-123',
        'hostId': 'host-456',
        'guestId': 'guest-789',
        'status': 'playing',
        'currentTurn': 2,
        'hostFishCount': 10,
        'guestFishCount': 8,
        'hostDiceRoll': 4,
        'guestDiceRoll': 3,
        'hostReady': true,
        'guestReady': false,
        'cats': ['茶トラねこ', '白ねこ', '黒ねこ'],
        'catCosts': [2, 3, 1],
        'hostBets': {'0': 3, '1': 2, '2': 1},
        'guestBets': {'0': 1, '1': 2, '2': 3},
        'hostCatsWon': ['茶トラねこ', '白ねこ'],
        'guestCatsWon': ['黒ねこ'],
        'hostWonCatCosts': [2, 3],
        'guestWonCatCosts': [1],
      };

      final room = GameRoom.fromMap(originalMap);

      expect(room.roomId, equals('room-123'));
      expect(room.hostId, equals('host-456'));
      expect(room.guestId, equals('guest-789'));
      expect(room.status, equals('playing'));
      expect(room.currentTurn, equals(2));
      expect(room.hostFishCount, equals(10));
      expect(room.guestFishCount, equals(8));
      expect(room.hostDiceRoll, equals(4));
      expect(room.guestDiceRoll, equals(3));
      expect(room.hostReady, isTrue);
    });

    test('round-trip (toMap → fromMap) で値が保存される', () {
      final original = GameRoom(
        roomId: 'room-123',
        hostId: 'host-456',
        guestId: 'guest-789',
        status: 'roundResult',
        currentTurn: 3,
        hostFishCount: 15,
        guestFishCount: 12,
        cats: ['茶トラねこ', '白ねこ', '黒ねこ'],
        catCosts: [2, 3, 1],
        hostCatsWon: ['茶トラねこ', '白ねこ'],
        guestCatsWon: ['黒ねこ'],
        hostWonCatCosts: [2, 3],
        guestWonCatCosts: [1],
      );

      original.hostDiceRoll = 5;
      original.guestDiceRoll = 2;
      original.hostReady = true;
      original.guestReady = true;
      original.hostBets = {'0': 3, '1': 2, '2': 1};
      original.guestBets = {'0': 1, '1': 2, '2': 3};

      // toMap → fromMap
      final map = original.toMap();
      final restored = GameRoom.fromMap(map);

      // すべての重要フィールドが保存されているか確認
      expect(restored.roomId, equals(original.roomId));
      expect(restored.hostId, equals(original.hostId));
      expect(restored.guestId, equals(original.guestId));
      expect(restored.status, equals(original.status));
      expect(restored.currentTurn, equals(original.currentTurn));
      expect(restored.hostFishCount, equals(original.hostFishCount));
      expect(restored.guestFishCount, equals(original.guestFishCount));
      expect(restored.cats, equals(original.cats));
      expect(restored.catCosts, equals(original.catCosts));
      expect(restored.hostCatsWon, equals(original.hostCatsWon));
      expect(restored.guestCatsWon, equals(original.guestCatsWon));
      expect(restored.hostWonCatCosts, equals(original.hostWonCatCosts));
      expect(restored.guestWonCatCosts, equals(original.guestWonCatCosts));
      expect(restored.hostDiceRoll, equals(original.hostDiceRoll));
      expect(restored.guestDiceRoll, equals(original.guestDiceRoll));
      expect(restored.hostBets, equals(original.hostBets));
      expect(restored.guestBets, equals(original.guestBets));
    });

    test('null 値が正しく処理される', () {
      final room = GameRoom(
        roomId: 'room-123',
        hostId: 'host-456',
      );

      final map = room.toMap();
      final restored = GameRoom.fromMap(map);

      expect(restored.guestId, isNull);
      expect(restored.hostDiceRoll, isNull);
      expect(restored.guestDiceRoll, isNull);
      expect(restored.winners, isNull);
      expect(restored.finalWinner, isNull);
    });
  });

  group('GameRoom - ゲーム進行', () {
    test('複数ラウンドで状態が正しく引き継がれる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      // ラウンド1
      room.currentTurn = 1;
      room.hostCatsWon.add('茶トラねこ');
      room.guestCatsWon.add('白ねこ');
      room.hostWonCatCosts.add(2);
      room.guestWonCatCosts.add(1);

      // ラウンド2に進む
      room.currentTurn = 2;
      room.hostCatsWon.add('黒ねこ');
      room.guestCatsWon.add('茶トラねこ');
      room.hostWonCatCosts.add(3);
      room.guestWonCatCosts.add(2);

      // 累積を確認
      expect(room.currentTurn, equals(2));
      expect(room.hostCatsWon, equals(['茶トラねこ', '黒ねこ']));
      expect(room.guestCatsWon, equals(['白ねこ', '茶トラねこ']));
      expect(room.hostWonCatCosts, equals([2, 3]));
      expect(room.guestWonCatCosts, equals([1, 2]));
    });

    test('前回のラウンド情報が記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.lastRoundCats = ['茶トラねこ', '白ねこ', '黒ねこ'];
      room.lastRoundCatCosts = [2, 3, 1];
      room.lastRoundWinners = {'0': 'host', '1': 'guest', '2': 'draw'};
      room.lastRoundHostBets = {'0': 3, '1': 2, '2': 1};
      room.lastRoundGuestBets = {'0': 2, '1': 3, '2': 2};

      expect(room.lastRoundCats, equals(['茶トラねこ', '白ねこ', '黒ねこ']));
      expect(room.lastRoundCatCosts, equals([2, 3, 1]));
      expect(room.lastRoundWinners, equals({'0': 'host', '1': 'guest', '2': 'draw'}));
    });

    test('ゲーム終了時に最終勝者が記録される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.finalWinner, isNull);

      room.finalWinner = 'host';
      room.status = 'finished';

      expect(room.finalWinner, equals('host'));
      expect(room.status, equals('finished'));
    });

    test('退出状態が独立して管理される', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.hostAbandoned, isFalse);
      expect(room.guestAbandoned, isFalse);

      room.hostAbandoned = true;
      expect(room.hostAbandoned, isTrue);
      expect(room.guestAbandoned, isFalse);

      room.guestAbandoned = true;
      expect(room.hostAbandoned, isTrue);
      expect(room.guestAbandoned, isTrue);
    });

    test('確定フラグが各段階で機能する', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      // サイコロ確定
      expect(room.hostConfirmedRoll, isFalse);
      expect(room.guestConfirmedRoll, isFalse);

      room.hostConfirmedRoll = true;
      room.guestConfirmedRoll = true;

      expect(room.hostConfirmedRoll, isTrue);
      expect(room.guestConfirmedRoll, isTrue);

      // ラウンド結果確定
      expect(room.hostConfirmedRoundResult, isFalse);
      expect(room.guestConfirmedRoundResult, isFalse);

      room.hostConfirmedRoundResult = true;
      expect(room.hostConfirmedRoundResult, isTrue);
    });
  });

  group('GameRoom - エッジケース', () {
    test('大きなターン数に対応できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.currentTurn = 100;
      expect(room.currentTurn, equals(100));
    });

    test('多数の猫獲得に対応できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      for (int i = 0; i < 50; i++) {
        room.hostCatsWon.add('茶トラねこ');
      }

      expect(room.hostCatsWon, hasLength(50));
    });

    test('大きな魚数に対応できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      room.hostFishCount = 1000;
      room.guestFishCount = 999;

      expect(room.hostFishCount, equals(1000));
      expect(room.guestFishCount, equals(999));
    });

    test('ゲストIDが null のまま処理できる', () {
      final room = GameRoom(roomId: 'room-123', hostId: 'host-456');

      expect(room.guestId, isNull);

      // ゲストが参加しても他の処理は進められる
      room.status = 'rolling';
      room.hostDiceRoll = 4;

      expect(room.status, equals('rolling'));
    });
  });
}
