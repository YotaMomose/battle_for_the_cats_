import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/constants/game_constants.dart';

/// テスト用のGameRoomを作成するファクトリ関数
GameRoom createTestGameRoom({
  String roomId = 'test-room-123',
  String hostId = 'host-user-123',
  String? guestId = 'guest-user-456',
  String status = 'playing',
  int currentTurn = 1,
  int hostFishCount = 10,
  int guestFishCount = 10,
  List<String>? cats,
  List<int>? catCosts,
  Map<String, int>? hostBets,
  Map<String, int>? guestBets,
  List<String>? hostCatsWon,
  List<String>? guestCatsWon,
  List<int>? hostWonCatCosts,
  List<int>? guestWonCatCosts,
}) {
  return GameRoom(
    roomId: roomId,
    hostId: hostId,
    guestId: guestId,
    status: status,
    currentTurn: currentTurn,
    hostFishCount: hostFishCount,
    guestFishCount: guestFishCount,
    cats: cats ?? ['茶トラねこ', '白ねこ', '黒ねこ'],
    catCosts: catCosts ?? [2, 3, 1],
    hostBets: hostBets ?? {'0': 0, '1': 0, '2': 0},
    guestBets: guestBets ?? {'0': 0, '1': 0, '2': 0},
    hostCatsWon: hostCatsWon ?? [],
    guestCatsWon: guestCatsWon ?? [],
    hostWonCatCosts: hostWonCatCosts ?? [],
    guestWonCatCosts: guestWonCatCosts ?? [],
  );
}
