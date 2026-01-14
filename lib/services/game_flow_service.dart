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
  }

  /// サイコロ結果を確認し、フェーズを進める準備をする
  Future<void> confirmRoll(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = _repository.isHost(room, playerId);

    await _repository.updateRoom(roomCode, {
      isHost ? 'hostConfirmedRoll' : 'guestConfirmedRoll': true,
    });

    // 両者が確認済みになったら、ステータスを playing に変更（整合性のため）
    final updatedRoom = await _repository.getRoom(roomCode);
    if (updatedRoom != null &&
        updatedRoom.hostConfirmedRoll &&
        updatedRoom.guestConfirmedRoll) {
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

    // 累計獲得コストリストを更新
    final newHostWonCatCosts = [
      ...room.hostWonCatCosts,
      ...result.hostWonCosts,
    ];
    final newGuestWonCatCosts = [
      ...room.guestWonCatCosts,
      ...result.guestWonCosts,
    ];

    await _repository.updateRoom(roomCode, {
      'winners': result.winners,
      'hostCatsWon': newHostCatsWon,
      'guestCatsWon': newGuestCatsWon,
      'hostWonCatCosts': newHostWonCatCosts,
      'guestWonCatCosts': newGuestWonCatCosts,
      'status': result.finalStatus.value,
      'finalWinner': result.finalWinner?.value,
      // 前回（今回終わった）の情報を保存
      'lastRoundCats': room.cats,
      'lastRoundCatCosts': room.catCosts,
      'lastRoundWinners': result.winners,
      'lastRoundHostBets': room.hostBets,
      'lastRoundGuestBets': room.guestBets,
      'hostConfirmedRoundResult': false,
      'guestConfirmedRoundResult': false,
    });
  }

  /// 次のターンへ進む（個別アクション）
  Future<void> nextTurn(String roomCode, String playerId) async {
    final room = await _repository.getRoom(roomCode);
    if (room == null) return;

    final isHost = _repository.isHost(room, playerId);
    final myConfirmedField = isHost
        ? 'hostConfirmedRoundResult'
        : 'guestConfirmedRoundResult';

    // 自分の確認フラグを立てる
    await _repository.updateRoom(roomCode, {myConfirmedField: true});

    // まだ誰も次へ進んでいない場合（status が roundResult のままの場合）、
    // 次のターンの初期化処理を行う
    // これにより、最初に「次へ」を押した人が次のターンのデータを作成し、
    // status を rolling に変える。
    if (room.status == GameStatus.roundResult.value) {
      // 次のターンの猫を生成
      final nextCats = _gameLogic.generateRandomCats();
      final nextCosts = _gameLogic.generateRandomCosts(nextCats.length);

      // 賭けた魚の総数を計算して、残りの魚を算出（持ち越し）
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
        'hostConfirmedRoll': false,
        'guestConfirmedRoll': false,
        'cats': nextCats, // 新しい猫を設定
        'catCosts': nextCosts, // コストを設定
      });
    }
  }
}
