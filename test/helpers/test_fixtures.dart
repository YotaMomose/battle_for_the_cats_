import 'package:battle_for_the_cats/models/game_room.dart';
import 'package:battle_for_the_cats/models/cards/round_cards.dart';
import 'package:battle_for_the_cats/models/cards/regular_cat.dart';

/// テスト用のRoundCardsを作成（特定の猫データで）
RoundCards createTestRoundCards(
  List<String> displayNames, [
  List<int>? costs,
]) {
  final cats = [
    RegularCat(
      id: 'test_cat_1',
      displayName: displayNames[0],
      baseCost: costs != null ? costs[0] : 1,
    ),
    RegularCat(
      id: 'test_cat_2',
      displayName: displayNames[1],
      baseCost: costs != null ? costs[1] : 1,
    ),
    RegularCat(
      id: 'test_cat_3',
      displayName: displayNames[2],
      baseCost: costs != null ? costs[2] : 1,
    ),
  ];
  return RoundCards(
    card1: cats[0],
    card2: cats[1],
    card3: cats[2],
  );
}

/// テスト用のGameRoomを作成するファクトリ関数
GameRoom createTestGameRoom({
  String roomId = 'test-room-123',
  String hostId = 'host-user-123',
  String? guestId = 'guest-user-456',
  String status = 'playing',
  int currentTurn = 1,
  int hostFishCount = 10,
  int guestFishCount = 10,
  RoundCards? currentRound,
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
    currentRound: currentRound ?? RoundCards.random(),
    hostBets: hostBets ?? {'0': 0, '1': 0, '2': 0},
    guestBets: guestBets ?? {'0': 0, '1': 0, '2': 0},
    hostCatsWon: hostCatsWon ?? [],
    guestCatsWon: guestCatsWon ?? [],
    hostWonCatCosts: hostWonCatCosts ?? [],
    guestWonCatCosts: guestWonCatCosts ?? [],
  );
}
