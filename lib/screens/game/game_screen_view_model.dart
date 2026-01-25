import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/game_room.dart';
import '../../constants/game_constants.dart';
import '../../services/game_service.dart';
import 'game_screen_state.dart';
import 'player_data.dart';

/// ラウンド結果のUI表示用アイテム
class RoundDisplayItem {
  final String catName;
  final int catCost;
  final String winnerLabel;
  final Color cardColor;
  final Color winnerTextColor;
  final Color catIconColor;
  final int myBet;
  final int opponentBet;

  const RoundDisplayItem({
    required this.catName,
    required this.catCost,
    required this.winnerLabel,
    required this.cardColor,
    required this.winnerTextColor,
    required this.catIconColor,
    required this.myBet,
    required this.opponentBet,
  });
}

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

  /// 最終ターンの結果表示用データ
  List<RoundDisplayItem> get lastRoundDisplayItems {
    final room = _currentRoom;
    final result = room?.lastRoundResult;
    if (room == null || result == null) return [];

    final myRole = isHost ? Winner.host : Winner.guest;
    final opponentRole = isHost ? Winner.guest : Winner.host;

    return List.generate(result.catNames.length, (i) {
      final winner = result.getWinner(i);

      String label = '引き分け';
      Color cardColor = Colors.grey.shade50;
      Color textColor = Colors.grey;

      if (winner == myRole) {
        label = 'あなた獲得';
        cardColor = Colors.green.shade50;
        textColor = Colors.green;
      } else if (winner == opponentRole) {
        label = '相手獲得';
        cardColor = Colors.red.shade50;
        textColor = Colors.red;
      }

      return RoundDisplayItem(
        catName: result.catNames[i],
        catCost: result.catCosts[i],
        winnerLabel: label,
        cardColor: cardColor,
        winnerTextColor: textColor,
        catIconColor: _getCatColor(result.catNames[i]),
        myBet: result.getBet(i, isHost ? 'host' : 'guest'),
        opponentBet: result.getBet(i, isHost ? 'guest' : 'host'),
      );
    });
  }

  /// 自分の獲得した猫のサマリーテキスト
  String get myCatsWonSummary {
    final data = playerData;
    if (data == null) return '';
    return _formatCatsSummary(data.myCatsWon);
  }

  /// 相手の獲得した猫のサマリーテキスト
  String get opponentCatsWonSummary {
    final data = playerData;
    if (data == null) return '';
    return _formatCatsSummary(data.opponentCatsWon);
  }

  /// 猫の名前に応じて色を返す（内部用ヘルパー）
  Color _getCatColor(String catName) {
    switch (catName) {
      case '茶トラねこ':
        return Colors.orange;
      case '白ねこ':
        return Colors.grey.shade300;
      case '黒ねこ':
        return Colors.black;
      default:
        return Colors.orange;
    }
  }

  /// 獲得した猫を種類別にフォーマット（内部用ヘルパー）
  String _formatCatsSummary(List<String> catsWon) {
    final counts = <String, int>{'茶トラねこ': 0, '白ねこ': 0, '黒ねこ': 0};
    for (final cat in catsWon) {
      if (counts.containsKey(cat)) {
        counts[cat] = counts[cat]! + 1;
      }
    }
    return '茶トラ${counts['茶トラねこ']}匹 白${counts['白ねこ']}匹 黒${counts['黒ねこ']}匹';
  }

  /// 最終勝者のラベル
  String get finalWinnerLabel {
    final room = _currentRoom;
    if (room == null || room.status != GameStatus.finished) return '';

    final myRole = isHost ? Winner.host : Winner.guest;
    if (room.finalWinner == Winner.draw) return '引き分け';
    return room.finalWinner == myRole ? 'あなたの勝利！' : '敗北...';
  }

  /// 最終勝者の色
  Color get finalWinnerColor {
    final room = _currentRoom;
    if (room == null || room.status != GameStatus.finished) return Colors.black;

    final myRole = isHost ? Winner.host : Winner.guest;
    if (room.finalWinner == Winner.draw) return Colors.grey;
    return room.finalWinner == myRole ? Colors.green : Colors.red;
  }

  /// 現在表示すべきターン数
  int get displayTurn => playerData?.displayTurn ?? 0;

  /// 自分がラウンド結果を確認済みかどうか
  bool get isRoundResultConfirmed =>
      playerData?.isMyRoundResultConfirmed ?? false;

  /// このラウンドでの自分の勝利数
  int get myRoundWinCount => playerData?.myRoundWinCount ?? 0;

  /// このラウンドでの相手の勝利数
  int get opponentRoundWinCount => playerData?.opponentRoundWinCount ?? 0;

  /// 相手の準備状態のラベル
  String get opponentReadyStatusLabel {
    final data = playerData;
    if (data == null) return '';
    return data.opponentReady ? '準備完了！' : '選択中...';
  }

  /// 相手の準備状態の色
  Color get opponentReadyStatusColor {
    final data = playerData;
    if (data == null) return Colors.grey;
    return data.opponentReady ? Colors.green : Colors.orange;
  }

  /// 残りの魚の表示ラベル
  String get myRemainingFishLabel {
    final data = playerData;
    if (data == null) return '';
    final remaining = data.myFishCount - totalBet;
    return '残りの魚: $remaining / ${data.myFishCount} 🐟';
  }

  /// 確定ボタンのラベル
  String get confirmBetsButtonLabel {
    return _hasPlacedBet ? '確定済み' : '確定';
  }

  /// サイコロボタンのラベル
  String get rollButtonLabel {
    return _hasRolled ? '振りました' : 'サイコロを振る';
  }

  /// サイコロボタンの色
  Color get rollButtonColor {
    return _hasRolled ? Colors.grey : Colors.orange;
  }

  /// 相手のサイコロ結果ステータスラベル
  String get opponentRollStatusLabel {
    final data = playerData;
    if (data == null) return '';
    if (data.opponentRolled && data.opponentDiceRoll != null) {
      return '魚を ${data.opponentDiceRoll} 匹獲得しました！';
    }
    return 'サイコロを振っています...';
  }

  /// 相手のサイコロ結果ステータスラベルの色
  Color get opponentRollStatusColor {
    final data = playerData;
    if (data == null) return Colors.grey;
    return data.opponentRolled ? Colors.green : Colors.orange;
  }

  /// 猫のアイコン色を取得（外部View用）
  Color getCatIconColor(String catName) => _getCatColor(catName);

  // --- ローカルの描画分岐ロジック ---

  /// 自分のサイコロ結果を表示すべきか
  bool get shouldShowMyRollResult =>
      playerData?.shouldShowMyRollResult ?? false;

  /// 相手のサイコロ結果を表示すべきか
  bool get shouldShowOpponentRollResult =>
      playerData?.shouldShowOpponentRollResult ?? false;

  /// ロールフェーズから次へ進める状態か
  bool get canProceedFromRoll => playerData?.canProceedFromRoll ?? false;

  /// 自分の準備（確定）が終わっているか
  bool get isMyReady => playerData?.myReady ?? false;

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
        room.lastRoundResult?.winners != null &&
        (room.status == GameStatus.rolling ||
            room.status == GameStatus.playing)) {
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
      case GameStatus.waiting:
        _uiState = GameScreenState.waiting();
        break;
      case GameStatus.rolling:
        // 2. サイコロ結果の確認待ち
        final bothRolled = host.rolled && (guest?.rolled ?? false);

        if (bothRolled && myConfirmedRoll) {
          _uiState = GameScreenState.playing(room);
        } else {
          _uiState = GameScreenState.rolling(room);
        }
        break;
      case GameStatus.playing:
        _uiState = GameScreenState.playing(room);
        break;
      case GameStatus.roundResult:
        _uiState = GameScreenState.roundResult(room);
        break;
      case GameStatus.finished:
        _uiState = GameScreenState.finished(room);
        break;
    }
  }

  void _handleOpponentLeft() {
    _uiState = _uiState.copyWithOpponentLeft();
    notifyListeners();
  }

  /// ターン変更チェック
  void _checkTurnChange(GameRoom room) {
    // ターン番号が増えたらローカル状態をリセット
    if (room.currentTurn > _lastTurn) {
      resetLocalState();
      _lastTurn = room.currentTurn;
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
