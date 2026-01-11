import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/game_constants.dart';
import '../domain/game_logic.dart';
import '../models/game_room.dart';
import '../repositories/firestore_repository.dart';
import 'room_service.dart';

/// ランダムマッチング処理を担当するサービス
class MatchmakingService {
  final FirestoreRepository _repository;
  final RoomService _roomService;
  final GameLogic _gameLogic;
  static const String _collection = 'matchmaking';

  MatchmakingService({
    required FirestoreRepository repository,
    required RoomService roomService,
    GameLogic? gameLogic,
  }) : _repository = repository,
       _roomService = roomService,
       _gameLogic = gameLogic ?? GameLogic();

  /// 待機リストに登録
  Future<String> joinMatchmaking(String playerId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _repository.setDocument(_collection, playerId, {
      'playerId': playerId,
      'timestamp': timestamp,
      'status': MatchmakingStatus.waiting.value,
    });

    return playerId;
  }

  /// マッチングを監視
  Stream<String?> watchMatchmaking(String playerId) async* {
    await for (final snapshot in _repository.watchDocument(
      _collection,
      playerId,
    )) {
      if (!_isValidSnapshot(snapshot)) {
        yield null;
        return;
      }

      final data = snapshot.data()!;
      final status = MatchmakingStatus.fromString(data['status'] as String);

      // マッチング成立した場合
      if (status == MatchmakingStatus.matched) {
        final roomCode = data['roomCode'] as String?;
        yield roomCode;
        return;
      }

      // まだ待機中の場合、自分から相手を探す
      if (status == MatchmakingStatus.waiting) {
        await _tryToMatch(playerId);
        yield null; // まだマッチングしていない
      }
    }
  }

  bool _isValidSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.exists && snapshot.data() != null;
  }

  /// 相手を探してマッチング試行（トランザクションで制御）
  Future<void> _tryToMatch(String playerId) async {
    try {
      final opponentId = await _findOpponent(playerId);
      if (opponentId == null) return;

      await _executeMatchTransaction(playerId, opponentId);
    } catch (e) {
      // トランザクション失敗（競合が発生した場合など）
      // 何もせずに次の監視サイクルで再試行
    }
  }

  /// 対戦相手候補を検索
  Future<String?> _findOpponent(String playerId) async {
    final querySnapshot = await _repository.query(
      _collection,
      filters: [QueryFilter('status', MatchmakingStatus.waiting.value)],
      orderByField: 'timestamp',
      limit: GameConstants.matchmakingSearchLimit,
    );

    for (final doc in querySnapshot.docs) {
      if (doc.id != playerId) {
        return doc.id;
      }
    }
    return null;
  }

  /// マッチング確定トランザクション実行
  Future<void> _executeMatchTransaction(
    String playerId,
    String opponentId,
  ) async {
    await _repository.runTransaction((transaction) async {
      final myRef = _repository.getDocumentReference(_collection, playerId);
      final opponentRef = _repository.getDocumentReference(
        _collection,
        opponentId,
      );

      final myDoc = await transaction.get(myRef);
      final opponentDoc = await transaction.get(opponentRef);

      // マッチング可能な状態か検証
      if (!_canMatch(myDoc, opponentDoc)) {
        return;
      }

      // ルームを作成
      final roomCode = _roomService.generateRoomCode();
      final room = _createGameRoomObject(roomCode, playerId, opponentId);

      // トランザクション内でルームを保存
      _createRoomInTransaction(transaction, roomCode, room);

      // 両プレイヤーのマッチング状態を更新
      _updateMatchStatusInTransaction(
        transaction,
        myRef,
        opponentRef,
        roomCode,
      );
    });
  }

  /// マッチング可能か判定
  bool _canMatch(
    DocumentSnapshot<Map<String, dynamic>> myDoc,
    DocumentSnapshot<Map<String, dynamic>> opponentDoc,
  ) {
    if (!myDoc.exists || !opponentDoc.exists) return false;

    final myStatus = myDoc.data()?['status'];
    final opponentStatus = opponentDoc.data()?['status'];

    return myStatus == MatchmakingStatus.waiting.value &&
        opponentStatus == MatchmakingStatus.waiting.value;
  }

  /// GameRoomオブジェクトの生成
  GameRoom _createGameRoomObject(
    String roomCode,
    String hostId,
    String guestId,
  ) {
    final cats = _gameLogic.generateRandomCats();
    final catCosts = _gameLogic.generateRandomCosts(cats.length);

    return GameRoom(
      roomId: roomCode,
      hostId: hostId,
      guestId: guestId,
      status: GameStatus.rolling.value, // サイコロフェーズから開始
      cats: cats,
      catCosts: catCosts,
    );
  }

  /// トランザクション内でのルーム作成
  void _createRoomInTransaction(
    Transaction transaction,
    String roomCode,
    GameRoom room,
  ) {
    final roomRef = _repository.getDocumentReference('rooms', roomCode);
    transaction.set(roomRef, room.toMap());
  }

  /// トランザクション内でのステータス更新
  void _updateMatchStatusInTransaction(
    Transaction transaction,
    DocumentReference myRef,
    DocumentReference opponentRef,
    String roomCode,
  ) {
    transaction.update(myRef, {
      'status': MatchmakingStatus.matched.value,
      'roomCode': roomCode,
      'isHost': true,
    });

    transaction.update(opponentRef, {
      'status': MatchmakingStatus.matched.value,
      'roomCode': roomCode,
      'isHost': false,
    });
  }

  /// マッチングをキャンセル
  Future<void> cancelMatchmaking(String playerId) async {
    await _repository.deleteDocument(_collection, playerId);
  }

  /// マッチング情報からホストかどうかを取得
  Future<bool> isHostInMatch(String playerId) async {
    final doc = await _repository.getDocument(_collection, playerId);
    return doc.data()?['isHost'] as bool? ?? true;
  }
}
