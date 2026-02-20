import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:battle_for_the_cats/services/game_flow_service.dart';
import 'package:battle_for_the_cats/services/game_service.dart';
import 'package:battle_for_the_cats/services/matchmaking_service.dart';
import 'package:battle_for_the_cats/services/room_service.dart';

import 'package:mockito/annotations.dart';
import 'game_service_test.mocks.dart';

@GenerateMocks([RoomService, MatchmakingService, GameFlowService])
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
        when(
          mockRoomService.createRoom(
            'host_001',
            displayName: anyNamed('displayName'),
            iconId: anyNamed('iconId'),
          ),
        ).thenAnswer((_) async => 'ROOM_CODE_001');

        final result = await gameService.createRoom(
          'host_001',
          displayName: 'Name',
          iconId: 'Icon',
        );

        expect(result, equals('ROOM_CODE_001'));
        verify(
          mockRoomService.createRoom(
            'host_001',
            displayName: 'Name',
            iconId: 'Icon',
          ),
        ).called(1);
      });

      test('joinRoom をリクエストすると RoomService に委譲される', () async {
        when(
          mockRoomService.joinRoom(
            'ROOM_CODE',
            'guest_001',
            displayName: anyNamed('displayName'),
            iconId: anyNamed('iconId'),
          ),
        ).thenAnswer((_) async => true);

        final result = await gameService.joinRoom(
          'ROOM_CODE',
          'guest_001',
          displayName: 'Name',
          iconId: 'Icon',
        );

        expect(result, isTrue);
        verify(
          mockRoomService.joinRoom(
            'ROOM_CODE',
            'guest_001',
            displayName: 'Name',
            iconId: 'Icon',
          ),
        ).called(1);
      });
    });

    group('ゲーム進行メソッド', () {
      test('rollDice をリクエストすると GameFlowService に委譲される', () async {
        await gameService.rollDice('ROOM_CODE', 'player_001');
        verify(
          mockGameFlowService.rollDice('ROOM_CODE', 'player_001'),
        ).called(1);
      });

      test('placeBets をリクエストすると GameFlowService に委譲される', () async {
        final bets = {'cat_001': 5};
        final items = {'cat_001': 'catTeaser'};

        await gameService.placeBets('ROOM_CODE', 'player_001', bets, items);

        verify(
          mockGameFlowService.placeBets('ROOM_CODE', 'player_001', bets, items),
        ).called(1);
      });
    });

    group('エッジケース', () {
      test('複数プレイヤーのアクション処理', () async {
        final bets1 = {'cat_001': 5};
        final bets2 = {'cat_001': 3};
        final items = {'cat_001': null};

        await gameService.placeBets('ROOM_CODE', 'player_1', bets1, items);
        await gameService.placeBets('ROOM_CODE', 'player_2', bets2, items);

        verify(
          mockGameFlowService.placeBets('ROOM_CODE', 'player_1', bets1, items),
        ).called(1);
        verify(
          mockGameFlowService.placeBets('ROOM_CODE', 'player_2', bets2, items),
        ).called(1);
      });
    });
  });
}
