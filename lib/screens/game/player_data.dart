import '../../models/game_room.dart';
import '../../models/bets.dart';
import '../../models/cat_inventory.dart';
import '../../models/item_inventory.dart';
import '../../constants/game_constants.dart';

/// プレイヤー別にGameRoomのデータを取得するヘルパークラス
/// ※ドメインモデルのデータを「自分から見た視点」で整理するだけの純粋なデータクラス
class PlayerData {
  final GameRoom room;
  final bool isHost;
  final int myFishCount;
  final int opponentFishCount;
  final CatInventory myCatsWon;
  final CatInventory opponentCatsWon;
  final int? myDiceRoll;
  final int? opponentDiceRoll;
  final bool myRolled;
  final bool opponentRolled;
  final bool myReady;
  final bool opponentReady;
  final Bets myBets;
  final Bets opponentBets;
  final ItemInventory myInventory;
  final ItemInventory opponentInventory;

  const PlayerData({
    required this.room,
    required this.isHost,
    required this.myFishCount,
    required this.opponentFishCount,
    required this.myCatsWon,
    required this.opponentCatsWon,
    required this.myDiceRoll,
    required this.opponentDiceRoll,
    required this.myRolled,
    required this.opponentRolled,
    required this.myReady,
    required this.opponentReady,
    required this.myBets,
    required this.opponentBets,
    required this.myInventory,
    required this.opponentInventory,
  });

  /// 自分の役割
  Winner get myRole => isHost ? Winner.host : Winner.guest;

  /// 相手の役割
  Winner get opponentRole => isHost ? Winner.guest : Winner.host;

  /// 自分のサイコロ結果を表示すべきか
  bool get shouldShowMyRollResult => myRolled && myDiceRoll != null;

  /// 相手のサイコロ結果を表示すべきか
  bool get shouldShowOpponentRollResult =>
      opponentRolled && opponentDiceRoll != null;

  /// ロールフェーズから次へ進める状態か
  bool get canProceedFromRoll => myRolled && opponentRolled;

  /// 表示すべきターン数
  int get displayTurn => room.status == GameStatus.roundResult
      ? room.currentTurn
      : room.currentTurn - 1;

  /// 自分がラウンド結果を確認済みか
  bool get isMyRoundResultConfirmed => isHost
      ? room.host.confirmedRoundResult
      : (room.guest?.confirmedRoundResult ?? false);

  /// このラウンドでの自分の勝利数
  int get myRoundWinCount => room.lastRoundResult?.getWinCountFor(myRole) ?? 0;

  /// このラウンドでの相手の勝利数
  int get opponentRoundWinCount =>
      room.lastRoundResult?.getWinCountFor(opponentRole) ?? 0;

  /// GameRoomとisHostから自分と相手のデータを抽出
  factory PlayerData.fromRoom(GameRoom room, bool isHost) {
    final host = room.host;
    final guest = room.guest;

    final my = isHost ? host : guest;
    final opponent = isHost ? guest : host;

    return PlayerData(
      room: room,
      isHost: isHost,
      myFishCount: my?.fishCount ?? 0,
      opponentFishCount: opponent?.fishCount ?? 0,
      myCatsWon: my?.catsWon ?? CatInventory(),
      opponentCatsWon: opponent?.catsWon ?? CatInventory(),
      myDiceRoll: my?.diceRoll,
      opponentDiceRoll: opponent?.diceRoll,
      myRolled: my?.rolled ?? false,
      opponentRolled: opponent?.rolled ?? false,
      myReady: my?.ready ?? false,
      opponentReady: opponent?.ready ?? false,
      myBets: my?.currentBets ?? Bets(),
      opponentBets: opponent?.currentBets ?? Bets(),
      myInventory: my?.items ?? ItemInventory.initial(),
      opponentInventory: opponent?.items ?? ItemInventory.initial(),
    );
  }
}
