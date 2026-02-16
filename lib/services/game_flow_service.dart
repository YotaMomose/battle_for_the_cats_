import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/game_constants.dart';
import '../models/game_room.dart';
import '../models/item.dart';
import '../domain/dice.dart';
import '../domain/round_resolver.dart';
import '../repositories/room_repository.dart';

/// ゲーム進行（サイコロ、賭け、ターン進行）を担当するサービス
class GameFlowService {
  final RoomRepository _repository;
  final Dice _dice;
  final RoundResolver _roundResolver;

  GameFlowService({
    required RoomRepository repository,
    Dice? dice,
    RoundResolver? roundResolver,
  }) : _repository = repository,
       _dice = dice ?? StandardDice(),
       _roundResolver = roundResolver ?? RoundResolver();

  /// サイコロを振る
  Future<void> rollDice(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = room.isHost(playerId);
    final player = isHost ? room.host : room.guest;
    if (player == null) return;

    player.roll(_dice);

    await _repository.updateRoom(roomCode, room.toMap());
  }

  /// サイコロ結果を確認し、フェーズを進める準備をする
  Future<void> confirmRoll(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = room.isHost(playerId);
    final player = isHost ? room.host : room.guest;
    if (player == null) return;

    player.confirmedRoll = true;

    // 両者が確認済みになったら、ステータスを playing に変更
    if (room.bothConfirmedRoll) {
      room.status = GameStatus.playing;
    }

    await _repository.updateRoom(roomCode, room.toMap());
  }

  /// 魚を賭ける
  Future<void> placeBets(
    String roomCode,
    String playerId,
    Map<String, int> bets,
    Map<String, String?> itemPlacements,
  ) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final player = room.isHost(playerId) ? room.host : room.guest;
    if (player == null) return;

    final convertedItems = itemPlacements.map((key, value) {
      if (value == null) return MapEntry(key, null);
      return MapEntry(key, ItemType.fromString(value));
    });

    player.placeBetsWithItems(bets, convertedItems);

    // 両者が準備完了したか確認
    if (room.canStartRound) {
      await _resolveRound(roomCode, room);
    } else {
      await _repository.updateRoom(roomCode, room.toMap());
    }
  }

  /// ラウンド結果を判定
  Future<void> _resolveRound(String roomCode, GameRoom room) async {
    _roundResolver.resolve(room);

    await _repository.updateRoom(roomCode, room.toMap());
  }

  /// 次のターンへ進む（個別アクション）
  Future<void> nextTurn(String roomCode, String playerId) async {
    // トランザクションでアトミックに実行
    await _repository.runTransaction((Transaction transaction) async {
      final roomRef = _repository.firestoreRepository.getDocumentReference(
        'rooms',
        roomCode,
      );
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final room = GameRoom.fromMap(snapshot.data()!);

      // ドメイン層に確認と遷移を委譲
      room.confirmRoundResult(playerId);
      _roundResolver.advanceFromRoundResult(room);

      transaction.update(roomRef, room.toMap());
    });
  }

  /// 太っちょネコイベントを確認する
  Future<void> confirmFatCatEvent(String roomCode, String playerId) async {
    await _repository.runTransaction((Transaction transaction) async {
      final roomRef = _repository.firestoreRepository.getDocumentReference(
        'rooms',
        roomCode,
      );
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final room = GameRoom.fromMap(snapshot.data()!);

      // ドメイン層に確認と遷移を委譲
      room.confirmFatCatEvent(playerId);
      _roundResolver.advanceFromFatCatEvent(room);

      transaction.update(roomRef, room.toMap());
    });
  }
}
