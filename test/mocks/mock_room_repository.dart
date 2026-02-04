import 'package:mockito/mockito.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/repositories/room_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// MockRoomRepository: RoomRepositoryをモック化して、メソッド呼び出しやパラメータを検証
class MockRoomRepository extends Mock implements RoomRepository {
  /// 保存されたルームの辞書
  final Map<String, GameRoom> _rooms = {};

  /// getRoom呼び出しの履歴（テスト検証用）
  final List<String> getCallHistory = [];

  /// createRoom呼び出しの履歴（テスト検証用）
  final List<GameRoom> createCallHistory = [];

  /// updateRoom呼び出しの履歴（テスト検証用）
  final List<(String, GameRoom)> updateCallHistory = [];

  /// deleteRoom呼び出しの履歴（テスト検証用）
  final List<String> deleteCallHistory = [];

  /// getCallHistoryの呼び出し数を取得
  int get getRoomCallCount => getCallHistory.length;

  /// createRoomの呼び出し数を取得
  int get createRoomCallCount => createCallHistory.length;

  /// updateRoomの呼び出し数を取得
  int get updateRoomCallCount => updateCallHistory.length;

  /// deleteRoomの呼び出し数を取得
  int get deleteRoomCallCount => deleteCallHistory.length;

  /// 履歴をすべてリセット（各テスト後）
  void resetCallHistories() {
    getCallHistory.clear();
    createCallHistory.clear();
    updateCallHistory.clear();
    deleteCallHistory.clear();
  }

  /// モックのgetRoom実装
  @override
  Future<GameRoom?> getRoom(String roomId) async {
    getCallHistory.add(roomId);
    return _rooms[roomId];
  }

  /// モックのcreateRoom実装
  @override
  Future<void> createRoom(GameRoom room) async {
    createCallHistory.add(room);
    _rooms[room.roomId] = room;
  }

  /// モックのupdateRoom実装
  @override
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    updateCallHistory.add((roomId, _rooms[roomId]!));
    // 実装では Firestore を更新するため、ここではメモリ内のデータは更新しない
  }

  /// モックのdeleteRoom実装
  @override
  Future<void> deleteRoom(String roomId) async {
    deleteCallHistory.add(roomId);
    _rooms.remove(roomId);
  }

  /// モックのrunTransaction実装
  /// トランザクションをシミュレートするため、同期的に処理を実行
  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    // テスト環境では、トランザクションオブジェクトは実際には使用されない
    // RoomServiceのleaveRoomメソッドは、トランザクション内でRepositoryのメソッドを呼び出すだけ
    // そのため、nullを渡しても問題ない（ただし、型チェックを回避するためにdynamicを使用）
    return await transactionHandler(null as dynamic);
  }

  /// モックのgetRoomInTransaction実装
  @override
  Future<GameRoom?> getRoomInTransaction(
    Transaction transaction,
    String roomCode,
  ) async {
    return _rooms[roomCode];
  }

  /// モックのupdateRoomInTransaction実装
  @override
  void updateRoomInTransaction(
    Transaction transaction,
    String roomCode,
    Map<String, dynamic> data,
  ) {
    final room = _rooms[roomCode];
    if (room == null) return;

    // abandonedフラグの更新をシミュレート
    if (data.containsKey('host.abandoned')) {
      room.host.abandoned = data['host.abandoned'] as bool;
    }
    if (data.containsKey('guest.abandoned') && room.guest != null) {
      room.guest!.abandoned = data['guest.abandoned'] as bool;
    }
  }

  /// モックのdeleteRoomInTransaction実装
  @override
  void deleteRoomInTransaction(Transaction transaction, String roomCode) {
    deleteCallHistory.add(roomCode);
    _rooms.remove(roomCode);
  }

  /// モックのisHost実装
  @override
  bool isHost(GameRoom room, String playerId) {
    return room.hostId == playerId;
  }
}
