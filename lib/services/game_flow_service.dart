import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/game_constants.dart';
import '../models/cards/round_cards.dart';
import '../models/game_room.dart';
import '../models/item.dart';
import '../domain/dice.dart';
import '../repositories/room_repository.dart';

/// ゲーム進行（サイコロ、賭け、ターン進行）を担当するサービス
class GameFlowService {
  final RoomRepository _repository;
  final Dice _dice;
  final Random _random;

  GameFlowService({required RoomRepository repository, Dice? dice})
    : _repository = repository,
      _dice = dice ?? StandardDice(),
      _random = Random();

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

      // 両者が確認済みになったら、次のターンの準備、あるいはイベント発生
      if (room.bothConfirmedRoundResult &&
          room.status == GameStatus.roundResult) {
        // 50%の確率で太っちょネコイベント発生
        if (_random.nextDouble() < GameConstants.fatCatEventProbability) {
          room.status = GameStatus.fatCatEvent;
          // 両者の魚を没収
          room.host.fishCount = 0;
          if (room.guest != null) {
            room.guest!.fishCount = 0;
          }
        } else {
          // 通常通り次へ
          room.prepareNextTurn(RoundCards.random());
        }
      }

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
      if (room.status != GameStatus.fatCatEvent) return;

      final isHost = room.isHost(playerId);
      final player = isHost ? room.host : room.guest;
      if (player != null) {
        player.confirmedFatCatEvent = true;
      }

      // 両者が確認済みになったら、次のターンの準備をする
      if (room.bothConfirmedFatCatEvent) {
        room.prepareNextTurn(RoundCards.random());
      }

      transaction.update(roomRef, room.toMap());
    });
  }
}
