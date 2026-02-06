import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/game_service.dart';
import '../../models/match_result.dart';
import 'home_screen_state.dart';

/// ホーム画面のViewModel
/// ホーム画面の状態管理とビジネスロジックを担当する
class HomeScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  final Function(String roomCode, String playerId, bool isHost)
  onNavigateToGame;

  HomeScreenState _state = HomeScreenState.idle();
  StreamSubscription? _matchmakingSubscription;
  String? _sessionPlayerId;

  HomeScreenState get state => _state;

  HomeScreenViewModel({
    required GameService gameService,
    required this.onNavigateToGame,
  }) : _gameService = gameService;

  /// Player ID を一意に生成 (セッション内で固定)
  String _generatePlayerId() {
    _sessionPlayerId ??= const Uuid().v4();
    return _sessionPlayerId!;
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
    if (_state is! IdleState) return;
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
    if (_state is! IdleState) return;
    final playerId = _generatePlayerId();
    _updateState(HomeScreenState.matchmaking(playerId));

    try {
      // 待機リストに登録
      await _gameService.joinMatchmaking(playerId);

      // join処理（書き込み）完了後のガード：
      // 書き込みの非同期処理中にキャンセルボタンが押されていないか、
      // あるいは別のマッチングが開始されていないかチェックする
      final currentState = _state;
      if (currentState is! MatchmakingState ||
          currentState.playerId != playerId) {
        // キャンセルされていた場合は、直ちにFirestoreの情報を消去してゴースト化を防ぐ
        await _gameService.cancelMatchmaking(playerId);
        return;
      }

      // マッチング監視を開始
      _matchmakingSubscription = _gameService
          .watchMatchmaking(playerId)
          .listen(
            (result) => _handleMatchFound(result, playerId),
            onError: _handleMatchmakingError,
          );
    } catch (e) {
      _handleMatchmakingError(e);
    }
  }

  /// マッチング成立時の処理
  Future<void> _handleMatchFound(MatchResult? result, String playerId) async {
    // まだマッチングしていない場合は継続
    if (result == null) return;

    // マッチング成立！
    await _matchmakingSubscription?.cancel();
    _matchmakingSubscription = null;
    // マッチング完了処理
    await _finalizeMatch(result, playerId);
  }

  /// マッチング完了処理
  /// マッチングが完了したら、ゲーム画面へ遷移する
  Future<void> _finalizeMatch(MatchResult result, String playerId) async {
    try {
      // マッチング情報を取得
      final roomCode = result.roomCode;
      final isHost = result.isHost;

      // ゲーム画面へ遷移
      onNavigateToGame(roomCode, playerId, isHost);

      // マッチング情報をクリーンアップ (非同期で実行)
      _gameService.cancelMatchmaking(playerId);

      // 状態を元に戻す
      _sessionPlayerId = null; // 次回のためにIDをリセット
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
      final pId = currentState.playerId;

      // 1. UIをロック
      _updateState(HomeScreenState.loading());

      // 2. 監視の停止 (ハング防止のため待機しない)
      _matchmakingSubscription?.cancel();
      _matchmakingSubscription = null;

      try {
        // 3. Firestore削除を実行し、完了を待機する
        await _gameService.cancelMatchmaking(pId);
      } catch (e) {
        _setError('キャンセル処理（削除）に失敗しました。');
      } finally {
        // 4. メインメニューに戻す
        _updateState(HomeScreenState.idle());
      }
    }
  }

  /// ルームに参加
  Future<void> joinRoom(String roomCode) async {
    if (_state is! IdleState) return;
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
