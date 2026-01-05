import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import 'home_screen_state.dart';

/// ホーム画面のViewModel
class HomeScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  final Function(String roomCode, String playerId, bool isHost) onNavigateToGame;
  
  HomeScreenState _state = HomeScreenState.idle();
  StreamSubscription? _matchmakingSubscription;
  
  HomeScreenState get state => _state;
  
  HomeScreenViewModel({
    required GameService gameService,
    required this.onNavigateToGame,
  }) : _gameService = gameService;

  /// Player ID を生成
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
      _matchmakingSubscription = _gameService.watchMatchmaking(playerId).listen(
        (roomCode) async {
          // まだマッチングしていない場合は継続
          if (roomCode == null) return;
          
          // マッチング成立！
          await _matchmakingSubscription?.cancel();
          _matchmakingSubscription = null;
          
          // マッチング情報を取得してホストかゲストか判定
          final isHost = await _gameService.isHostInMatch(playerId);
          
          // ゲーム画面へ遷移
          onNavigateToGame(roomCode, playerId, isHost);
          
          // マッチング情報をクリーンアップ
          await _gameService.cancelMatchmaking(playerId);
          
          // 状態を元に戻す
          _updateState(HomeScreenState.idle());
        },
        onError: (error) {
          _setError('マッチングに失敗しました: $error');
          _updateState(HomeScreenState.idle());
        },
      );
    } catch (e) {
      _setError('マッチングに失敗しました: $e');
      _updateState(HomeScreenState.idle());
    }
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
    final trimmedCode = roomCode.trim().toUpperCase();
    
    if (trimmedCode.isEmpty) {
      _setError('ルームコードを入力してください');
      return;
    }
    
    if (trimmedCode.length != 6) {
      _setError('ルームコードは6桁です');
      return;
    }
    
    _updateState(HomeScreenState.loading());
    
    try {
      final playerId = _generatePlayerId();
      final success = await _gameService.joinRoom(trimmedCode, playerId);
      
      // 参加に失敗した場合はエラーメッセージを表示
      if (!success) {
        _setError('ルームが見つからないか、すでに満員です');
        _updateState(HomeScreenState.idle());
        return;
      }
      
      // ゲーム画面へ遷移
      onNavigateToGame(trimmedCode, playerId, false);
      
      // 状態を元に戻す
      _updateState(HomeScreenState.idle());
    } catch (e) {
      _setError('ルーム参加に失敗しました: $e');
      _updateState(HomeScreenState.idle());
    }
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
