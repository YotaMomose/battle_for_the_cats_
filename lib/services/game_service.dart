import '../models/game_room.dart';
import '../repositories/firestore_repository.dart';
import '../repositories/room_repository.dart';
import 'game_flow_service.dart';
import 'matchmaking_service.dart';
import 'room_service.dart';
import '../models/match_result.dart';
import '../models/item.dart';

/// ゲームサービスのファサード　複数のクラスやオブジェクトから構成される複雑な処理を、一つのシンプルなクラス（ファサード）に集約する
/// 各専門サービスへのアクセスを提供
class GameService {
  late final RoomService _roomService;
  late final MatchmakingService _matchmakingService;
  late final GameFlowService _gameFlowService;

  // テスト用の依存注入コンストラクタ
  GameService({
    FirestoreRepository? firestoreRepository,
    RoomService? roomService,
    MatchmakingService? matchmakingService,
    GameFlowService? gameFlowService,
  }) {
    if (roomService != null &&
        matchmakingService != null &&
        gameFlowService != null) {
      // テストから直接サービスが提供された場合
      _roomService = roomService;
      _matchmakingService = matchmakingService;
      _gameFlowService = gameFlowService;
    } else {
      // 通常使用時（本番環境）
      final repo = firestoreRepository ?? FirestoreRepository();
      final roomRepo = RoomRepository(repository: repo);

      _roomService = RoomService(repository: roomRepo);
      _matchmakingService = MatchmakingService(
        repository: repo,
        roomService: _roomService,
      );
      _gameFlowService = GameFlowService(repository: roomRepo);
    }
  }

  // ルーム管理
  String generateRoomCode() => _roomService.generateRoomCode();
  Future<String> createRoom(String hostId) => _roomService.createRoom(hostId);
  Future<bool> joinRoom(String roomCode, String guestId) =>
      _roomService.joinRoom(roomCode, guestId);
  Stream<GameRoom?> watchRoom(String roomCode) =>
      _roomService.watchRoom(roomCode);
  Future<void> leaveRoom(String roomCode, String playerId) =>
      _roomService.leaveRoom(roomCode, playerId);
  Future<void> deleteRoom(String roomCode) => _roomService.deleteRoom(roomCode);

  // マッチング
  Future<String> joinMatchmaking(String playerId) =>
      _matchmakingService.joinMatchmaking(playerId);
  Stream<MatchResult?> watchMatchmaking(String playerId) =>
      _matchmakingService.watchMatchmaking(playerId);
  Future<void> cancelMatchmaking(String playerId) =>
      _matchmakingService.cancelMatchmaking(playerId);
  Future<bool> isHostInMatch(String playerId) =>
      _matchmakingService.isHostInMatch(playerId);

  // ゲーム進行
  Future<void> reviveItem(
    String roomCode,
    String playerId,
    ItemType itemType,
  ) => _roomService.reviveItem(roomCode, playerId, itemType);

  Future<void> rollDice(String roomCode, String playerId) =>
      _gameFlowService.rollDice(roomCode, playerId);
  Future<void> placeBets(
    String roomCode,
    String playerId,
    Map<String, int> bets,
    Map<String, String?> itemPlacements,
  ) => _gameFlowService.placeBets(roomCode, playerId, bets, itemPlacements);
  Future<void> confirmRoll(String roomCode, String playerId) =>
      _gameFlowService.confirmRoll(roomCode, playerId);
  Future<void> nextTurn(String roomCode, String playerId) =>
      _gameFlowService.nextTurn(roomCode, playerId);
}
