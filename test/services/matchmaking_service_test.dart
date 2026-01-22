import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/services/matchmaking_service.dart';
import 'package:battle_for_the_cats/services/room_service.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';
import '../mocks/mock_firestore_repository.dart';
import '../mocks/mock_room_repository.dart';

void main() {
  group('MatchmakingService - 詳細テスト', () {
    late MatchmakingService matchmakingService;
    late MockFirestoreRepository mockFirestoreRepository;
    late RoomService roomService;
    setUp(() {
      mockFirestoreRepository = MockFirestoreRepository();
      final mockRoomRepository = MockRoomRepository();
      roomService = RoomService(repository: mockRoomRepository);
      
      matchmakingService = MatchmakingService(
        repository: mockFirestoreRepository,
        roomService: roomService,
      );
    });

    group('joinMatchmaking', () {
      test('プレイヤーIDが正しく登録される', () async {
        const playerId = 'player_001';
        final result = await matchmakingService.joinMatchmaking(playerId);
        expect(result, equals(playerId));
      });

      test('複数のプレイヤーが同時に登録できる', () async {
        const playerIds = ['player_001', 'player_002', 'player_003'];
        final results = <String>[];
        for (final playerId in playerIds) {
          results.add(await matchmakingService.joinMatchmaking(playerId));
        }
        expect(results.length, equals(3));
        expect(results, containsAll(playerIds));
      });

      test('大量のプレイヤー登録に対応できる', () async {
        final playerIds = List.generate(100, (i) => 'player_$i');
        final futures = playerIds.map((id) => matchmakingService.joinMatchmaking(id));
        final results = await Future.wait(futures);
        expect(results.length, equals(100));
        expect(results.toSet().length, equals(100));
      });
    });

    group('マッチングロジック', () {
      test('マッチング定数が正しく定義されている', () {
        expect(GameConstants.matchmakingSearchLimit, greaterThan(0));
        expect(GameConstants.matchmakingSearchLimit, equals(10));
      });

      test('MatchmakingStatus が正しく定義されている', () {
        expect(MatchmakingStatus.waiting.value, equals('waiting'));
        expect(MatchmakingStatus.matched.value, equals('matched'));
      });

      test('MatchmakingStatus.fromString が正しく動作する', () {
        expect(
          MatchmakingStatus.fromString('waiting'),
          equals(MatchmakingStatus.waiting),
        );
        expect(
          MatchmakingStatus.fromString('matched'),
          equals(MatchmakingStatus.matched),
        );
        expect(
          MatchmakingStatus.fromString('invalid'),
          equals(MatchmakingStatus.waiting),
        );
      });
    });

    group('マッチング状態管理', () {
      test('プレイヤーがマッチング待機リストに追加される', () async {
        const playerId = 'player_001';
        final registeredId = await matchmakingService.joinMatchmaking(playerId);
        expect(registeredId, equals(playerId));
      });

      test('複数プレイヤーのマッチング登録が独立している', () async {
        const player1 = 'player_001';
        const player2 = 'player_002';
        final result1 = await matchmakingService.joinMatchmaking(player1);
        final result2 = await matchmakingService.joinMatchmaking(player2);
        expect(result1, equals(player1));
        expect(result2, equals(player2));
        expect(result1, isNot(equals(result2)));
      });
    });

    group('エッジケース', () {
      test('プレイヤーID が空文字列でない', () async {
        const playerId = 'player_001';
        final result = await matchmakingService.joinMatchmaking(playerId);
        expect(result, isNotEmpty);
        expect(result, isA<String>());
      });

      test('複数のマッチング登録リクエストが競合しない', () async {
        const playerIds = ['p1', 'p2', 'p3', 'p4', 'p5'];
        final futures = playerIds.map((id) => matchmakingService.joinMatchmaking(id));
        final results = await Future.wait(futures);
        expect(results.length, equals(5));
        expect(results.toSet().length, equals(5));
      });
    });
  });
}
