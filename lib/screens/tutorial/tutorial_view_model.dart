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
  late GameRoom _room;
  late Player _me;
  late Player _elder;
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

    _me = player;
    _elder = elder;

    _room = GameRoom(
      roomId: 'tutorial',
      host: _me,
      guest: _elder,
      currentRound: round,
    );
  }

  // --- チュートリアル用の状態 ---
  int? _randomDiceResult;
  bool _isDiceRolled = false;
  bool _isResultPhase = false;
  bool _isAnimationFinished = true; // デフォルトは完了状態
  int _round = 1;

  // --- Getters ---
  int get totalBet => _bets.total;
  Map<String, int> get bets => _bets.toMap();
  bool get hasPlacedBet => _hasPlacedBet;
  bool get isMyReady => _hasPlacedBet;
  bool get isMyRolled => _isDiceRolled;
  bool get isResultPhase => _isResultPhase;
  bool get isAnimationFinished => _isAnimationFinished;
  int get round => _round;
  int get currentTurn => _round;
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
    if (_round == 1) {
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
    } else {
      // 第2ターン:
      // 0: しろ(びっくりホーンで引き分け)
      // 1: しろ(自分3、相手4で負け)
      // 2: 茶トラ(自分2、相手1で勝ち)
      return [
        TutorialRoundResultItem(
          catName: 'しろねこ',
          myBet: 0,
          opponentBet: 3,
          myItem: ItemType.surpriseHorn,
          winStatus: 'draw',
        ),
        TutorialRoundResultItem(
          catName: 'しろねこ',
          myBet: 3,
          opponentBet: 4,
          winStatus: 'lose',
        ),
        TutorialRoundResultItem(
          catName: '茶トラねこ',
          myBet: 2,
          opponentBet: 1,
          winStatus: 'win',
        ),
      ];
    }
  }

  PlayerData get playerData {
    final bool isAcquisitionComplete = _currentStep >= 17;
    final int fishAfterBet = 10 - 4; // 3 + 0 + 1 = 4匹消費
    final myCurrentFish = _isDiceRolled
        ? (fishAfterBet + (_randomDiceResult ?? 0))
        : (isAcquisitionComplete ? fishAfterBet : 10);

    final myInventory = CatInventory();
    final oppInventory = CatInventory();

    final myItemInventory = ItemInventory({
      ItemType.catTeaser: _round == 1 ? 1 : 0,
      ItemType.surpriseHorn: 1,
      ItemType.matatabi: 1,
    });

    if (_round >= 2 || isAcquisitionComplete) {
      myInventory.addCat('しろねこ', 3);
      myInventory.addCat('くろねこ', 2);
    }

    if (_isFinalResultPhase) {
      myInventory.addCat('茶トラねこ', 1);
      oppInventory.addCat('しろねこ', 3);
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
      opponentCatsWon: oppInventory,
      myDiceRoll: _randomDiceResult,
      opponentDiceRoll: null,
      myRolled: _isDiceRolled,
      opponentRolled: false,
      myReady: _hasPlacedBet,
      opponentReady: false,
      myBets: (_isResultPhase)
          ? _bets
          : (_round == 1
                ? (_currentStep >= 11 && _currentStep < 17
                      ? _bets
                      : Bets.empty())
                : _bets),
      opponentBets: Bets.empty(),
      myInventory: myItemInventory,
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
        return 'ほっほっほ。ようこそ、にゃんこほいほい！へ！ワシがルールを教えてやろう。';
      case 1:
        return 'このゲームは、お魚をあげてにゃんこをゲットするゲームじゃ。';
      case 2:
        return '先に３匹の同じ種類のにゃんこを集めるか、３匹の違う種類のにゃんこを集めれば勝利じゃ。';
      case 3:
        return '真ん中に3匹の猫がおるじゃろう？この3匹から欲しいにゃんこをゲットするのじゃ。';
      case 4:
        return 'まずは左の「しろねこ」にお魚を3匹置いておくれ。下の魚をドラッグ、もしくはお皿を数回タップするのじゃ。';
      case 5:
        return 'よしよし、上手じゃ！次は真ん中の「くろねこ」じゃな。';
      case 6:
        return 'ここではアイテムを使ってみよう。「ねこじゃらし」を「くろ」のお皿にドラッグするのじゃ。';
      case 7:
        return '「ねこじゃらし」は相手がお魚を置いていなければ、お魚を使わずに仲間にできる優れものじゃ。';
      case 8:
        return 'アイテムは使うとなくなるからタイミングが大事じゃ。最後に右の「茶トラねこ」じゃな。';
      case 9:
        return '「茶トラ」はコスト1じゃから、お魚を1匹だけ置いてみるのじゃ。';
      case 10:
        return 'よし、これですべての準備が整った！それじゃあ右下の「確定する」ボタンを押してみるのじゃ。';
      case 11:
        return '判定が始まるぞ！わくわくするのう。';
      case 12:
        return 'まずは「しろ」じゃな。相手（ワシ）は0匹。お主の勝ちじゃ！';
      case 13:
        return '次は「くろ」じゃな。「ねこじゃらし」のおかげでお魚0匹で仲間にできたぞ。';
      case 14:
        return '最後は「茶トラ」じゃが...おっと！ワシが「またたび」を置いたようじゃ。';
      case 15:
        return '「またたび」はカードの必要コストを2倍にする！コスト1が2になったようじゃな。';
      case 16:
        return 'お主は1匹しか置いておらんから、コスト不足で仲間にできなかったようじゃ。ワシも魚は0匹じゃから誰も仲間にできんかったがの。';
      case 17:
        return '負けることもあるが、次がある！しかし、お魚が少なくなってきたのう。';
      case 18:
        return 'お魚がなくなったらサイコロを振るのじゃ。出た目の数だけお魚が補充されるぞ。';
      case 19:
        return '右下の「サイコロを振る」を押して、お魚を補充するのじゃ！';
      case 20:
        return 'ほっほっほ、これでまた戦えるな！さあ、このまま第2ターンへ進むぞ。';
      case 21:
        return '2ターン目じゃ！ここでお主を勝利に導く秘策を伝授しようかの。';
      case 22:
        return '新しいアイテム「びっくりホーン」を授けるぞ。';
      case 23:
        return 'これは「自分も相手も魚を0にする」という特殊なアイテムじゃ。取られたくないカードに置くのが吉じゃな。';
      case 24:
        return 'まずは一番左の「しろねこ」に「びっくりホーン」を置いてみるのじゃ。';
      case 25:
        return 'よし！これでワシとお主、どちらが魚を置いても驚いて逃げ出してしまうぞ。';
      case 26:
        return '次に、真ん中の「しろねこ」に魚を3匹置いてみるのじゃ。コストぴったりじゃな。';
      case 27:
        return 'ふむ、魚を置いても安心はできんぞ。相手の方が多くの魚を置いた場合は、そちらに取られてしまうのじゃ。';
      case 28:
        return '最後に、右の「茶トラ」を確実に取るために、魚を2匹置いておくのじゃ！';
      case 29:
        return 'ほっほっほ、完璧な布陣じゃな。それでは右下の「確定する」ボタンを押してみるのじゃ。';
      case 30:
        return 'ワシも準備完了じゃ。さあ、2ターン目の判定、いってみようかの！';
      case 31:
        return 'まずは一番左の「しろ」からじゃな。判定、いってみようかの！';
      case 32:
        return 'びっくりホーンでお互いの魚が逃げ出した！誰も仲間にできんかったのう。';
      case 33:
        return '次は真ん中の「しろ」じゃ。お主も3匹置いたが、ワシはどうしたかのう？';
      case 34:
        return 'ワシは4匹置いた。ワシの勝ちじゃな！';
      case 35:
        return 'このように、コストを満たしていても相手より少ないと取られてしまう。駆け引きが重要じゃ。';
      case 36:
        return '最後は右の「茶トラ」！お主は2匹、ワシは1匹。結果は...？';
      case 37:
        return 'お主の勝ちじゃ！「茶トラ」が仲間に加わったぞ。';
      case 38:
        return 'これで「しろ」「くろ」「茶トラ」の3種類が揃ったな！';
      case 39:
        return 'お見事！3種類揃ったのでお主の完全勝利じゃ！';
      case 40:
        return '今回は登場しなかったが、実際のゲームでは他にも様々なキャラクターが登場するぞ。紹介しておこう。';
      case 41:
        return 'よし、これでチュートリアルは終了じゃ。立派なにゃんこホイホイ！プレイヤーになるのじゃぞ！';
      default:
        return '';
    }
  }

  // --- アクション属性 ---
  int get currentStep => _currentStep;
  bool get canProgress {
    // 判定フェーズ中は演出が終わるまで進めない
    if (_isResultPhase && !_isAnimationFinished) return false;

    if (_currentStep == 4) return _bets.getBet('0') >= 3;
    if (_currentStep == 6) return _bets.getItem('1') != null;
    if (_currentStep == 9)
      return _bets.getBet('2') >= 1 || _bets.getItem('2') != null;
    if (_currentStep == 10) return _hasPlacedBet;

    // 第2ターン
    if (_currentStep == 24) return _bets.getItem('0') == ItemType.surpriseHorn;
    if (_currentStep == 26) return _bets.getBet('1') >= 3;
    if (_currentStep == 28) return _bets.getBet('2') >= 2;
    if (_currentStep == 29) return _hasPlacedBet;

    if (_currentStep == 19) return _isDiceRolled;
    return true;
  }

  // --- アクション ---
  void updateBet(String catIndex, int delta) {
    if ((_currentStep == 4 && catIndex == '0') ||
        (_currentStep == 9 && catIndex == '2') ||
        (_currentStep == 26 && catIndex == '1') ||
        (_currentStep == 28 && catIndex == '2') ||
        (_currentStep == 29 && catIndex == '2')) {
      final currentAmount = _bets.getBet(catIndex);
      final newAmount = (currentAmount + delta).clamp(0, 50);

      _bets = Bets(
        Map.from(_bets.toMap())..[catIndex] = newAmount,
        _bets.itemsToMap().map(
          (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
        ),
      );

      if (_currentStep == 4 && newAmount >= 3) {
        _currentStep = 5;
      } else if (_currentStep == 9 && newAmount >= 1) {
        _currentStep = 10;
      } else if (_currentStep == 26 && catIndex == '1' && newAmount >= 3) {
        _currentStep = 27;
      } else if (_currentStep == 28 && catIndex == '2' && newAmount >= 2) {
        _currentStep = 29;
      }
      notifyListeners();
    }
  }

  void placeBets() {
    if (_currentStep == 10 || _currentStep == 29) {
      _hasPlacedBet = true;
      if (_currentStep == 10) {
        _isResultPhase = true;
        _currentStep = 11;
        _isAnimationFinished = false;
      } else {
        _currentStep = 30; // セリフ「ワシも準備完了じゃ」へ
      }
      notifyListeners();
    }
  }

  void updateItemPlacement(String catIndex, ItemType? item) {
    if ((_currentStep == 6 && catIndex == '1' && item == ItemType.catTeaser) ||
        (_currentStep == 9 && catIndex == '2' && item != null) ||
        (_currentStep == 24 &&
            catIndex == '0' &&
            item == ItemType.surpriseHorn)) {
      final newItemsMap = _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      );
      newItemsMap[catIndex] = item;

      _bets = Bets(_bets.toMap(), newItemsMap);

      if (_currentStep == 6) {
        _currentStep = 7;
      } else if (_currentStep == 9) {
        _currentStep = 10;
      } else if (_currentStep == 24) {
        _currentStep = 25;
      }
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
    if (_currentStep == 19) {
      _randomDiceResult = 4;
      _isDiceRolled = true;
      _currentStep = 20;
      notifyListeners();
    }
  }

  void nextStep() {
    if (canProgress) {
      if (_currentStep == 20) {
        startRound2();
        return;
      }
      if (_currentStep == 16) {
        _isResultPhase = false;
        _currentStep = 17;
        notifyListeners();
        return;
      }
      if (_currentStep == 30) {
        _isResultPhase = true;
        _currentStep = 31;
        _isAnimationFinished = false;
        notifyListeners();
        return;
      }
      if (_currentStep == 37) {
        _isResultPhase = false;
        _isFinalResultPhase = true;
        _currentStep = 38;
        notifyListeners();
        return;
      }
      if (_currentStep == 40) {
        _showCharacterIntro = true;
        notifyListeners();
        return;
      }
      if (_currentStep == 41) {
        // 完了
        return;
      }
      _currentStep++;
      notifyListeners();
    }
  }

  bool _isFinalResultPhase = false;
  bool get isFinalResultPhase => _isFinalResultPhase;

  bool _showCharacterIntro = false;
  bool get showCharacterIntro => _showCharacterIntro;

  void completeCharacterIntro() {
    _showCharacterIntro = false;
    _currentStep = 41;
    notifyListeners();
  }

  void startRound2() {
    _currentStep = 21;
    _round = 2;
    _hasPlacedBet = false;
    _isDiceRolled = false;
    _isResultPhase = false;
    _bets = Bets.empty();

    // 第2ターンのカードセット
    final round2 = RoundCards(
      card1: const RegularCat(id: 'white1', displayName: 'しろねこ', baseCost: 3),
      card2: const RegularCat(id: 'white2', displayName: 'しろねこ', baseCost: 3),
      card3: const RegularCat(id: 'tabby2', displayName: '茶トラねこ', baseCost: 1),
    );

    _room = GameRoom(
      roomId: 'tutorial_2',
      host: _me,
      guest: _elder,
      status: GameStatus.playing,
      currentRound: round2,
    );
    notifyListeners();
  }

  void finishResultPhase() {
    if (_round == 1) {
      _currentStep = 17;
    } else {
      _currentStep = 36; // 勝利宣言
    }
    _isResultPhase = false;
    _isAnimationFinished = true;
    notifyListeners();
  }

  void setAnimationFinished(bool value) {
    if (_isAnimationFinished != value) {
      _isAnimationFinished = value;
      notifyListeners();
    }
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
