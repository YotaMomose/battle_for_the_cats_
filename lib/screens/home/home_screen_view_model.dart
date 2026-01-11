import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import 'home_screen_state.dart';

/// ホーム画面のViewModel
/// ホーム画面の状態管理とビジネスロジックを担当する
class HomeScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  final Function(String roomCode, String playerId, bool isHost)
  onNavigateToGame;

  HomeScreenState _state = HomeScreenState.idle();
  StreamSubscription? _matchmakingSubscription;

  HomeScreenState get state => _state;

  HomeScreenViewModel({
    required GameService gameService,
    required this.onNavigateToGame,
  }) : _gameService = gameService;

  /// Player ID を生成
  /// TODO: Player ID の生成方法を変更する
  String _generatePlayerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 状態を更新して通知
  void _updateState(HomeScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  /// エラーを設定
  void _setError(String message) {
    _state = _state.copyWithError(message);
    notifyListeners();
  }

  /// ルームを作成
  Future<void> createRoom() async {
    _updateState(HomeScreenState.loading());

    try {
      final playerId = _generatePlayerId();
      final roomCode = await _gameService.createRoom(playerId);

      // ゲーム画面へ遷移
      onNavigateToGame(roomCode, playerId, true);

      // 状態を元に戻す
      _updateState(HomeScreenState.idle());
    } catch (e) {
      _setError('ルーム作成に失敗しました: $e');
      _updateState(HomeScreenState.idle());
    }
  }

  /// ランダムマッチングを開始
  Future<void> startRandomMatch() async {
    final playerId = _generatePlayerId();
    _updateState(HomeScreenState.matchmaking(playerId));

    try {
      // 待機リストに登録
      await _gameService.joinMatchmaking(playerId);

      // マッチング監視を開始
      _matchmakingSubscription = _gameService
          .watchMatchmaking(playerId)
          .listen(
            (roomCode) => _handleMatchFound(roomCode, playerId),
            onError: _handleMatchmakingError,
          );
    } catch (e) {
      _handleMatchmakingError(e);
    }
  }

  /// マッチング成立時の処理
  Future<void> _handleMatchFound(String? roomCode, String playerId) async {
    // まだマッチングしていない場合は継続
    if (roomCode == null) return;

    // マッチング成立！
    await _matchmakingSubscription?.cancel();
    _matchmakingSubscription = null;
    // マッチング完了処理
    await _finalizeMatch(roomCode, playerId);
  }

  /// マッチング完了処理
  /// マッチングが完了したら、ゲーム画面へ遷移する
  Future<void> _finalizeMatch(String roomCode, String playerId) async {
    try {
      // マッチング情報を取得してホストかゲストか判定
      final isHost = await _gameService.isHostInMatch(playerId);

      // ゲーム画面へ遷移
      onNavigateToGame(roomCode, playerId, isHost);

      // マッチング情報をクリーンアップ
      await _gameService.cancelMatchmaking(playerId);

      // 状態を元に戻す
      _updateState(HomeScreenState.idle());
    } catch (e) {
      _handleMatchmakingError(e);
    }
  }

  /// マッチングエラー処理
  void _handleMatchmakingError(dynamic error) {
    _setError('マッチングに失敗しました: $error');
    _updateState(HomeScreenState.idle());
  }

  /// ランダムマッチングをキャンセル
  Future<void> cancelMatchmaking() async {
    final currentState = _state;
    if (currentState is MatchmakingState) {
      await _matchmakingSubscription?.cancel();
      _matchmakingSubscription = null;
      await _gameService.cancelMatchmaking(currentState.playerId);
      _updateState(HomeScreenState.idle());
    }
  }

  /// ルームに参加
  Future<void> joinRoom(String roomCode) async {
    final validCode = _validateRoomCode(roomCode);
    if (validCode == null) return;

    _updateState(HomeScreenState.loading());

    try {
      final playerId = _generatePlayerId();
      final success = await _gameService.joinRoom(validCode, playerId);

      // 参加に失敗した場合はエラーメッセージを表示
      if (!success) {
        _setError('ルームが見つからないか、すでに満員です');
        _updateState(HomeScreenState.idle());
        return;
      }

      _handleJoinSuccess(validCode, playerId);
    } catch (e) {
      _setError('ルーム参加に失敗しました: $e');
      _updateState(HomeScreenState.idle());
    }
  }

  /// ルームコードの検証
  /// 戻り値がnullの場合は検証に失敗
  String? _validateRoomCode(String roomCode) {
    final trimmedCode = roomCode.trim().toUpperCase();

    if (trimmedCode.isEmpty) {
      _setError('ルームコードを入力してください');
      return null;
    }
    if (trimmedCode.length != 6) {
      _setError('ルームコードは6桁です');
      return null;
    }

    return trimmedCode;
  }

  /// 参加成功時の処理
  void _handleJoinSuccess(String roomCode, String playerId) {
    // ゲーム画面へ遷移
    onNavigateToGame(roomCode, playerId, false);

    // 状態を元に戻す
    _updateState(HomeScreenState.idle());
  }

  @override
  void dispose() {
    _matchmakingSubscription?.cancel();

    // マッチング中の場合はキャンセル
    final currentState = _state;
    if (currentState is MatchmakingState) {
      _gameService.cancelMatchmaking(currentState.playerId);
    }

    super.dispose();
  }
}
