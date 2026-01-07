import '../constants/game_constants.dart';
import '../domain/game_logic.dart';
import '../models/game_room.dart';
import '../repositories/firestore_repository.dart';
import 'room_service.dart';

/// マッチング処理を担当するサービス
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
      if (!snapshot.exists || snapshot.data() == null) {
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

  /// 相手を探してマッチング試行（トランザクションで制御）
  Future<void> _tryToMatch(String playerId) async {
    try {
      // 待機中のプレイヤーを検索
      final querySnapshot = await _repository.query(
        _collection,
        filters: [QueryFilter('status', MatchmakingStatus.waiting.value)],
        orderByField: 'timestamp',
        limit: GameConstants.matchmakingSearchLimit,
      );

      // 自分以外の最初の相手を探す
      String? opponentId;
      for (final doc in querySnapshot.docs) {
        if (doc.id != playerId) {
          opponentId = doc.id;
          break;
        }
      }

      // 相手が見つからない場合は何もしない
      if (opponentId == null) {
        return;
      }

      // トランザクションでマッチング処理
      await _repository.runTransaction((transaction) async {
        final myRef = _repository.getDocumentReference(_collection, playerId);
        final opponentRef = _repository.getDocumentReference(
          _collection,
          opponentId!,
        );

        final myDoc = await transaction.get(myRef);
        final opponentDoc = await transaction.get(opponentRef);

        // どちらかが既にマッチング済みの場合は中断
        if (!myDoc.exists || !opponentDoc.exists) {
          return;
        }

        final myStatus = myDoc.data()?['status'];
        final opponentStatus = opponentDoc.data()?['status'];

        if (myStatus != MatchmakingStatus.waiting.value ||
            opponentStatus != MatchmakingStatus.waiting.value) {
          return;
        }

        // ルームを作成
        final roomCode = _roomService.generateRoomCode();
        final cats = _gameLogic.generateRandomCats();
        final catCosts = _gameLogic.generateRandomCosts(cats.length);
        final room = GameRoom(
          roomId: roomCode,
          hostId: playerId,
          guestId: opponentId,
          status: GameStatus.rolling.value, // サイコロフェーズから開始
          cats: cats,
          catCosts: catCosts,
        );

        // トランザクション内でルームを作成
        final roomRef = _repository.getDocumentReference('rooms', roomCode);
        transaction.set(roomRef, room.toMap());

        // 両プレイヤーのマッチング状態を更新
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
      });
    } catch (e) {
      // トランザクション失敗（競合が発生した場合など）
      // 何もせずに次の監視サイクルで再試行
    }
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
