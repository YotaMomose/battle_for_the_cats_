/// ホーム画面の状態を表す抽象クラス
abstract class HomeScreenState {
  final String? errorMessage;

  const HomeScreenState({this.errorMessage});

  factory HomeScreenState.idle({String? errorMessage}) = IdleState;
  factory HomeScreenState.loading() = LoadingState;
  factory HomeScreenState.matchmaking(String playerId) = MatchmakingState;

  HomeScreenState copyWithError(String error);
}

/// 待機中（初期状態）
class IdleState extends HomeScreenState {
  const IdleState({super.errorMessage});

  @override
  HomeScreenState copyWithError(String error) {
    return IdleState(errorMessage: error);
  }
}

/// ローディング中（ルーム作成・参加処理中）
class LoadingState extends HomeScreenState {
  const LoadingState({super.errorMessage});

  @override
  HomeScreenState copyWithError(String error) {
    return LoadingState(errorMessage: error);
  }
}

/// ランダムマッチング中
class MatchmakingState extends HomeScreenState {
  final String playerId;

  const MatchmakingState(this.playerId, {super.errorMessage});

  @override
  HomeScreenState copyWithError(String error) {
    return MatchmakingState(playerId, errorMessage: error);
  }
}
