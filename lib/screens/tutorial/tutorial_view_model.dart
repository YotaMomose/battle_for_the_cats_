import 'package:flutter/material.dart';
import '../../models/game_room.dart';
import '../game/player_data.dart';
import '../../models/bets.dart';
import '../../models/player.dart';
import '../../models/cat_inventory.dart';
import '../../models/item_inventory.dart';
import '../../models/item.dart';
import '../../models/cards/round_cards.dart';
import '../../models/cards/regular_cat.dart';
import '../../constants/game_constants.dart';

class TutorialViewModel extends ChangeNotifier {
  late final GameRoom _room;
  int _currentStep = 0;
  int _currentBet = 0;
  Bets _bets = Bets.empty();
  bool _hasPlacedBet = false;

  TutorialViewModel() {
    // チュートリアル用の初期設定
    final player = Player(id: 'me', displayName: 'あなた', iconId: 'cat_orange');
    final elder = Player(id: 'elder', displayName: '長老ねこ', iconId: 'cat_black');

    final round = RoundCards(
      card1: const RegularCat(id: 'white', displayName: 'しろねこ', baseCost: 3),
      card2: const RegularCat(id: 'black', displayName: 'くろねこ', baseCost: 2),
      card3: const RegularCat(id: 'tabby', displayName: '茶トラねこ', baseCost: 1),
    );

    _room = GameRoom(
      roomId: 'tutorial',
      host: player,
      guest: elder,
      currentRound: round,
    );
  }

  // --- チュートリアル用の状態 ---
  int? _randomDiceResult;
  bool _isDiceRolled = false;
  bool _isResultPhase = false;

  // --- Getters ---
  int get totalBet => _bets.total;
  Map<String, int> get bets => _bets.toMap();
  bool get hasPlacedBet => _hasPlacedBet;
  bool get isMyReady => _hasPlacedBet;
  bool get isMyRolled => _isDiceRolled;
  bool get isResultPhase => _isResultPhase;
  int get currentTurn => 1;
  int? get currentDiceRoll => _randomDiceResult;
  String get confirmBetsButtonLabel => _hasPlacedBet ? '確定済み' : '確定する';

  String get myDisplayName => 'あなた';
  String get myIconEmoji => '🐱';
  String get myIconId => 'cat_orange';
  String get opponentDisplayName => '長老ねこ';
  String get opponentIconEmoji => '👴';
  String get opponentIconId => 'cat_black';

  String get opponentReadyStatusLabel => '選択中...';
  Color get opponentReadyStatusColor => const Color.fromARGB(255, 255, 38, 0);

  /// 判定演出用の擬似的なデータ
  List<TutorialRoundResultItem> get roundResultItems {
    return [
      TutorialRoundResultItem(
        catName: 'しろねこ',
        myBet: 3,
        opponentBet: 0,
        winStatus: 'win',
      ),
      TutorialRoundResultItem(
        catName: 'くろねこ',
        myBet: 0,
        opponentBet: 0,
        myItem: ItemType.catTeaser,
        winStatus: 'win',
      ),
      TutorialRoundResultItem(
        catName: '茶トラねこ',
        myBet: 1,
        opponentBet: 0,
        opponentItem: ItemType.matatabi,
        winStatus: 'none', // 誰も獲得できず
      ),
    ];
  }

  PlayerData get playerData {
    final bool isAcquisitionComplete = _currentStep >= 16;
    final int fishAfterBet = 10 - 4; // 3 + 0 + 1 = 4匹消費
    final myCurrentFish = _isDiceRolled
        ? (fishAfterBet + (_randomDiceResult ?? 0))
        : (isAcquisitionComplete ? fishAfterBet : 10);

    final myInventory = CatInventory();
    if (isAcquisitionComplete) {
      myInventory.addCat('しろねこ', 3);
      myInventory.addCat('くろねこ', 2);
    }

    return PlayerData(
      room: _room,
      isHost: true,
      myDisplayName: 'あなた',
      myIconId: 'cat_orange',
      opponentDisplayName: '長老ねこ',
      opponentIconId: 'cat_black',
      myFishCount: myCurrentFish,
      opponentFishCount: 10,
      myCatsWon: myInventory,
      opponentCatsWon: CatInventory(),
      myDiceRoll: _randomDiceResult,
      opponentDiceRoll: null,
      myRolled: _isDiceRolled,
      opponentRolled: false,
      myReady: _hasPlacedBet,
      opponentReady: false,
      myBets: (_currentStep >= 11 && _currentStep < 16) ? _bets : Bets.empty(),
      opponentBets: Bets.empty(),
      myInventory: ItemInventory.initial(),
      opponentInventory: ItemInventory.initial(),
      myPendingItemRevivals: 0,
      myFishermanCount: 0,
      opponentFishermanCount: 0,
      myPendingDogChases: 0,
      chasedCards: [],
    );
  }

  GameRoom get room => _room;
  ItemType? getPlacedItem(String catIndex) => _bets.getItem(catIndex);

  String? getCatImagePath(String catName) {
    if (catName.contains('しろ')) return 'assets/images/sironeko.png';
    if (catName.contains('くろ')) return 'assets/images/kuroneko.png';
    if (catName.contains('茶トラ')) return 'assets/images/tyatoranekopng.png';
    return null;
  }

  IconData getCatIconData(String catName) => Icons.pets;
  Color getCatIconColor(String catName) {
    if (catName.contains('しろ')) return Colors.grey[300]!;
    if (catName.contains('くろ')) return Colors.grey[800]!;
    if (catName.contains('茶トラ')) return Colors.orange;
    return Colors.grey;
  }

  // --- チュートリアル用のメッセージ ---
  String get currentMessage {
    switch (_currentStep) {
      case 0:
        return 'ほっほっほ。ようこそ、猫争奪戦へ！ワシがルールを教えてやろう。';
      case 1:
        return 'このゲームは、お魚をあげて猫たちの信頼を勝ち取るゲームじゃ。';
      case 2:
        return '真ん中に3匹の猫がおるじゃろう？まずは左の「しろねこ」からじゃ。';
      case 3:
        return '「しろ」にお魚を3匹置いておくれ。下の魚をドラッグ、もしくはお皿を数回タップするのじゃ。';
      case 4:
        return 'よしよし、上手じゃ！次は真ん中の「くろねこ」じゃな。';
      case 5:
        return 'ここではアイテムを使ってみよう。「ねこじゃらし」を「くろ」のお皿にドラッグするのじゃ。';
      case 6:
        return '「ねこじゃらし」は相手がお魚を置いていなければ、お魚を使わずに仲間にできる優れものじゃ。';
      case 7:
        return 'バッチリじゃ！最後に右の「茶トラねこ」じゃな。';
      case 8:
        return '「茶トラ」はコスト1じゃから、お魚を1匹だけ置いてみるのじゃ。';
      case 9:
        return 'よし、これですべての準備が整った！それじゃあ右下の「確定する」ボタンを押してみるのじゃ。';
      case 10:
        return '判定が始まるぞ！わくわくするのう。';
      case 11:
        return 'まずは「しろ」じゃな。相手（ワシ）は0匹。お主の勝ちじゃ！';
      case 12:
        return '次は「くろ」じゃな。「ねこじゃらし」のおかげでお魚0匹で仲間にできたぞ。';
      case 13:
        return '最後は「茶トラ」じゃが...おっと！ワシが「またたび」を置いたようじゃ。';
      case 14:
        return '「またたび」はカードの必要コストを2倍にする！コスト1が2になったようじゃな。';
      case 15:
        return 'お主は1匹しか置いておらんから、コスト不足で仲間にできなかったようじゃ。ワシも魚は0匹じゃから誰も仲間にできんかったがの。';
      case 16:
        return '負けることもあるが、次がある！しかし、お魚が少なくなってきたのう。';
      case 17:
        return 'お魚がなくなったらサイコロを振るのじゃ。出た目の数だけお魚が補充されるぞ。';
      case 18:
        return '右下の「サイコロを振る」を押して、お魚を補充するのじゃ！';
      case 19:
        return 'ほっほっほ、これでまた戦えるな！基本はこれだけじゃ。実践あるのみ！さあ、行くのじゃ！';
      default:
        return '';
    }
  }

  // --- アクション属性 ---
  int get currentStep => _currentStep;
  bool get canProgress {
    if (_currentStep == 3) return _bets.getBet('0') >= 3;
    if (_currentStep == 5) return _bets.getItem('1') != null;
    if (_currentStep == 8)
      return _bets.getBet('2') >= 1 || _bets.getItem('2') != null;
    if (_currentStep == 9) return _hasPlacedBet;
    if (_currentStep == 18) return _isDiceRolled;
    return true;
  }

  // --- アクション ---
  void updateBet(String catIndex, int delta) {
    if ((_currentStep == 3 && catIndex == '0') ||
        (_currentStep == 8 && catIndex == '2')) {
      final currentAmount = _bets.getBet(catIndex);
      final newAmount = (currentAmount + delta).clamp(0, 50);

      _bets = Bets(
        Map.from(_bets.toMap())..[catIndex] = newAmount,
        _bets.itemsToMap().map(
          (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
        ),
      );

      if (_currentStep == 3 && newAmount >= 3) {
        _currentStep = 4;
      } else if (_currentStep == 8 && newAmount >= 1) {
        _currentStep = 9;
      }
      notifyListeners();
    }
  }

  void placeBets() {
    if (_currentStep == 9) {
      _hasPlacedBet = true;
      _isResultPhase = true;
      _currentStep = 10;
      notifyListeners();
    }
  }

  void updateItemPlacement(String catIndex, ItemType? item) {
    if (_currentStep == 5 && catIndex == '1' && item == ItemType.catTeaser) {
      final newItemsMap = _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      );
      newItemsMap[catIndex] = item;

      _bets = Bets(_bets.toMap(), newItemsMap);
      _currentStep = 6;
      notifyListeners();
    } else if (_currentStep == 8 && catIndex == '2' && item != null) {
      final newItemsMap = _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      );
      newItemsMap[catIndex] = item;

      _bets = Bets(_bets.toMap(), newItemsMap);
      _currentStep = 9;
      notifyListeners();
    } else if (item == null) {
      final newItemsMap = _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      );
      newItemsMap[catIndex] = null;
      _bets = Bets(_bets.toMap(), newItemsMap);
      notifyListeners();
    }
  }

  void rollDice() {
    if (_currentStep == 18) {
      _randomDiceResult = 4;
      _isDiceRolled = true;
      _currentStep = 19;
      notifyListeners();
    }
  }

  void nextStep() {
    if (canProgress) {
      _currentStep++;
      // 茶トラの解説が終わったら判定終了 (15)
      if (_currentStep == 16) {
        _isResultPhase = false;
      }
      notifyListeners();
    }
  }

  void finishResultPhase() {
    _isResultPhase = false;
    notifyListeners();
  }

  Future<void> completeTutorial() async {
    // 完了
  }
}

class TutorialRoundResultItem {
  final String catName;
  final int myBet;
  final int opponentBet;
  final ItemType? myItem;
  final ItemType? opponentItem;
  final String winStatus;

  TutorialRoundResultItem({
    required this.catName,
    required this.myBet,
    required this.opponentBet,
    this.myItem,
    this.opponentItem,
    required this.winStatus,
  });
}
