import 'user_profile.dart';

/// フレンド情報（戦績を含む）を保持するデータモデル
class Friend {
  final UserProfile profile;
  final int winCount;
  final int lossCount;

  const Friend({
    required this.profile,
    required this.winCount,
    required this.lossCount,
  });

  /// 勝率を計算 (0.0 - 1.0)
  double get winRate {
    final total = winCount + lossCount;
    if (total == 0) return 0.0;
    return winCount / total;
  }

  /// 合計試合数
  int get totalGames => winCount + lossCount;

  factory Friend.fromMap(UserProfile profile, Map<String, dynamic> map) {
    return Friend(
      profile: profile,
      winCount: map['winCount'] ?? 0,
      lossCount: map['lossCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendId': profile.uid,
      'winCount': winCount,
      'lossCount': lossCount,
    };
  }
}
