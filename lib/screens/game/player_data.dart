import '../../models/game_room.dart';

/// プレイヤー別にGameRoomのデータを取得するヘルパークラス
class PlayerData {
  final int myFishCount;
  final int opponentFishCount;
  final List<String> myCatsWon;
  final List<String> opponentCatsWon;
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
    return PlayerData(
      myFishCount: isHost ? room.hostFishCount : room.guestFishCount,
      opponentFishCount: isHost ? room.guestFishCount : room.hostFishCount,
      myCatsWon: isHost ? room.hostCatsWon : room.guestCatsWon,
      opponentCatsWon: isHost ? room.guestCatsWon : room.hostCatsWon,
      myDiceRoll: isHost ? room.hostDiceRoll : room.guestDiceRoll,
      opponentDiceRoll: isHost ? room.guestDiceRoll : room.hostDiceRoll,
      myRolled: isHost ? room.hostRolled : room.guestRolled,
      opponentRolled: isHost ? room.guestRolled : room.hostRolled,
      myReady: isHost ? room.hostReady : room.guestReady,
      opponentReady: isHost ? room.guestReady : room.hostReady,
      myBets: isHost ? room.hostBets : room.guestBets,
      opponentBets: isHost ? room.guestBets : room.hostBets,
    );
  }
}
