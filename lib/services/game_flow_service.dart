import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/game_constants.dart';
import '../models/cards/round_cards.dart';
import '../models/game_room.dart';
import '../domain/dice.dart';
import '../repositories/room_repository.dart';

/// ゲーム進行（サイコロ、賭け、ターン進行）を担当するサービス
class GameFlowService {
  final RoomRepository _repository;
  final Dice _dice;

  GameFlowService({required RoomRepository repository, Dice? dice})
    : _repository = repository,
      _dice = dice ?? StandardDice();

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
  ) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = room.isHost(playerId);
    final player = isHost ? room.host : room.guest;
    if (player == null) return;

    player.placeBets(bets);

    // 両者が準備完了したか確認
    if (room.canStartRound) {
      await _resolveRound(roomCode, room);
    } else {
      await _repository.updateRoom(roomCode, room.toMap());
    }
  }

  /// ラウンド結果を判定
  Future<void> _resolveRound(String roomCode, GameRoom room) async {
    room.resolveRound();

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

      // 自分の確認フラグを立てる
      final isHost = room.isHost(playerId);
      final player = isHost ? room.host : room.guest;
      if (player != null) {
        player.confirmedRoundResult = true;
      }

      // 両者が確認済みになったら、次のターンの準備をする
      if (room.bothConfirmedRoundResult &&
          room.status == GameStatus.roundResult) {
        room.prepareNextTurn(RoundCards.random());
      }

      transaction.update(roomRef, room.toMap());
    });
  }
}
