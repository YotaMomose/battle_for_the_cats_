import '../models/game_room.dart';
import '../repositories/firestore_repository.dart';
import '../repositories/room_repository.dart';
import 'game_flow_service.dart';
import 'matchmaking_service.dart';
import 'room_service.dart';

/// ゲームサービスのファサード　複数のクラスやオブジェクトから構成される複雑な処理を、一つのシンプルなクラス（ファサード）に集約する
/// 各専門サービスへのアクセスを提供
class GameService {
  late final RoomService _roomService;
  late final MatchmakingService _matchmakingService;
  late final GameFlowService _gameFlowService;

  GameService() {
    final firestoreRepository = FirestoreRepository();
    final roomRepository = RoomRepository(repository: firestoreRepository);

    _roomService = RoomService(repository: roomRepository);
    _matchmakingService = MatchmakingService(
      repository: firestoreRepository,
      roomService: _roomService,
    );
    _gameFlowService = GameFlowService(repository: roomRepository);
  }

  // ルーム管理
  String generateRoomCode() => _roomService.generateRoomCode();
  Future<String> createRoom(String hostId) => _roomService.createRoom(hostId);
  Future<bool> joinRoom(String roomCode, String guestId) =>
      _roomService.joinRoom(roomCode, guestId);
  Stream<GameRoom> watchRoom(String roomCode) =>
      _roomService.watchRoom(roomCode);
  Future<void> deleteRoom(String roomCode) => _roomService.deleteRoom(roomCode);

  // マッチング
  Future<String> joinMatchmaking(String playerId) =>
      _matchmakingService.joinMatchmaking(playerId);
  Stream<String?> watchMatchmaking(String playerId) =>
      _matchmakingService.watchMatchmaking(playerId);
  Future<void> cancelMatchmaking(String playerId) =>
      _matchmakingService.cancelMatchmaking(playerId);
  Future<bool> isHostInMatch(String playerId) =>
      _matchmakingService.isHostInMatch(playerId);

  // ゲーム進行
  Future<void> rollDice(String roomCode, String playerId) =>
      _gameFlowService.rollDice(roomCode, playerId);
  Future<void> placeBets(
    String roomCode,
    String playerId,
    Map<String, int> bets,
  ) => _gameFlowService.placeBets(roomCode, playerId, bets);
  Future<void> confirmRoll(String roomCode, String playerId) =>
      _gameFlowService.confirmRoll(roomCode, playerId);
  Future<void> nextTurn(String roomCode, String playerId) =>
      _gameFlowService.nextTurn(roomCode, playerId);
}
