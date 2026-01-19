import 'package:mockito/mockito.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/repositories/room_repository.dart';

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
}

