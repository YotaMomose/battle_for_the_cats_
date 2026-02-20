import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/auth_service.dart';
import '../../repositories/firestore_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/match_result.dart';
import '../../models/user_profile.dart';
import 'home_screen_state.dart';

/// ホーム画面のViewModel
/// ホーム画面の状態管理とビジネスロジックを担当する
class HomeScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  late final AuthService _authService;
  late final UserRepository _userRepository;
  final Function(String roomCode, String playerId, bool isHost)
  onNavigateToGame;

  HomeScreenState _state = HomeScreenState.idle();
  StreamSubscription? _matchmakingSubscription;
  UserProfile? _userProfile;

  HomeScreenState get state => _state;
  UserProfile? get userProfile => _userProfile;

  HomeScreenViewModel({
    required GameService gameService,
    required this.onNavigateToGame,
    AuthService? authService,
    UserRepository? userRepository,
  }) : _gameService = gameService {
    _authService = authService ?? AuthService();
    _userRepository =
        userRepository ?? UserRepository(repository: FirestoreRepository());
    _loadProfile();
  }

  /// 現在のユーザーIDを取得（Firebase Auth の永続的な uid）
  String get _playerId => _authService.currentUserId ?? '';

  /// ユーザープロフィールを読み込む
  ///
  /// 認証が未完了の場合は自動的に初期化を行う。
  Future<void> _loadProfile() async {
    try {
      final uid = await _authService.initialize();
      _userProfile = await _userRepository.getProfile(uid);
      _userProfile ??= UserProfile.defaultProfile(uid);
      notifyListeners();
    } catch (e) {
      // 認証失敗時はデフォルトプロフィールで続行
      debugPrint('プロフィール読み込みエラー: $e');
    }
  }

  /// プロフィールを更新する
  Future<void> updateProfile({String? displayName, String? iconId}) async {
    if (_userProfile == null) return;
    _userProfile = _userProfile!.copyWith(
      displayName: displayName,
      iconId: iconId,
    );
    await _userRepository.saveProfile(_userProfile!);
    notifyListeners();
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
      final playerId = _playerId;
      final roomCode = await _gameService.createRoom(
        playerId,
        displayName: _userProfile?.displayName,
        iconId: _userProfile?.iconId,
      );

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
    final playerId = _playerId;
    _updateState(HomeScreenState.matchmaking(playerId));

    try {
      // 待機リストに登録
      await _gameService.joinMatchmaking(
        playerId,
        displayName: _userProfile?.displayName,
        iconId: _userProfile?.iconId,
      );

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
      final playerId = _playerId;
      final success = await _gameService.joinRoom(
        validCode,
        playerId,
        displayName: _userProfile?.displayName,
        iconId: _userProfile?.iconId,
      );

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
