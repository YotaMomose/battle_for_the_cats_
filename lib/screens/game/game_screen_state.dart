import '../../models/game_room.dart';

/// ゲーム画面の状態を表す抽象クラス
sealed class GameScreenState {
  final String? errorMessage;
  final bool isOpponentLeft;

  const GameScreenState({this.errorMessage, this.isOpponentLeft = false});

  factory GameScreenState.loading() = LoadingState;
  factory GameScreenState.waiting() = WaitingState;
  factory GameScreenState.rolling(GameRoom room) = RollingState;
  factory GameScreenState.playing(GameRoom room) = PlayingState;
  factory GameScreenState.roundResult(GameRoom room) = RoundResultState;
  factory GameScreenState.finished(GameRoom room) = FinishedState;
  factory GameScreenState.fatCatEvent(GameRoom room) = FatCatEventState;

  GameScreenState copyWithError(String error);
  GameScreenState copyWithOpponentLeft();
}

/// ローディング中
class LoadingState extends GameScreenState {
  const LoadingState({super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return LoadingState(errorMessage: error, isOpponentLeft: isOpponentLeft);
  }

  @override
  LoadingState copyWithOpponentLeft() {
    return LoadingState(errorMessage: errorMessage, isOpponentLeft: true);
  }
}

/// 対戦相手待ち
class WaitingState extends GameScreenState {
  const WaitingState({super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return WaitingState(errorMessage: error, isOpponentLeft: isOpponentLeft);
  }

  @override
  WaitingState copyWithOpponentLeft() {
    return WaitingState(errorMessage: errorMessage, isOpponentLeft: true);
  }
}

/// サイコロフェーズ
class RollingState extends GameScreenState {
  final GameRoom room;
  const RollingState(this.room, {super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return RollingState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
    );
  }

  @override
  RollingState copyWithOpponentLeft() {
    return RollingState(room, errorMessage: errorMessage, isOpponentLeft: true);
  }
}

/// 賭けフェーズ
class PlayingState extends GameScreenState {
  final GameRoom room;
  const PlayingState(this.room, {super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return PlayingState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
    );
  }

  @override
  PlayingState copyWithOpponentLeft() {
    return PlayingState(room, errorMessage: errorMessage, isOpponentLeft: true);
  }
}

/// ラウンド結果表示
class RoundResultState extends GameScreenState {
  final GameRoom room;
  const RoundResultState(this.room, {super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return RoundResultState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
    );
  }

  @override
  RoundResultState copyWithOpponentLeft() {
    return RoundResultState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
    );
  }
}

/// ゲーム終了
class FinishedState extends GameScreenState {
  final GameRoom room;
  const FinishedState(this.room, {super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return FinishedState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
    );
  }

  @override
  FinishedState copyWithOpponentLeft() {
    return FinishedState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
    );
  }
}

/// 太っちょネコイベント
class FatCatEventState extends GameScreenState {
  final GameRoom room;
  const FatCatEventState(this.room, {super.errorMessage, super.isOpponentLeft});

  @override
  GameScreenState copyWithError(String error) {
    return FatCatEventState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
    );
  }

  @override
  FatCatEventState copyWithOpponentLeft() {
    return FatCatEventState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
    );
  }
}
