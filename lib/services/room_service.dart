import '../constants/game_constants.dart';
import '../models/cards/round_cards.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../repositories/room_repository.dart';
import '../models/item.dart';
import '../models/chased_card_info.dart';
import '../domain/win_condition.dart';

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

  /// アイテムを復活させる
  Future<void> reviveItem(
    String roomCode,
    String playerId,
    ItemType itemType,
  ) async {
    await _repository.runTransaction((transaction) async {
      final room = await _repository.getRoomInTransaction(
        transaction,
        roomCode,
      );
      if (room == null) throw Exception('Room not found');

      final isHost = _repository.isHost(room, playerId);
      final player = isHost ? room.host : room.guest;

      if (player == null) throw Exception('Player not found');

      if (player.pendingItemRevivals <= 0) {
        throw Exception('No pending item revivals');
      }

      // アイテムを追加
      player.items.add(itemType);
      player.pendingItemRevivals--;

      _repository.updateRoomInTransaction(transaction, roomCode, {
        isHost ? 'host' : 'guest': player.toMap(),
      });
    });
  }

  /// キャラクターを追い出す（犬の効果）
  Future<void> chaseAwayCard(
    String roomCode,
    String playerId,
    String? targetCardName,
  ) async {
    await _repository.runTransaction((transaction) async {
      final room = await _repository.getRoomInTransaction(
        transaction,
        roomCode,
      );
      if (room == null) throw Exception('Room not found');

      final isHost = _repository.isHost(room, playerId);
      final player = isHost ? room.host : room.guest;
      final opponent = isHost ? room.guest : room.host;

      if (player == null || opponent == null)
        throw Exception('Player or Opponent not found');

      if (player.pendingDogChases <= 0) {
        throw Exception('No pending dog chases');
      }

      // 相手のインベントリから削除（ターゲットが指定されている場合のみ）
      if (targetCardName != null && targetCardName.isNotEmpty) {
        opponent.catsWon.removeByName(targetCardName);

        // 通知用に記録
        room.chasedCards.add(
          ChasedCardInfo(cardName: targetCardName, chaserPlayerId: playerId),
        );
        player.pendingDogChases--;
      } else {
        // スキップの場合は残りすべての回数をクリア
        player.pendingDogChases = 0;
      }

      // 勝利条件の再評価
      final hasPendingEffects =
          room.host.pendingDogChases > 0 ||
          (room.guest?.pendingDogChases ?? 0) > 0;

      if (!hasPendingEffects) {
        final condition = StandardWinCondition();
        room.finalWinner = condition.determineFinalWinner(
          room.host,
          room.guest!,
        );
        if (room.finalWinner != null) {
          room.status = GameStatus.finished;
        }
      }

      _repository.updateRoomInTransaction(transaction, roomCode, {
        'host': room.host.toMap(),
        'guest': room.guest?.toMap(),
        'finalWinner': room.finalWinner?.value,
        'status': room.status.value,
        'chasedCards': room.chasedCards.map((c) => c.toMap()).toList(),
      });
    });
  }

  /// プレイヤーがホストかどうかを判定
  bool isHost(GameRoom room, String playerId) {
    return _repository.isHost(room, playerId);
  }
}
