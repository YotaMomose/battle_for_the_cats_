import '../../models/game_room.dart';

/// プレイヤー別にGameRoomのデータを取得するヘルパークラス
/// ※ドメインモデルのデータを「自分から見た視点」で整理するだけの純粋なデータクラス
class PlayerData {
  final int myFishCount;
  final int opponentFishCount;
  final List<String> myCatsWon;
  final List<String> opponentCatsWon;
  final List<int> myWonCatCosts;
  final List<int> opponentWonCatCosts;
  final int? myDiceRoll;
  final int? opponentDiceRoll;
  final bool myRolled;
  final bool opponentRolled;
  final bool myReady;
  final bool opponentReady;
  final Map<String, int> myBets;
  final Map<String, int> opponentBets;

  const PlayerData({
    required this.myFishCount,
    required this.opponentFishCount,
    required this.myCatsWon,
    required this.opponentCatsWon,
    required this.myWonCatCosts,
    required this.opponentWonCatCosts,
    required this.myDiceRoll,
    required this.opponentDiceRoll,
    required this.myRolled,
    required this.opponentRolled,
    required this.myReady,
    required this.opponentReady,
    required this.myBets,
    required this.opponentBets,
  });

  /// GameRoomとisHostから自分と相手のデータを抽出
  factory PlayerData.fromRoom(GameRoom room, bool isHost) {
    final host = room.host;
    final guest = room.guest;

    final my = isHost ? host : guest;
    final opponent = isHost ? guest : host;

    return PlayerData(
      myFishCount: my?.fishCount ?? 0,
      opponentFishCount: opponent?.fishCount ?? 0,
      myCatsWon: my?.catsWon ?? [],
      opponentCatsWon: opponent?.catsWon ?? [],
      myWonCatCosts: my?.wonCatCosts ?? [],
      opponentWonCatCosts: opponent?.wonCatCosts ?? [],
      myDiceRoll: my?.diceRoll,
      opponentDiceRoll: opponent?.diceRoll,
      myRolled: my?.rolled ?? false,
      opponentRolled: opponent?.rolled ?? false,
      myReady: my?.ready ?? false,
      opponentReady: opponent?.ready ?? false,
      myBets: my?.currentBets ?? {},
      opponentBets: opponent?.currentBets ?? {},
    );
  }
}
