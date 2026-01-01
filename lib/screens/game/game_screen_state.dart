import '../../models/game_room.dart';

/// ゲーム画面の状態を表す抽象クラス
abstract class GameScreenState {
  final String? errorMessage;

  const GameScreenState({this.errorMessage});

  factory GameScreenState.loading() = LoadingState;
  factory GameScreenState.waiting() = WaitingState;
  factory GameScreenState.rolling(GameRoom room) = RollingState;
  factory GameScreenState.playing(GameRoom room) = PlayingState;
  factory GameScreenState.roundResult(GameRoom room) = RoundResultState;
  factory GameScreenState.finished(GameRoom room) = FinishedState;

  GameScreenState copyWithError(String error);
}

/// ローディング中
class LoadingState extends GameScreenState {
  const LoadingState({String? errorMessage}) : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return LoadingState(errorMessage: error);
  }
}

/// 対戦相手待ち
class WaitingState extends GameScreenState {
  const WaitingState({String? errorMessage}) : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return WaitingState(errorMessage: error);
  }
}

/// サイコロフェーズ
class RollingState extends GameScreenState {
  final GameRoom room;

  const RollingState(this.room, {String? errorMessage})
      : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return RollingState(room, errorMessage: error);
  }
}

/// 賭けフェーズ
class PlayingState extends GameScreenState {
  final GameRoom room;

  const PlayingState(this.room, {String? errorMessage})
      : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return PlayingState(room, errorMessage: error);
  }
}

/// ラウンド結果表示
class RoundResultState extends GameScreenState {
  final GameRoom room;

  const RoundResultState(this.room, {String? errorMessage})
      : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return RoundResultState(room, errorMessage: error);
  }
}

/// ゲーム終了
class FinishedState extends GameScreenState {
  final GameRoom room;

  const FinishedState(this.room, {String? errorMessage})
      : super(errorMessage: errorMessage);

  @override
  GameScreenState copyWithError(String error) {
    return FinishedState(room, errorMessage: error);
  }
}
