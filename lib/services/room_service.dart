import '../constants/game_constants.dart';
import '../domain/game_logic.dart';
import '../models/game_room.dart';
import '../repositories/room_repository.dart';

/// ルーム管理を担当するサービス
class RoomService {
  final RoomRepository _repository;
  final GameLogic _gameLogic;

  RoomService({required RoomRepository repository, GameLogic? gameLogic})
    : _repository = repository,
      _gameLogic = gameLogic ?? GameLogic();

  /// ルームコードを生成
  String generateRoomCode() {
    return _gameLogic.generateRoomCode();
  }

  /// ルームを作成
  Future<String> createRoom(String hostId) async {
    String roomCode;
    // 重複チェック: 生成されたコードが既に存在する場合は再生成
    do {
      roomCode = generateRoomCode();
    } while (await _repository.getRoom(roomCode) != null);

    final cats = _gameLogic.generateRandomCats();
    final catCosts = _gameLogic.generateRandomCosts(cats.length);
    final room = GameRoom(
      roomId: roomCode,
      hostId: hostId,
      cats: cats,
      catCosts: catCosts,
    );

    await _repository.createRoom(room);
    return roomCode;
  }

  /// ルームに参加
  Future<bool> joinRoom(String roomCode, String guestId) async {
    final room = await _repository.getRoom(roomCode);

    if (room == null) {
      return false; // ルームが存在しない
    }

    if (room.guestId != null) {
      return false; // すでにゲストがいる
    }

    await _repository.updateRoom(roomCode, {
      'guestId': guestId,
      'status': GameStatus.rolling.value, // サイコロフェーズから開始
    });

    return true;
  }

  /// ルームを監視
  Stream<GameRoom?> watchRoom(String roomCode) {
    return _repository.watchRoom(roomCode);
  }

  /// ルームを退出する（削除ではなく、フラグを立てる）
  Future<void> leaveRoom(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = _repository.isHost(room, playerId);
    await _repository.updateRoom(roomCode, {
      isHost ? 'hostAbandoned' : 'guestAbandoned': true,
    });
  }

  /// ルームを削除
  Future<void> deleteRoom(String roomCode) async {
    await _repository.deleteRoom(roomCode);
  }

  /// プレイヤーがホストかどうかを判定
  bool isHost(GameRoom room, String playerId) {
    return _repository.isHost(room, playerId);
  }
}
