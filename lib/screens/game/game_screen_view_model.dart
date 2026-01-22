import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/game_room.dart';
import '../../services/game_service.dart';
import 'game_screen_state.dart';
import 'player_data.dart';

/// ゲーム画面のViewModel
class GameScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  final String roomCode;
  final String playerId;
  final bool isHost;

  // ===== View用の状態 =====
  GameRoom? _currentRoom;
  GameScreenState _uiState = GameScreenState.loading();

  // ローカル状態
  bool _hasRolled = false;
  bool _hasPlacedBet = false;
  Map<String, int> _bets = {'0': 0, '1': 0, '2': 0};
  int _lastTurn = 0;

  // Stream購読
  StreamSubscription<GameRoom?>? _roomSubscription;

  // コールバック
  final VoidCallback? onOpponentLeft;

  // ===== Getters (Viewから参照) =====
  GameScreenState get uiState => _uiState;
  bool get hasRolled => _hasRolled;
  bool get hasPlacedBet => _hasPlacedBet;
  Map<String, int> get bets => Map.unmodifiable(_bets);
  int get totalBet => _bets.values.reduce((a, b) => a + b);

  /// プレイヤーデータ（計算プロパティ）
  PlayerData? get playerData {
    if (_currentRoom == null) return null;
    return PlayerData.fromRoom(_currentRoom!, isHost);
  }

  GameScreenViewModel({
    required GameService gameService,
    required this.roomCode,
    required this.playerId,
    required this.isHost,
    this.onOpponentLeft,
  }) : _gameService = gameService {
    _init();
  }

  // ===== 初期化 =====
  void _init() {
    _roomSubscription = _gameService
        .watchRoom(roomCode)
        .listen(
          (room) {
            if (room == null) {
              // ルームが削除された場合
              _handleOpponentLeft();
              return;
            }
            _currentRoom = room;
            _updateUiState(room);
            _checkTurnChange(room);
            notifyListeners();
          },
          onError: (error) {
            _uiState = _uiState.copyWithError('データの取得に失敗しました: $error');
            notifyListeners();
          },
        );
  }

  // ===== 状態更新ロジック =====
  void _updateUiState(GameRoom room) {
    final host = room.host;
    final guest = room.guest;

    // --- 個別遷移の整合性チェック ---
    final myConfirmedRound = isHost
        ? host.confirmedRoundResult
        : (guest?.confirmedRoundResult ?? false);
    final myConfirmedRoll = isHost
        ? host.confirmedRoll
        : (guest?.confirmedRoll ?? false);

    // 1. ラウンド結果の確認待ち
    if (!myConfirmedRound &&
        room.lastRoundWinners != null &&
        (room.status == 'rolling' || room.status == 'playing')) {
      _uiState = GameScreenState.roundResult(room);
      return;
    }

    // --- 相手の退出チェック ---
    final opponentAbandoned = isHost
        ? (guest?.abandoned ?? false)
        : host.abandoned;
    if (opponentAbandoned) {
      _handleOpponentLeft();
      return;
    }

    switch (room.status) {
      case 'waiting':
        _uiState = GameScreenState.waiting();
        break;
      case 'rolling':
        // 2. サイコロ結果の確認待ち
        final bothRolled = host.rolled && (guest?.rolled ?? false);

        if (bothRolled && myConfirmedRoll) {
          _uiState = GameScreenState.playing(room);
        } else {
          _uiState = GameScreenState.rolling(room);
        }
        break;
      case 'playing':
        _uiState = GameScreenState.playing(room);
        break;
      case 'roundResult':
        _uiState = GameScreenState.roundResult(room);
        break;
      case 'finished':
        _uiState = GameScreenState.finished(room);
        break;
      default:
        _uiState = GameScreenState.loading();
    }
  }

  void _handleOpponentLeft() {
    _uiState = _uiState.copyWithOpponentLeft();
    notifyListeners();
  }

  /// ターン変更チェック
  void _checkTurnChange(GameRoom room) {
    if (room.currentTurn != _lastTurn &&
        (room.status == 'playing' || room.status == 'rolling')) {
      final myConfirmedRound = isHost
          ? room.host.confirmedRoundResult
          : (room.guest?.confirmedRoundResult ?? false);

      if (myConfirmedRound) {
        resetLocalState();
        _lastTurn = room.currentTurn;
      }
    }
  }

  /// ローカル状態をリセットする
  void resetLocalState() {
    _hasRolled = false;
    _hasPlacedBet = false;
    _bets = {'0': 0, '1': 0, '2': 0};
  }

  Future<void> confirmRoll() async {
    try {
      await _gameService.confirmRoll(roomCode, playerId);
      notifyListeners();
    } catch (e) {
      _uiState = _uiState.copyWithError('確認に失敗しました: $e');
      notifyListeners();
    }
  }

  // ===== ユーザーアクション（Viewから呼ばれる） =====
  Future<void> rollDice() async {
    try {
      await _gameService.rollDice(roomCode, playerId);
      _hasRolled = true;
      notifyListeners();
    } catch (e) {
      _uiState = _uiState.copyWithError('サイコロを振れませんでした: $e');
      notifyListeners();
    }
  }

  /// 賭けを置く
  Future<void> placeBets() async {
    try {
      await _gameService.placeBets(roomCode, playerId, _bets);
      _hasPlacedBet = true;
      notifyListeners();
    } catch (e) {
      _uiState = _uiState.copyWithError('賭けに失敗しました: $e');
      notifyListeners();
    }
  }

  Future<void> nextTurn() async {
    try {
      await _gameService.nextTurn(roomCode, playerId);
    } catch (e) {
      _uiState = _uiState.copyWithError('次のターンに進めませんでした: $e');
      notifyListeners();
    }
  }

  void updateBet(String catIndex, int amount) {
    if (_hasPlacedBet) return;
    if (amount < 0) return;

    _bets[catIndex] = amount;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    try {
      await _gameService.leaveRoom(roomCode, playerId);
      onOpponentLeft?.call();
    } catch (e) {
      _uiState = _uiState.copyWithError('退出に失敗しました: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
