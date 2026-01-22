import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';
import 'firestore_repository.dart';

/// ルームデータへのアクセスを担当
class RoomRepository {
  final FirestoreRepository _repository;
  static const String _collection = 'rooms';

  RoomRepository({required FirestoreRepository repository})
    : _repository = repository;

  FirestoreRepository get firestoreRepository => _repository;

  /// トランザクションを実行
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    return await _repository.runTransaction(transactionHandler);
  }

  /// ルームを取得
  Future<GameRoom?> getRoom(String roomCode) async {
    final doc = await _repository.getDocument(_collection, roomCode);

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return GameRoom.fromMap(doc.data()!);
  }

  /// ルームを作成
  Future<void> createRoom(GameRoom room) async {
    await _repository.setDocument(_collection, room.roomId, room.toMap());
  }

  /// ルームを更新
  Future<void> updateRoom(String roomCode, Map<String, dynamic> data) async {
    await _repository.updateDocument(_collection, roomCode, data);
  }

  /// ルームを削除
  Future<void> deleteRoom(String roomCode) async {
    await _repository.deleteDocument(_collection, roomCode);
  }

  /// ルームを監視
  Stream<GameRoom?> watchRoom(String roomCode) {
    return _repository.watchDocument(_collection, roomCode).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return GameRoom.fromMap(snapshot.data()!);
    });
  }

  /// プレイヤーがホストかどうかを判定
  bool isHost(GameRoom room, String playerId) {
    return room.hostId == playerId;
  }

  /// プレイヤー固有のフィールド名を取得（例: 'hostBets' or 'guestBets'）
  String getPlayerField(GameRoom room, String playerId, String fieldName) {
    final isHost = this.isHost(room, playerId);
    return isHost ? 'host$fieldName' : 'guest$fieldName';
  }

  /// プレイヤーのデータを更新
  Future<void> updatePlayerData(
    String roomCode,
    String playerId,
    Map<String, dynamic> data,
  ) async {
    final room = await getRoom(roomCode);
    if (room == null) return;

    final isHost = this.isHost(room, playerId);
    final prefix = isHost ? 'host' : 'guest';
    final prefixedData = <String, dynamic>{};

    for (final entry in data.entries) {
      // キャメルケースを維持しつつネストを表現 ('host.diceRoll' など)
      final field = entry.key;
      final lowercaseField = field[0].toLowerCase() + field.substring(1);
      prefixedData['$prefix.$lowercaseField'] = entry.value;
    }

    await updateRoom(roomCode, prefixedData);
  }
}
