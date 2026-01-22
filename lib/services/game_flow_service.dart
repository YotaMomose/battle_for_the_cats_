import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/game_constants.dart';
import '../domain/game_logic.dart';
import '../models/game_room.dart';
import '../repositories/room_repository.dart';

/// ゲーム進行（サイコロ、賭け、ターン進行）を担当するサービス
class GameFlowService {
  final RoomRepository _repository;
  final GameLogic _gameLogic;

  GameFlowService({required RoomRepository repository, GameLogic? gameLogic})
    : _repository = repository,
      _gameLogic = gameLogic ?? GameLogic();

  /// サイコロを振る
  Future<void> rollDice(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final diceRoll = _gameLogic.rollDice();

    final isHost = _repository.isHost(room, playerId);
    final player = isHost ? room.host : room.guest;
    if (player == null) return;

    final newFishCount = player.fishCount + diceRoll;

    await _repository.updatePlayerData(roomCode, playerId, {
      'diceRoll': diceRoll,
      'rolled': true,
      'fishCount': newFishCount,
    });
  }

  /// サイコロ結果を確認し、フェーズを進める準備をする
  Future<void> confirmRoll(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = _repository.isHost(room, playerId);
    final prefix = isHost ? 'host' : 'guest';

    await _repository.updateRoom(roomCode, {'$prefix.confirmedRoll': true});

    // 両者が確認済みになったら、ステータスを playing に変更（整合性のため）
    final updatedRoom = await _repository.getRoom(roomCode);
    if (updatedRoom != null &&
        updatedRoom.host.confirmedRoll &&
        (updatedRoom.guest?.confirmedRoll ?? false)) {
      await _repository.updateRoom(roomCode, {
        'status': GameStatus.playing.value,
      });
    }
  }

  /// 魚を賭ける
  Future<void> placeBets(
    String roomCode,
    String playerId,
    Map<String, int> bets,
  ) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = _repository.isHost(room, playerId);
    final prefix = isHost ? 'host' : 'guest';

    await _repository.updateRoom(roomCode, {
      '$prefix.currentBets': bets,
      '$prefix.ready': true,
    });

    // 両者が準備完了したか確認
    final updatedRoom = await _repository.getRoom(roomCode);
    if (updatedRoom == null) return;

    if (updatedRoom.host.ready && (updatedRoom.guest?.ready ?? false)) {
      await _resolveRound(roomCode, updatedRoom);
    }
  }

  /// ラウンド結果を判定
  Future<void> _resolveRound(String roomCode, GameRoom room) async {
    final result = _gameLogic.resolveRound(room);
    final guest = room.guest;
    if (guest == null) return;

    // 累計獲得リストを更新
    final newHostCatsWon = [...room.host.catsWon, ...result.hostWonCats];
    final newGuestCatsWon = [...guest.catsWon, ...result.guestWonCats];

    // 累計獲得コストリストを更新
    final newHostWonCatCosts = [
      ...room.host.wonCatCosts,
      ...result.hostWonCosts,
    ];
    final newGuestWonCatCosts = [...guest.wonCatCosts, ...result.guestWonCosts];

    await _repository.updateRoom(roomCode, {
      'winners': result.winners,
      'host.catsWon': newHostCatsWon,
      'guest.catsWon': newGuestCatsWon,
      'host.wonCatCosts': newHostWonCatCosts,
      'guest.wonCatCosts': newGuestWonCatCosts,
      'status': result.finalStatus.value,
      'finalWinner': result.finalWinner?.value,
      // 前回（今回終わった）の情報を保存
      'lastRoundCats': room.currentRound
          ?.toList()
          .map((c) => c.displayName)
          .toList(),
      'lastRoundCatCosts': room.currentRound?.getCosts(),
      'lastRoundWinners': result.winners,
      'lastRoundHostBets': room.host.currentBets,
      'lastRoundGuestBets': guest.currentBets,
      'host.confirmedRoundResult': false,
      'guest.confirmedRoundResult': false,
    });
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
      final isHost = _repository.isHost(room, playerId);
      final prefix = isHost ? 'host' : 'guest';

      transaction.update(roomRef, {'$prefix.confirmedRoundResult': true});

      // すでに他の誰かが更新済みでないか（status が roundResult のままであること）を再確認
      if (room.status == GameStatus.roundResult.value) {
        // 次のターンの猫を生成
        final roundCards = _gameLogic.generateRandomCards();

        // 賭けた魚の総数を計算して、残りの魚を算出（持ち越し）
        final hostBetTotal = room.host.currentBets.values.fold(
          0,
          (a, b) => a + b,
        );
        final guestBetTotal =
            room.guest?.currentBets.values.fold(0, (a, b) => a + b) ?? 0;

        final remainingHostFish = room.host.fishCount - hostBetTotal;
        final remainingGuestFish = (room.guest?.fishCount ?? 0) - guestBetTotal;

        transaction.update(roomRef, {
          'currentTurn': room.currentTurn + 1,
          'status': GameStatus.rolling.value, // サイコロフェーズに移行
          'host.diceRoll': null,
          'guest.diceRoll': null,
          'host.rolled': false,
          'guest.rolled': false,
          'host.fishCount': remainingHostFish, // 残った魚を持ち越し
          'guest.fishCount': remainingGuestFish, // 残った魚を持ち越し
          'host.currentBets': {'0': 0, '1': 0, '2': 0},
          'guest.currentBets': {'0': 0, '1': 0, '2': 0},
          'host.ready': false,
          'guest.ready': false,
          'winners': null,
          'host.confirmedRoll': false,
          'guest.confirmedRoll': false,
          'currentRound': roundCards.toMap(), // 新しいカードセットを設定
        });
      }
    });
  }
}
