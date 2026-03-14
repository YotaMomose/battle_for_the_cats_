import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/game_room.dart';
import '../../models/bets.dart';
import '../../models/item.dart';
import '../../models/cat_inventory.dart';
import '../../models/user_profile.dart';
import '../../constants/game_constants.dart';
import '../../services/game_service.dart';
import '../../domain/win_condition.dart';
import '../../repositories/firestore_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/friend_repository.dart';
import '../../services/invitation_service.dart';
import 'game_screen_state.dart';
import 'player_data.dart';

/// ラウンド結果のUI表示用アイテム
class RoundDisplayItem {
  // ... existing fields
  final String catName;
  final int catCost;
  final String winnerLabel;
  final Color cardColor;
  final Color winnerTextColor;
  final Color catIconColor;
  final IconData catIcon;
  final String? imagePath;
  final int myBet;
  final int opponentBet;
  final ItemType? myItem;
  final ItemType? opponentItem;

  const RoundDisplayItem({
    required this.catName,
    required this.catCost,
    required this.winnerLabel,
    required this.cardColor,
    required this.winnerTextColor,
    required this.catIconColor,
    required this.catIcon,
    this.imagePath,
    required this.myBet,
    required this.opponentBet,
    this.myItem,
    this.opponentItem,
  });
}

/// 最終結果でのカード表示用データ
class FinalResultCardInfo {
  final String name;
  final Color color;
  final IconData icon;
  final String? imagePath;
  final bool isWinningCard;

  const FinalResultCardInfo({
    required this.name,
    required this.color,
    required this.icon,
    this.imagePath,
    required this.isWinningCard,
  });
}

/// ゲーム画面のViewModel
class GameScreenViewModel extends ChangeNotifier {
  final GameService _gameService;
  final String roomCode;
  final String playerId;
  final bool isHost;

  final UserRepository _userRepository = UserRepository(
    repository: FirestoreRepository(),
  );
  final FriendRepository _friendRepository = FriendRepository(
    repository: FirestoreRepository(),
  );
  final InvitationService _invitationService = InvitationService();

  // フレンドリスト
  List<UserProfile> _friends = [];
  List<UserProfile> get friends => _friends;
  bool _isLoadingFriends = false;
  bool get isLoadingFriends => _isLoadingFriends;

  // ===== View用の状態 =====
  GameRoom? _currentRoom;
  GameScreenState _uiState = GameScreenState.loading();

  // ローカル状態
  bool _hasRolled = false;
  bool _hasPlacedBet = false;
  Bets _bets = Bets.empty();
  int _lastTurn = 0;

  // Stream購読
  StreamSubscription<GameRoom?>? _roomSubscription;

  // コールバック
  final VoidCallback? onOpponentLeft;

  // 退出処理中かどうか
  bool _isExiting = false;

  // 戦績記録済みフラグ
  bool _hasRecordedFinalResult = false;

  // ===== Getters (Viewから参照) =====
  GameScreenState get uiState => _uiState;
  bool get hasRolled => _hasRolled;
  bool get hasPlacedBet => _hasPlacedBet;
  Map<String, int> get bets => _bets.toMap();
  int get totalBet => _bets.total;
  bool get isWaiting => _uiState is WaitingState;
  bool get isRolling => _uiState is RollingState;
  bool get isPlaying => _uiState is PlayingState;
  bool get isRoundResult => _uiState is RoundResultState;
  bool get isFinished => _uiState is FinishedState;
  bool get isFatCatEvent => _uiState is FatCatEventState;
  ItemType? getPlacedItem(String catIndex) => _bets.getItem(catIndex);

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

    return List.generate(result.cats.length, (i) {
      final winner = result.getWinner(i);
      final cat = result.cats[i];

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
        catName: cat.name,
        catCost: cat.cost,
        winnerLabel: label,
        cardColor: cardColor,
        winnerTextColor: textColor,
        catIconColor: _getCatColor(cat.name),
        catIcon: _getCatIcon(cat.name),
        imagePath: _getCatImagePath(cat.name),
        myBet: result.getBet(i, isHost ? 'host' : 'guest'),
        opponentBet: result.getBet(i, isHost ? 'guest' : 'host'),
        myItem: result.getItem(i, isHost ? 'host' : 'guest'),
        opponentItem: result.getItem(i, isHost ? 'guest' : 'host'),
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

  /// 自分の獲得した全カードの詳細
  List<FinalResultCardInfo> get myWonCardDetails {
    final data = playerData;
    if (data == null) return [];
    return _getWonCardDetails(data.myCatsWon);
  }

  /// 相手の獲得した全カードの詳細
  List<FinalResultCardInfo> get opponentWonCardDetails {
    final data = playerData;
    if (data == null) return [];
    return _getWonCardDetails(data.opponentCatsWon);
  }

  List<FinalResultCardInfo> _getWonCardDetails(CatInventory inventory) {
    final winningIndices = StandardWinCondition().getWinningIndices(inventory);
    return List.generate(inventory.all.length, (i) {
      final cat = inventory.all[i];
      return FinalResultCardInfo(
        name: cat.name,
        color: _getCatColor(cat.name),
        icon: _getCatIcon(cat.name),
        imagePath: _getCatImagePath(cat.name),
        isWinningCard: winningIndices.contains(i),
      );
    });
  }

  /// 猫の名前に応じて色を返す（内部用ヘルパー）
  Color _getCatColor(String catName) {
    if (catName.contains(GameConstants.catOrange)) {
      return Colors.orange;
    }
    if (catName.contains(GameConstants.catWhite)) {
      return Colors.grey[300]!;
    }
    if (catName.contains(GameConstants.catBlack)) {
      return Colors.grey[800]!;
    }
    if (catName == GameConstants.itemShop) {
      return Colors.blue;
    }
    if (catName == GameConstants.fisherman) {
      return Colors.cyan;
    }
    return Colors.grey;
  }

  IconData _getCatIcon(String catName) {
    if (catName == GameConstants.itemShop) {
      return Icons.store;
    }
    if (catName == GameConstants.fisherman) {
      return Icons.sailing;
    }
    return Icons.pets;
  }

  /// 猫の名前に応じて画像パスを返す（内部用ヘルパー）
  String? _getCatImagePath(String catName) {
    if (catName.contains(GameConstants.catOrange)) {
      return 'assets/images/tyatoranekopng.png';
    }
    if (catName.contains(GameConstants.catWhite)) {
      return 'assets/images/sironeko.png';
    }
    if (catName.contains(GameConstants.catBlack)) {
      return 'assets/images/kuroneko.png';
    }
    if (catName == GameConstants.dog) {
      return 'assets/images/inu.png';
    }
    if (catName == GameConstants.fisherman) {
      return 'assets/images/ryousi.png';
    }
    if (catName == GameConstants.itemShop) {
      return 'assets/images/shop.png';
    }
    return null;
  }

  /// 獲得した猫を種類別にフォーマット（内部用ヘルパー）
  String _formatCatsSummary(CatInventory inventory) {
    final counts = inventory.countByName();
    final brown = counts[GameConstants.catOrange] ?? 0;
    final white = counts[GameConstants.catWhite] ?? 0;
    final black = counts[GameConstants.catBlack] ?? 0;
    return '茶トラ$brown匹 白$white匹 黒$black匹';
  }

  /// 最終勝者のラベル
  String get finalWinnerLabel {
    final room = _currentRoom;
    if (room == null || room.status != GameStatus.finished) return '';

    final myRole = isHost ? Winner.host : Winner.guest;
    final opponent = isHost ? room.guest : room.host;
    final opponentAbandoned = opponent?.abandoned ?? false;

    if (room.finalWinner == Winner.draw) return '引き分け';
    final winnerName = room.finalWinner == myRole
        ? myDisplayName
        : opponentDisplayName;

    if (opponentAbandoned && room.finalWinner == myRole) {
      return '👑 $winnerName の不戦勝！\n(相手の退出)';
    }

    return room.finalWinner == myRole
        ? '👑 $winnerName の勝利！'
        : '$winnerName の勝利...';
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

  /// 自分の表示名
  String get myDisplayName => playerData?.myDisplayName ?? 'あなた';

  /// 自分のアイコン（絵文字）
  String get myIconEmoji =>
      UserIcon.fromId(playerData?.myIconId ?? 'cat_orange').emoji;

  /// 相手の表示名
  String get opponentDisplayName => playerData?.opponentDisplayName ?? '相手';

  /// 相手のアイコン（絵文字）
  String get opponentIconEmoji =>
      UserIcon.fromId(playerData?.opponentIconId ?? 'cat_orange').emoji;

  /// 残りの魚の表示ラベル
  String get myRemainingFishLabel {
    final data = playerData;
    if (data == null) return '';
    final remaining = data.myFishCount - totalBet;
    return '$myDisplayName の魚: $remaining / ${data.myFishCount} 🐟';
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
      final totalFish = data.opponentDiceRoll! + data.opponentFishermanCount;
      return '$opponentDisplayName は 魚を $totalFish 匹獲得しました！';
    }
    return '$opponentDisplayName がサイコロを振っています...';
  }

  /// 相手のサイコロ結果ステータスラベルの色
  Color get opponentRollStatusColor {
    final data = playerData;
    if (data == null) return Colors.grey;
    return data.opponentRolled ? Colors.green : Colors.orange;
  }

  /// 猫のアイコン色を取得（外部View用）
  Color getCatIconColor(String catName) => _getCatColor(catName);

  /// 猫のアイコン種類を取得（外部View用）
  IconData getCatIconData(String catName) => _getCatIcon(catName);

  /// 猫の画像パスを取得（外部View用）
  String? getCatImagePath(String catName) => _getCatImagePath(catName);

  /// アイテムのアイコンを取得（内部用ヘルパー）
  IconData _getItemIcon(ItemType? type) {
    if (type == null) return Icons.help_outline;
    switch (type) {
      case ItemType.catTeaser:
        return Icons.auto_awesome;
      case ItemType.surpriseHorn:
        return Icons.campaign;
      case ItemType.matatabi:
        return Icons.monetization_on;
      case ItemType.unknown:
        return Icons.help_outline;
    }
  }

  /// アイテムのアイコンを取得（外部View用）
  IconData getItemIconData(ItemType? type) => _getItemIcon(type);

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
              if (!_isExiting) {
                if (_uiState is WaitingState && !isHost) {
                  _handleHostClosed();
                } else {
                  _handleOpponentLeft();
                }
              }
              return;
            }
            _currentRoom = room;
            _updateUiState(room);
            _syncWithServerState(room);
            _checkTurnChange(room);
            notifyListeners();
          },
          onError: (error) {
            _uiState = _uiState.copyWithError('データの取得に失敗しました: $error');
            notifyListeners();
          },
        );
  }

  void _updateUiState(GameRoom room) {
    final host = room.host;
    final guest = room.guest;

    // --- 自分が追い出された場合（拒否されたなど）のチェック ---
    if (!isHost && guest == null) {
      if (!_isExiting) {
        if (room.status == GameStatus.waiting) {
          _handleKicked();
        } else {
          _handleOpponentLeft();
        }
      }
      return;
    }

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
    // 待機中やゲーム終了後はチェックをスキップ（終了後はリザルト画面を見せるため）
    if (room.status != GameStatus.waiting &&
        room.status != GameStatus.finished) {
      final opponentAbandoned = isHost
          ? (guest?.abandoned ?? false)
          : host.abandoned;
      if (opponentAbandoned) {
        // 自己退出中なら処理をスキップ
        if (!_isExiting) {
          _handleOpponentLeft();
        }
        return;
      }
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
        _recordMatchResultIfFinished(room);
        break;
      case GameStatus.fatCatEvent:
        final myConfirmedFatCat = isHost
            ? host.confirmedFatCatEvent
            : (guest?.confirmedFatCatEvent ?? false);
        if (myConfirmedFatCat) {
          // 自分が確認済みならサイコロフェーズ（次のターン）を表示
          _uiState = GameScreenState.rolling(room);
        } else {
          _uiState = GameScreenState.fatCatEvent(room);
        }
        break;
    }
  }

  void _handleOpponentLeft() {
    _uiState = _uiState.copyWithOpponentLeft();
    notifyListeners();
  }

  void _handleKicked() {
    _uiState = _uiState.copyWithKicked();
    notifyListeners();
  }

  void _handleHostClosed() {
    _uiState = _uiState.copyWithRoomClosed();
    notifyListeners();
  }

  /// ゲーム終了時に戦績を記録する
  Future<void> _recordMatchResultIfFinished(GameRoom room) async {
    if (_hasRecordedFinalResult) return;
    if (room.status != GameStatus.finished || room.finalWinner == null) return;

    final myRole = isHost ? Winner.host : Winner.guest;
    final opponentId = isHost ? room.guestId : room.hostId;

    if (opponentId == null) return;

    _hasRecordedFinalResult = true;

    try {
      if (room.finalWinner == Winner.draw) {
        // 引き分けの場合は現状記録しない（または両方に敗北扱い？仕様による）
        return;
      }

      final isWin = room.finalWinner == myRole;
      await _friendRepository.recordMatchResult(
        userId: playerId,
        friendId: opponentId,
        isWin: isWin,
      );
      debugPrint('[GameScreenViewModel] 戦績を記録しました: ${isWin ? "勝利" : "敗北"}');
    } catch (e) {
      debugPrint('[GameScreenViewModel] 戦績の記録に失敗しました: $e');
    }
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
    _bets = Bets.empty();
  }

  /// サーバーの状態とローカルの操作状態を同期する
  void _syncWithServerState(GameRoom room) {
    final my = isHost ? room.host : room.guest;
    if (my == null) return;

    // サーバー側で「まだ」の状態なのにローカルで「完了」になっていれば、
    // 書き込みの失敗や上書きが発生した可能性があるため、ボタンを再活性化する
    if (room.status == GameStatus.rolling) {
      if (!my.rolled && _hasRolled) {
        debugPrint(
          '[GameScreenViewModel] Roll state synced: server says not rolled',
        );
        _hasRolled = false;
      }
    } else if (room.status == GameStatus.playing) {
      if (!my.ready && _hasPlacedBet) {
        debugPrint(
          '[GameScreenViewModel] Bet state synced: server says not ready',
        );
        _hasPlacedBet = false;
      }
    }
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
      await _gameService.placeBets(
        roomCode,
        playerId,
        _bets.toMap(),
        _bets.itemsToMap(),
      );
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

  /// 太っちょネコイベントを承認する
  Future<void> confirmFatCatEvent() async {
    try {
      await _gameService.confirmFatCatEvent(roomCode, playerId);
    } catch (e) {
      _uiState = _uiState.copyWithError('太っちょネコイベントの承認に失敗しました: $e');
      notifyListeners();
    }
  }

  void updateBet(String catIndex, int amount) {
    if (_hasPlacedBet) return;
    if (amount < 0) return;

    final newMap = Map<String, int>.from(_bets.toMap());
    newMap[catIndex] = amount;
    _bets = Bets(
      newMap,
      _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      ),
    );
    notifyListeners();
  }

  /// アイテムを配置する
  void updateItemPlacement(String catIndex, ItemType? item) {
    if (_hasPlacedBet) return;

    final currentBetsMap = _bets.toMap();
    final currentItemsMap = _bets.itemsToMap().map(
      (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
    );

    // 他の場所に同じアイテムがあれば削除（1ターンに1回制限）
    if (item != null) {
      currentItemsMap.forEach((key, value) {
        if (value == item) currentItemsMap[key] = null;
      });
    }

    currentItemsMap[catIndex] = item;
    _bets = Bets(currentBetsMap, currentItemsMap);
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    try {
      _isExiting = true; // 退出フラグを立てる

      // バトル中（待機画面以外かつ未終了）に自分から退出した場合は、負けとして記録
      final room = _currentRoom;
      if (room != null &&
          room.status != GameStatus.waiting &&
          room.status != GameStatus.finished &&
          !_hasRecordedFinalResult) {
        final opponentId = isHost ? room.guestId : room.hostId;
        if (opponentId != null) {
          _hasRecordedFinalResult = true; // 早期マーク
          await _friendRepository.recordMatchResult(
            userId: playerId,
            friendId: opponentId,
            isWin: false,
          );
          debugPrint('[GameScreenViewModel] 途中退出による敗北を記録しました');
        }
      }

      await _gameService.leaveRoom(roomCode, playerId);
      onOpponentLeft?.call();
    } catch (e) {
      _isExiting = false; // 失敗した場合はフラグを戻す
      _uiState = _uiState.copyWithError('退出に失敗しました: $e');
      notifyListeners();
    }
  }

  /// ゲームを開始する（ホストが参加者を承認した際）
  Future<void> startGame() async {
    if (!isHost) return;
    try {
      await _gameService.startGame(roomCode, playerId);
    } catch (e) {
      _uiState = _uiState.copyWithError('ゲームの開始に失敗しました: $e');
      notifyListeners();
    }
  }

  /// 参加者を拒否する
  Future<void> rejectGuest() async {
    if (!isHost) return;
    try {
      await _gameService.rejectGuest(roomCode, playerId);
    } catch (e) {
      _uiState = _uiState.copyWithError('不参加処理に失敗しました: $e');
      notifyListeners();
    }
  }

  /// 参加者がいるかどうか
  bool get hasGuest => _currentRoom?.guest != null;

  /// フレンド一覧を読み込む
  Future<void> loadFriends() async {
    if (_isLoadingFriends) return;
    _isLoadingFriends = true;
    notifyListeners();

    try {
      final friendIds = await _friendRepository.getFriendIds(playerId);
      final profiles = <UserProfile>[];
      for (final id in friendIds) {
        final profile = await _userRepository.getProfile(id);
        if (profile != null) profiles.add(profile);
      }
      _friends = profiles;
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  /// フレンドを招待する
  Future<void> inviteFriend(UserProfile friend) async {
    final data = playerData;
    if (data == null) return;

    final sender = UserProfile(
      uid: playerId,
      displayName: data.myDisplayName,
      iconId: data.myIconId,
    );

    try {
      await _invitationService.sendInvitation(
        sender: sender,
        receiverId: friend.uid,
        roomCode: roomCode,
      );
    } catch (e) {
      _uiState = _uiState.copyWithError('招待の送信に失敗しました: $e');
      notifyListeners();
    }
  }

  /// 自分がアイテムを復活できる状態か
  bool get canReviveItem => (playerData?.myPendingItemRevivals ?? 0) > 0;

  /// 復活可能なアイテムリスト（所持していないアイテム）
  List<ItemType> get revivableItems {
    final data = playerData;
    if (data == null) return [];

    return ItemType.values.where((type) {
      if (type == ItemType.unknown) return false;
      return data.myInventory.count(type) == 0;
    }).toList();
  }

  /// アイテム復活を実行
  Future<void> reviveItem(ItemType item) async {
    try {
      await _gameService.reviveItem(roomCode, playerId, item);
      notifyListeners();
    } catch (e) {
      _uiState = _uiState.copyWithError('アイテムの復活に失敗しました: $e');
      notifyListeners();
    }
  }

  /// 犬の効果を適用できるか
  bool get canChaseAway => (playerData?.myPendingDogChases ?? 0) > 0;

  /// 犬の効果の残り回数
  int get remainingDogChases => playerData?.myPendingDogChases ?? 0;

  /// 追い出す対象として選べる相手のカードリスト
  List<String> get availableTargetsForDog {
    final data = playerData;
    if (data == null) return [];
    return data.opponentCatsWon.names;
  }

  /// 相手のカードを追い出す
  Future<void> chaseAwayCard(String? targetCardName) async {
    try {
      await _gameService.chaseAwayCard(roomCode, playerId, targetCardName);
      notifyListeners();
    } catch (e) {
      _uiState = _uiState.copyWithError('追い出しに失敗しました: $e');
      notifyListeners();
    }
  }

  /// 犬の効果による通知メッセージリスト
  List<String> get dogEffectNotifications {
    final data = playerData;
    if (data == null) return [];

    return data.chasedCards.map((chased) {
      if (chased.chaserPlayerId != playerId) {
        // 相手が自分のカードを追い出した場合
        return '🐶 $opponentDisplayName の犬によって「${chased.cardName}」が逃げてしまいました！';
      } else {
        // 自分が相手のカードを追い出した場合
        return '🐶 $myDisplayName の犬が相手の「${chased.cardName}」を追い出しました！';
      }
    }).toList();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
