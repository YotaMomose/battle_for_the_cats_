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
  StreamSubscription<GameRoom>? _roomSubscription;

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
  }) : _gameService = gameService {
    _init();
  }

  // ===== 初期化 =====
  void _init() {
    _roomSubscription = _gameService.watchRoom(roomCode).listen(
      (room) {
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
    switch (room.status) {
      case 'waiting':
        _uiState = GameScreenState.waiting();
        break;
      case 'rolling':
        _uiState = GameScreenState.rolling(room);
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

  void _checkTurnChange(GameRoom room) {
    if (room.currentTurn != _lastTurn &&
        (room.status == 'playing' || room.status == 'rolling')) {
      resetLocalState();
      _lastTurn = room.currentTurn;
    }
  }

  void resetLocalState() {
    _hasRolled = false;
    _hasPlacedBet = false;
    _bets = {'0': 0, '1': 0, '2': 0};
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

  Future<void> placeBets() async {
    if (totalBet == 0) {
      _uiState = _uiState.copyWithError('少なくとも1匹以上の魚を置いてください');
      notifyListeners();
      return;
    }

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
      await _gameService.nextTurn(roomCode);
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

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
