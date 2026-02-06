/// マッチングの結果を保持するデータモデル
class MatchResult {
  final String roomCode;
  final bool isHost;

  const MatchResult({required this.roomCode, required this.isHost});

  @override
  String toString() => 'MatchResult(roomCode: $roomCode, isHost: $isHost)';
}
