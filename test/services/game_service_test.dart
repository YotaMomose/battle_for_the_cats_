import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:battle_for_the_cats/services/game_flow_service.dart';
import 'package:battle_for_the_cats/services/game_service.dart';
import 'package:battle_for_the_cats/services/matchmaking_service.dart';
import 'package:battle_for_the_cats/services/room_service.dart';

class MockRoomService extends Mock implements RoomService {}
class MockMatchmakingService extends Mock implements MatchmakingService {}
class MockGameFlowService extends Mock implements GameFlowService {}

void main() {
  group('GameService', () {
    late MockRoomService mockRoomService;
    late MockMatchmakingService mockMatchmakingService;
    late MockGameFlowService mockGameFlowService;
    late GameService gameService;

    setUp(() {
      mockRoomService = MockRoomService();
      mockMatchmakingService = MockMatchmakingService();
      mockGameFlowService = MockGameFlowService();

      gameService = GameService(
        roomService: mockRoomService,
        matchmakingService: mockMatchmakingService,
        gameFlowService: mockGameFlowService,
      );
    });

    group('ルーム管理メソッド', () {
      test('generateRoomCode をリクエストすると RoomService に委譲される', () {
        when(mockRoomService.generateRoomCode()).thenReturn('ABC123');

        final result = gameService.generateRoomCode();

        expect(result, equals('ABC123'));
        verify(mockRoomService.generateRoomCode()).called(1);
      });

      test('createRoom をリクエストすると RoomService に委譲される', () async {
        when(mockRoomService.createRoom('host_001'))
            .thenAnswer((_) async => 'ROOM_CODE_001');

        final result = await gameService.createRoom('host_001');

        expect(result, equals('ROOM_CODE_001'));
        verify(mockRoomService.createRoom('host_001')).called(1);
      });

      test('joinRoom をリクエストすると RoomService に委譲される', () async {
        when(mockRoomService.joinRoom('ROOM_CODE', 'guest_001'))
            .thenAnswer((_) async => true);

        final result = await gameService.joinRoom('ROOM_CODE', 'guest_001');

        expect(result, isTrue);
        verify(mockRoomService.joinRoom('ROOM_CODE', 'guest_001')).called(1);
      });

      test('deleteRoom をリクエストすると RoomService に委譲される', () async {
        when(mockRoomService.deleteRoom('ROOM_CODE'))
            .thenAnswer((_) async => null);

        await gameService.deleteRoom('ROOM_CODE');

        verify(mockRoomService.deleteRoom('ROOM_CODE')).called(1);
      });
    });

    group('マッチングメソッド', () {
      test('joinMatchmaking をリクエストすると MatchmakingService に委譲される', () async {
        when(mockMatchmakingService.joinMatchmaking('player_001'))
            .thenAnswer((_) async => 'match_001');

        final result = await gameService.joinMatchmaking('player_001');

        expect(result, equals('match_001'));
        verify(mockMatchmakingService.joinMatchmaking('player_001')).called(1);
      });

      test('cancelMatchmaking をリクエストすると MatchmakingService に委譲される', () async {
        when(mockMatchmakingService.cancelMatchmaking('player_001'))
            .thenAnswer((_) async => null);

        await gameService.cancelMatchmaking('player_001');

        verify(mockMatchmakingService.cancelMatchmaking('player_001')).called(1);
      });

      test('isHostInMatch をリクエストすると MatchmakingService に委譲される', () async {
        when(mockMatchmakingService.isHostInMatch('player_001'))
            .thenAnswer((_) async => true);

        final result = await gameService.isHostInMatch('player_001');

        expect(result, isTrue);
        verify(mockMatchmakingService.isHostInMatch('player_001')).called(1);
      });

      test('watchMatchmaking をリクエストすると MatchmakingService に委譲される', () {
        when(mockMatchmakingService.watchMatchmaking('player_001'))
            .thenAnswer((_) => Stream.value('match_001'));

        final stream = gameService.watchMatchmaking('player_001');

        expect(stream, isNotNull);
        verify(mockMatchmakingService.watchMatchmaking('player_001')).called(1);
      });
    });

    group('ゲーム進行メソッド', () {
      test('rollDice をリクエストすると GameFlowService に委譲される', () async {
        when(mockGameFlowService.rollDice('ROOM_CODE', 'player_001'))
            .thenAnswer((_) async => null);

        await gameService.rollDice('ROOM_CODE', 'player_001');

        verify(mockGameFlowService.rollDice('ROOM_CODE', 'player_001')).called(1);
      });

      test('placeBets をリクエストすると GameFlowService に委譲される', () async {
        final bets = {'cat_001': 5, 'cat_002': 3};
        when(mockGameFlowService.placeBets('ROOM_CODE', 'player_001', bets))
            .thenAnswer((_) async => null);

        await gameService.placeBets('ROOM_CODE', 'player_001', bets);

        verify(mockGameFlowService.placeBets('ROOM_CODE', 'player_001', bets))
            .called(1);
      });

      test('confirmRoll をリクエストすると GameFlowService に委譲される', () async {
        when(mockGameFlowService.confirmRoll('ROOM_CODE', 'player_001'))
            .thenAnswer((_) async => null);

        await gameService.confirmRoll('ROOM_CODE', 'player_001');

        verify(mockGameFlowService.confirmRoll('ROOM_CODE', 'player_001')).called(1);
      });

      test('nextTurn をリクエストすると GameFlowService に委譲される', () async {
        when(mockGameFlowService.nextTurn('ROOM_CODE', 'player_001'))
            .thenAnswer((_) async => null);

        await gameService.nextTurn('ROOM_CODE', 'player_001');

        verify(mockGameFlowService.nextTurn('ROOM_CODE', 'player_001')).called(1);
      });
    });

    group('ファサードの委譲機能', () {
      test('複数のメソッドが正しいサービスに委譲される', () async {
        when(mockRoomService.generateRoomCode()).thenReturn('TEST123');
        when(mockRoomService.createRoom('host_001'))
            .thenAnswer((_) async => 'TEST123');
        when(mockMatchmakingService.joinMatchmaking('player_001'))
            .thenAnswer((_) async => 'match_001');

        final roomCode = gameService.generateRoomCode();
        await gameService.createRoom('host_001');
        await gameService.joinMatchmaking('player_001');

        verify(mockRoomService.generateRoomCode()).called(1);
        verify(mockRoomService.createRoom('host_001')).called(1);
        verify(mockMatchmakingService.joinMatchmaking('player_001')).called(1);
      });

      test('各サービスが独立して動作する', () async {
        when(mockRoomService.createRoom('host_001'))
            .thenAnswer((_) async => 'ROOM_A');
        when(mockGameFlowService.rollDice('ROOM_A', 'player_001'))
            .thenAnswer((_) async => null);

        await gameService.createRoom('host_001');
        await gameService.rollDice('ROOM_A', 'player_001');

        verifyInOrder([
          mockRoomService.createRoom('host_001'),
          mockGameFlowService.rollDice('ROOM_A', 'player_001'),
        ]);
      });
    });

    group('統合テスト', () {
      test('ルーム作成からゲーム開始までの流れ', () async {
        when(mockRoomService.generateRoomCode()).thenReturn('GAME_001');
        when(mockRoomService.createRoom('host_001'))
            .thenAnswer((_) async => 'GAME_001');
        when(mockRoomService.joinRoom('GAME_001', 'guest_001'))
            .thenAnswer((_) async => true);
        when(mockGameFlowService.rollDice('GAME_001', 'host_001'))
            .thenAnswer((_) async => null);

        final code = gameService.generateRoomCode();
        await gameService.createRoom('host_001');
        await gameService.joinRoom(code, 'guest_001');
        await gameService.rollDice(code, 'host_001');

        expect(code, equals('GAME_001'));
        verifyInOrder([
          mockRoomService.generateRoomCode(),
          mockRoomService.createRoom('host_001'),
          mockRoomService.joinRoom(code, 'guest_001'),
          mockGameFlowService.rollDice(code, 'host_001'),
        ]);
      });

      test('マッチングからゲーム開始までの流れ', () async {
        when(mockMatchmakingService.joinMatchmaking('player_001'))
            .thenAnswer((_) async => 'match_001');
        when(mockGameFlowService.rollDice('matched_room', 'player_001'))
            .thenAnswer((_) async => null);

        await gameService.joinMatchmaking('player_001');
        await gameService.rollDice('matched_room', 'player_001');

        verifyInOrder([
          mockMatchmakingService.joinMatchmaking('player_001'),
          mockGameFlowService.rollDice('matched_room', 'player_001'),
        ]);
      });
    });

    group('エッジケース', () {
      test('null 以外のコンテキストでメソッドが呼ばれる', () async {
        when(mockRoomService.createRoom(''))
            .thenAnswer((_) async => '');

        await gameService.createRoom('');

        verify(mockRoomService.createRoom('')).called(1);
      });

      test('複数プレイヤーのアクション処理', () async {
        final bets1 = {'cat_001': 5};
        final bets2 = {'cat_001': 3, 'cat_002': 2};
        when(mockGameFlowService.placeBets('ROOM_CODE', 'player_1', bets1))
            .thenAnswer((_) async => null);
        when(mockGameFlowService.placeBets('ROOM_CODE', 'player_2', bets2))
            .thenAnswer((_) async => null);

        await gameService.placeBets('ROOM_CODE', 'player_1', bets1);
        await gameService.placeBets('ROOM_CODE', 'player_2', bets2);

        verifyInOrder([
          mockGameFlowService.placeBets('ROOM_CODE', 'player_1', bets1),
          mockGameFlowService.placeBets('ROOM_CODE', 'player_2', bets2),
        ]);
      });

      test('大きな roomCode 値での処理', () async {
        final largeCode = 'X' * 100;
        when(mockRoomService.joinRoom(largeCode, 'player_001'))
            .thenAnswer((_) async => true);

        await gameService.joinRoom(largeCode, 'player_001');

        verify(mockRoomService.joinRoom(largeCode, 'player_001')).called(1);
      });

      test('多くのベット情報の処理', () async {
        final largeBets = {
          for (int i = 0; i < 50; i++) 'cat_$i': i + 1
        };
        when(mockGameFlowService.placeBets('ROOM_CODE', 'player_001', largeBets))
            .thenAnswer((_) async => null);

        await gameService.placeBets('ROOM_CODE', 'player_001', largeBets);

        verify(mockGameFlowService.placeBets('ROOM_CODE', 'player_001', largeBets))
            .called(1);
      });
    });

    group('API 契約の検証', () {
      test('すべてのルーム管理メソッドが提供される', () {
        expect(gameService.generateRoomCode, isNotNull);
        expect(gameService.createRoom, isNotNull);
        expect(gameService.joinRoom, isNotNull);
        expect(gameService.watchRoom, isNotNull);
        expect(gameService.leaveRoom, isNotNull);
        expect(gameService.deleteRoom, isNotNull);
      });

      test('すべてのマッチングメソッドが提供される', () {
        expect(gameService.joinMatchmaking, isNotNull);
        expect(gameService.watchMatchmaking, isNotNull);
        expect(gameService.cancelMatchmaking, isNotNull);
        expect(gameService.isHostInMatch, isNotNull);
      });

      test('すべてのゲーム進行メソッドが提供される', () {
        expect(gameService.rollDice, isNotNull);
        expect(gameService.placeBets, isNotNull);
        expect(gameService.confirmRoll, isNotNull);
        expect(gameService.nextTurn, isNotNull);
      });
    });
  });
}
