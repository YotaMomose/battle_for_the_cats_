import '../../models/game_room.dart';

/// ゲーム画面の状態を表す抽象クラス
sealed class GameScreenState {
  final String? errorMessage;
  final bool isOpponentLeft;
  final bool isKicked;
  final bool isRoomClosed;

  const GameScreenState({
    this.errorMessage,
    this.isOpponentLeft = false,
    this.isKicked = false,
    this.isRoomClosed = false,
  });

  factory GameScreenState.loading() = LoadingState;
  factory GameScreenState.waiting() = WaitingState;
  factory GameScreenState.rolling(GameRoom room) = RollingState;
  factory GameScreenState.playing(GameRoom room) = PlayingState;
  factory GameScreenState.roundResult(GameRoom room) = RoundResultState;
  factory GameScreenState.finished(GameRoom room) = FinishedState;
  factory GameScreenState.fatCatEvent(GameRoom room) = FatCatEventState;

  GameScreenState copyWithError(String error);
  GameScreenState copyWithOpponentLeft();
  GameScreenState copyWithKicked();
  GameScreenState copyWithRoomClosed();
}

/// ローディング中
class LoadingState extends GameScreenState {
  const LoadingState({
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return LoadingState(
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  LoadingState copyWithOpponentLeft() {
    return LoadingState(
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  LoadingState copyWithKicked() {
    return LoadingState(
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  LoadingState copyWithRoomClosed() {
    return LoadingState(
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// 対戦相手待ち
class WaitingState extends GameScreenState {
  const WaitingState({
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return WaitingState(
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  WaitingState copyWithOpponentLeft() {
    return WaitingState(
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  WaitingState copyWithKicked() {
    return WaitingState(
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  WaitingState copyWithRoomClosed() {
    return WaitingState(
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// サイコロフェーズ
class RollingState extends GameScreenState {
  final GameRoom room;
  const RollingState(
    this.room, {
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return RollingState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RollingState copyWithOpponentLeft() {
    return RollingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RollingState copyWithKicked() {
    return RollingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RollingState copyWithRoomClosed() {
    return RollingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// 賭けフェーズ
class PlayingState extends GameScreenState {
  final GameRoom room;
  const PlayingState(
    this.room, {
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return PlayingState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  PlayingState copyWithOpponentLeft() {
    return PlayingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  PlayingState copyWithKicked() {
    return PlayingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  PlayingState copyWithRoomClosed() {
    return PlayingState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// ラウンド結果表示
class RoundResultState extends GameScreenState {
  final GameRoom room;
  const RoundResultState(
    this.room, {
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return RoundResultState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RoundResultState copyWithOpponentLeft() {
    return RoundResultState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RoundResultState copyWithKicked() {
    return RoundResultState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  RoundResultState copyWithRoomClosed() {
    return RoundResultState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// ゲーム終了
class FinishedState extends GameScreenState {
  final GameRoom room;
  const FinishedState(
    this.room, {
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return FinishedState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FinishedState copyWithOpponentLeft() {
    return FinishedState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FinishedState copyWithKicked() {
    return FinishedState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FinishedState copyWithRoomClosed() {
    return FinishedState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}

/// 太っちょネコイベント
class FatCatEventState extends GameScreenState {
  final GameRoom room;
  const FatCatEventState(
    this.room, {
    super.errorMessage,
    super.isOpponentLeft,
    super.isKicked,
    super.isRoomClosed,
  });

  @override
  GameScreenState copyWithError(String error) {
    return FatCatEventState(
      room,
      errorMessage: error,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FatCatEventState copyWithOpponentLeft() {
    return FatCatEventState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: true,
      isKicked: isKicked,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FatCatEventState copyWithKicked() {
    return FatCatEventState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: true,
      isRoomClosed: isRoomClosed,
    );
  }

  @override
  FatCatEventState copyWithRoomClosed() {
    return FatCatEventState(
      room,
      errorMessage: errorMessage,
      isOpponentLeft: isOpponentLeft,
      isKicked: isKicked,
      isRoomClosed: true,
    );
  }
}
