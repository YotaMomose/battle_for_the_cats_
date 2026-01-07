import '../constants/game_constants.dart';
import '../domain/game_logic.dart';
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
    final currentFish = isHost ? room.hostFishCount : room.guestFishCount;
    final newFishCount = currentFish + diceRoll;

    await _repository.updatePlayerData(roomCode, playerId, {
      'DiceRoll': diceRoll,
      'Rolled': true,
      'FishCount': newFishCount,
    });

    // 両者がサイコロを振ったかチェック
    final updatedRoom = await _repository.getRoom(roomCode);
    if (updatedRoom == null) return;

    if (updatedRoom.hostRolled && updatedRoom.guestRolled) {
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

    await _repository.updateRoom(roomCode, {
      isHost ? 'hostBets' : 'guestBets': bets,
      isHost ? 'hostReady' : 'guestReady': true,
    });

    // 両者が準備完了したか確認
    final updatedRoom = await _repository.getRoom(roomCode);
    if (updatedRoom == null) return;

    if (updatedRoom.hostReady && updatedRoom.guestReady) {
      await _resolveRound(roomCode, updatedRoom);
    }
  }

  /// ラウンド結果を判定
  Future<void> _resolveRound(String roomCode, room) async {
    final result = _gameLogic.resolveRound(room);

    // 累計獲得猫リストを更新
    final newHostCatsWon = [...room.hostCatsWon, ...result.hostWonCats];
    final newGuestCatsWon = [...room.guestCatsWon, ...result.guestWonCats];

    await _repository.updateRoom(roomCode, {
      'winners': result.winners,
      'hostCatsWon': newHostCatsWon,
      'guestCatsWon': newGuestCatsWon,
      'status': result.finalStatus.value,
      'finalWinner': result.finalWinner?.value,
    });
  }

  /// 次のターンへ進む
  Future<void> nextTurn(String roomCode) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    // 次のターンの猫を生成
    final nextCats = _gameLogic.generateRandomCats();

    // 賭ケた魚の総数を計算して、残りの魚を算出（持ち越し）
    final hostBetTotal = room.hostBets.values.fold(0, (a, b) => a + b);
    final guestBetTotal = room.guestBets.values.fold(0, (a, b) => a + b);

    final remainingHostFish = room.hostFishCount - hostBetTotal;
    final remainingGuestFish = room.guestFishCount - guestBetTotal;

    await _repository.updateRoom(roomCode, {
      'currentTurn': room.currentTurn + 1,
      'status': GameStatus.rolling.value, // サイコロフェーズに移行
      'hostDiceRoll': null,
      'guestDiceRoll': null,
      'hostRolled': false,
      'guestRolled': false,
      'hostFishCount': remainingHostFish, // 残った魚を持ち越し
      'guestFishCount': remainingGuestFish, // 残った魚を持ち越し
      'hostBets': {'0': 0, '1': 0, '2': 0},
      'guestBets': {'0': 0, '1': 0, '2': 0},
      'hostReady': false,
      'guestReady': false,
      'winners': null,
      'cats': nextCats, // 新しい猫を設定
    });
  }
}
