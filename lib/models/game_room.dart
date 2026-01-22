import 'cards/round_cards.dart';
import 'player.dart';

class GameRoom {
  final String roomId;
  String status; // 'waiting', 'rolling', 'playing', 'roundResult', 'finished'
  int currentTurn;

  // プレイヤー情報
  Player host;
  Player? guest;

  // 前回のラウンド情報（画面表示用、個別に次へ進むために必要）
  List<String>? lastRoundCats;
  List<int>? lastRoundCatCosts;
  Map<String, String>? lastRoundWinners;
  Map<String, int>? lastRoundHostBets;
  Map<String, int>? lastRoundGuestBets;

  // 現在のラウンドの3匹の猫
  RoundCards? currentRound;

  // 各猫の勝者（猫のインデックス -> 'host'/'guest'/'draw'）
  Map<String, String>? winners;

  // 最終勝者
  String? finalWinner;

  GameRoom({
    required this.roomId,
    required this.host,
    this.guest,
    this.status = 'waiting',
    this.currentTurn = 1,
    this.lastRoundCats,
    this.lastRoundCatCosts,
    this.lastRoundWinners,
    this.lastRoundHostBets,
    this.lastRoundGuestBets,
    this.currentRound,
    this.winners,
    this.finalWinner,
  });

  String get hostId => host.id;
  String? get guestId => guest?.id;

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'status': status,
      'currentTurn': currentTurn,
      'host': host.toMap(),
      'guest': guest?.toMap(),
      'currentRound': currentRound?.toMap(),
      'winners': winners,
      'finalWinner': finalWinner,
      'lastRoundCats': lastRoundCats,
      'lastRoundCatCosts': lastRoundCatCosts,
      'lastRoundWinners': lastRoundWinners,
      'lastRoundHostBets': lastRoundHostBets,
      'lastRoundGuestBets': lastRoundGuestBets,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      roomId: map['roomId'] ?? '',
      status: map['status'] ?? 'waiting',
      currentTurn: map['currentTurn'] ?? 1,
      host: Player.fromMap(map['host'] ?? {'id': map['hostId'] ?? ''}),
      guest: map['guest'] != null
          ? Player.fromMap(map['guest'])
          : (map['guestId'] != null ? Player(id: map['guestId']) : null),
      currentRound: map['currentRound'] != null
          ? RoundCards.fromMap(map['currentRound'])
          : null,
      winners: map['winners'] != null
          ? Map<String, String>.from(map['winners'])
          : null,
      finalWinner: map['finalWinner'],
      lastRoundCats: map['lastRoundCats'] != null
          ? List<String>.from(map['lastRoundCats'])
          : null,
      lastRoundCatCosts: map['lastRoundCatCosts'] != null
          ? List<int>.from(map['lastRoundCatCosts'])
          : null,
      lastRoundWinners: map['lastRoundWinners'] != null
          ? Map<String, String>.from(map['lastRoundWinners'])
          : null,
      lastRoundHostBets: map['lastRoundHostBets'] != null
          ? Map<String, int>.from(map['lastRoundHostBets'])
          : null,
      lastRoundGuestBets: map['lastRoundGuestBets'] != null
          ? Map<String, int>.from(map['lastRoundGuestBets'])
          : null,
    );
  }
}
