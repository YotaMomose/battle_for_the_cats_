import '../constants/game_constants.dart';
import '../models/cards/round_cards.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../repositories/room_repository.dart';

/// ルーム管理を担当するサービス
class RoomService {
  final RoomRepository _repository;

  RoomService({required RoomRepository repository}) : _repository = repository;

  /// ルームコードを生成
  String generateRoomCode() {
    return GameRoom.generateRandomId();
  }

  /// ルームを作成
  Future<String> createRoom(String hostId) async {
    String roomCode;
    // 重複チェック: 生成されたコードが既に存在する場合は再生成
    do {
      roomCode = generateRoomCode();
    } while (await _repository.getRoom(roomCode) != null);

    final room = GameRoom(
      roomId: roomCode,
      host: Player(id: hostId),
      currentRound: RoundCards.random(),
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
      'guest': Player(id: guestId).toMap(),
      'status': GameStatus.rolling.value, // サイコロフェーズから開始
    });

    return true;
  }

  /// ルームを監視
  Stream<GameRoom?> watchRoom(String roomCode) {
    return _repository.watchRoom(roomCode);
  }

  /// ルームを退出する
  /// 両プレイヤーが退出した場合、または待機中にホストが退出した場合にはルームを削除する
  /// トランザクションを使用して整合性を担保する
  Future<void> leaveRoom(String roomCode, String playerId) async {
    await _repository.runTransaction((transaction) async {
      final room = await _repository.getRoomInTransaction(
        transaction,
        roomCode,
      );
      if (room == null) return;

      final isHost = _repository.isHost(room, playerId);

      if (_shouldDeleteRoom(room, isHost)) {
        _repository.deleteRoomInTransaction(transaction, roomCode);
      } else {
        _repository.updateRoomInTransaction(transaction, roomCode, {
          '${isHost ? 'host' : 'guest'}.abandoned': true,
        });
      }
    });
  }

  /// ルームを削除すべきかどうかを判定
  bool _shouldDeleteRoom(GameRoom room, bool isHost) {
    // 両方のプレイヤーが退出済みの場合は必ず削除
    final hostAbandoned = room.host.abandoned;
    final guestAbandoned = room.guest?.abandoned ?? false;

    if (hostAbandoned && guestAbandoned) {
      print('[RoomService] 両プレイヤーが退出済み - ルームを削除します');
      return true;
    }

    if (isHost) {
      // ホストが退出する場合
      // - ゲストがいない（待機中）
      // - ゲストが既に退出済み
      final shouldDelete = room.guest == null || guestAbandoned;
      return shouldDelete;
    } else {
      // ゲストが退出する場合
      // - ホストが既に退出済み
      final shouldDelete = hostAbandoned;
      return shouldDelete;
    }
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
