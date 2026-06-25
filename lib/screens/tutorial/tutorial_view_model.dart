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
import '../../models/user_profile.dart';
import '../../constants/game_constants.dart';

class TutorialViewModel extends ChangeNotifier {
  late GameRoom _room;
  late Player _me;
  late Player _elder;
  int _currentStep = 0;
  int _currentBet = 0;
  Bets _bets = Bets.empty();
  bool _hasPlacedBet = false;

  TutorialViewModel({UserProfile? userProfile}) {
    // チュートリアル用の初期設定
    final player = Player(
        id: 'me',
        displayName: userProfile?.displayName ?? 'あなた',
        iconId: userProfile?.iconId ?? 'cat_orange');
    final elder = Player(
        id: 'elder',
        displayName: 'あいて',
        iconId: 'cat_black');

    final round = RoundCards(
      card1: const RegularCat(id: 'white', displayName: 'しろねこ', baseCost: 3),
      card2: const RegularCat(id: 'black', displayName: 'くろねこ', baseCost: 2),
      card3: const RegularCat(id: 'tabby', displayName: 'とらねこ', baseCost: 1),
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
  bool get isFishingPhase => _currentStep >= 18 && _currentStep <= 21;
  bool _isFishingEffect = false;
  bool get isFishingEffect => _isFishingEffect;
  String get fishButtonLabel {
    if (_isFishingEffect) return 'つり中...';
    return '釣りをする';
  }
  int get round => _round;
  int get currentTurn => _round;
  int? get currentDiceRoll => _randomDiceResult;
  String get confirmBetsButtonLabel => _hasPlacedBet ? '確定済み' : '確定する';

  String get myDisplayName => _me.displayName;
  String get myIconId => _me.iconId;
  String get myIconEmoji => UserIcon.fromId(_me.iconId).emoji;
  UserIcon get myUserIcon => UserIcon.fromId(_me.iconId);

  /// 相手のアイコン
  UserIcon get opponentUserIcon => UserIcon.fromId(opponentIconId);

String get opponentIconEmoji => opponentUserIcon.emoji;

  String get opponentDisplayName => 'あいて';
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
          myItem: ItemType.captureNet,
          winStatus: 'win',
        ),
        TutorialRoundResultItem(
          catName: 'とらねこ',
          myBet: 1,
          opponentBet: 0,
          opponentItem: ItemType.potion,
          winStatus: 'lose', // コスト不足で失敗
        ),
      ];
    } else {
      // 第2ターン:
      // 0: しろ(びっくりホーンで引き分け)
      // 1: しろ(自分3、相手4で負け)
      // 2: とら(自分2、相手1で勝ち)
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
          catName: 'とらねこ',
          myBet: 2,
          opponentBet: 1,
          winStatus: 'win',
        ),
      ];
    }
  }

  PlayerData get playerData {
    final bool isAcquisitionComplete = _currentStep >= 18;
    final int myCurrentFish;
    if (_round == 1) {
      if (_currentStep < 18) {
        myCurrentFish = 10 - _bets.total;
      } else {
        final int fishAfterBet = 10 - 4; // 3 + 0 + 1 = 4匹消費
        myCurrentFish = _isDiceRolled
            ? (fishAfterBet + (_randomDiceResult ?? 0))
            : fishAfterBet;
      }
    } else {
      // 2ターン目
      myCurrentFish = 10 - _bets.total;
    }

    final myInventory = CatInventory();
    final oppInventory = CatInventory();

    final myItemInventory = ItemInventory({
      ItemType.captureNet: _round == 1 ? 1 : 0,
      ItemType.surpriseHorn: 1,
      ItemType.potion: 1,
    });

    if (_round >= 2 || isAcquisitionComplete) {
      myInventory.addCat('しろねこ', 3);
      myInventory.addCat('くろねこ', 2);
    }

    if (_isFinalResultPhase) {
      myInventory.addCat('とらねこ', 1);
      oppInventory.addCat('しろねこ', 3);
    }

    return PlayerData(
      room: _room,
      isHost: true,
      myDisplayName: 'あなた',
      myIconId: _me.iconId,
      opponentDisplayName: 'あいて',
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
                ? (_currentStep >= 12 && _currentStep < 18
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
    if (catName.contains('とら')) return 'assets/images/tyatoranekopng.png';
    if (catName.contains('ふとっちょ')) return 'assets/images/fatcat.png';
    return null;
  }

  IconData getCatIconData(String catName) => Icons.pets;
  Color getCatIconColor(String catName) {
    if (catName.contains('しろ')) return Colors.grey[300]!;
    if (catName.contains('くろ')) return Colors.grey[800]!;
    if (catName.contains('とら')) return Colors.orange;
    return Colors.grey;
  }

  // --- チュートリアル用のメッセージ ---
  String get currentMessage {
    switch (_currentStep) {
      case 0:
        return 'ほっほっほ。ワシがゲームのルールを教えてやろう。';
      case 1:
        return 'このゲームは、相手より多くのおさかなをあげてにゃんこをゲットすることが目的じゃ。';
      case 2:
        return '先に3匹の同じ種類のにゃんこを集めるか、3匹の違う種類のにゃんこを集めれば勝利じゃ。';
      case 3:
        return '画面中央に3匹のにゃんこがおるじゃろう？この3匹から欲しいにゃんこをゲットするのじゃ。';
      case 4:
        return 'にゃんこを仲間にするには、必要なおさかなの数が決まっておる。にゃんこの下にあるおさかなの数以上のおさかなを置かないと仲間にできんのじゃ。';
      case 5:
        return 'まずは左の「しろねこ」におさかなを3匹置いておくれ。下のおさかなをドラッグしてしろねこのお皿まで移動させるのじゃ。';
      case 6:
        return 'よしよし、上手じゃ！次は真ん中の「くろねこ」じゃな。';
      case 7:
        return 'ここではアイテムを使ってみよう。「捕獲ネット」を「くろねこ」のアイテムスペースにドラッグするのじゃ。';
      case 8:
        return '「捕獲ネット」は相手がおさかなを置いていなければ、おさかなを使わずに仲間にできる優れものじゃ。';
      case 9:
        return 'アイテムは使うとなくなるからタイミングが大事じゃ。\n最後に右の「とらねこ」じゃな。';
      case 10:
        return '「とらねこ」はおさかな1匹分必要じゃから、おさかなを1匹だけ置いてみるのじゃ。';
      case 11:
        return 'よし、これですべての準備が整った！\nそれじゃあ「確定する」ボタンを押してみるのじゃ。\n今回使わなかったおさかなは次のターンに持ち越されるぞ。';
      case 12:
        return '判定が始まるぞ！わくわくするのう。';
      case 13:
        return 'まずは「しろねこ」じゃな。相手は0匹。お主の勝ちじゃ！';
      case 14:
        return '次は「くろねこ」じゃな。相手がおさかなを置いてないから、「捕獲ネット」のおかげでおさかな0匹で仲間にできたぞ。';
      case 15:
        return '最後は「とらねこ」じゃが...おっと！相手が「食欲増進ポーション」を置いたようじゃ。';
      case 16:
        return '「食欲増進ポーション」はにゃんこゲットに必要なおさかなの数が2倍になるじゃ！1匹しか置いておらんから、おさかな不足で仲間にできなかったようじゃ。';
      case 17:
        return '1ターン目の結果じゃ。\nしろねことくろねこをゲットしたからとらねこをゲットできれば勝てるぞ！';
      case 18:
        return 'しかし、おさかなが少なくなってきたのう。';
      case 19:
        return '毎回ターン、はじめにつりができるのじゃ。釣れた数だけおさかなが補充されるぞ。';
      case 20:
        return '「釣りをする」を押して、おさかなをゲットするのじゃ！';
      case 21:
        return 'ほっほっほ、これでまた戦えるな！さあ、このまま第2ターンへ進むぞ。';
      case 22:
        return '2ターン目じゃ！\n出てくるキャラクターは毎回ランダムに変わるぞ。';
      case 23:
        return '今回はアイテム「びっくりホーン」を使ってみるのじゃ！';
      case 24:
        return 'このアイテムを置くとどれだけおさかなを置いてもお互いにキャラクターをゲットする事はできないのじゃ。';
      case 25:
        return 'まずは一番左の「しろねこ」に「びっくりホーン」を置いてみるのじゃ。';
      case 26:
        return 'よし！これであいてとお主、どちらがおさかなを置いてもこのしろねこはゲットできないぞ。';
      case 27:
        return '次に、真ん中の「しろねこ」におさかなを3匹置いてみるのじゃ。';
      case 28:
        return 'ふむ、おさかなを置いても安心はできんぞ。相手の方が多くのおさかなを置いた場合は、そちらに取られてしまうのじゃ。';
      case 29:
        return '最後に、右の「とら」を取るために、おさかなを2匹置いておくのじゃ！';
      case 30:
        return 'ほっほっほ、完璧な布陣じゃな。それでは「確定する」ボタンを押してみるのじゃ。';
      case 31:
        return 'さあ、2ターン目の判定、いってみようかの！';
      case 32:
        return 'まずは一番左の「しろ」からじゃな。';
      case 33:
        return 'びっくりホーンの効果で誰も仲間にできんかったのう。あいてのおさかなを無駄に使わせることができたぞ！';
      case 34:
        return '次は真ん中の「しろ」じゃ。お主は3匹置いたが、相手はどうかのう？';
      case 35:
        return 'おっと！相手は4匹も置いておる。';
      case 36:
        return '残念！お主より多いおさかなを置かれてしまった。必要なおさかなの数を満たしていても相手より少ないと取られてしまうのじゃ。';
      case 37:
        return '最後は右の「とら」！お主は必要な数より多い2匹置いておるが、相手は？';
      case 38:
        return '相手は1匹しか置かなかったようじゃな。お主の勝ちじゃ！';
      case 39:
        return 'これで「しろ」「くろ」「とら」の3種類が揃ったな！';
      case 40:
        return 'お見事！お主の完全勝利じゃ！';
      case 41:
        return '今回は登場しなかったが、実際のゲームでは他にも様々なキャラクターが登場するぞ。紹介しておこう。';
      case 42:
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

    if (_currentStep == 5) return _bets.getBet('0') >= 3;
    if (_currentStep == 7) return _bets.getItem('1') != null;
    if (_currentStep == 10)
      return _bets.getBet('2') >= 1 || _bets.getItem('2') != null;
    if (_currentStep == 11) return _hasPlacedBet;

    // 第2ターン
    if (_currentStep == 25) return _bets.getItem('0') == ItemType.surpriseHorn;
    if (_currentStep == 27) return _bets.getBet('1') >= 3;
    if (_currentStep == 29) return _bets.getBet('2') >= 2;
    if (_currentStep == 30) return _hasPlacedBet;

    if (_currentStep == 20) return _isDiceRolled;
    return true;
  }

  // --- アクション ---
  void updateBet(String catIndex, int delta) {
    if (delta <= 0) return; // チュートリアルでは魚を戻すことはできない
    if ((_currentStep == 5 && catIndex == '0') ||
        (_currentStep == 10 && catIndex == '2') ||
        (_currentStep == 27 && catIndex == '1') ||
        (_currentStep == 29 && catIndex == '2')) {
      final currentAmount = _bets.getBet(catIndex);
      final newAmount = (currentAmount + delta).clamp(0, 50);

      _bets = Bets(
        Map.from(_bets.toMap())..[catIndex] = newAmount,
        _bets.itemsToMap().map(
          (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
        ),
      );

      if (_currentStep == 5 && newAmount >= 3) {
        _currentStep = 6;
      } else if (_currentStep == 10 && newAmount >= 1) {
        _currentStep = 11;
      } else if (_currentStep == 27 && catIndex == '1' && newAmount >= 3) {
        _currentStep = 28;
      } else if (_currentStep == 29 && catIndex == '2' && newAmount >= 2) {
        _currentStep = 30;
      }
      notifyListeners();
    }
  }

  void placeBets() {
    if (_currentStep == 11 || _currentStep == 30) {
      _hasPlacedBet = true;
      if (_currentStep == 11) {
        _isResultPhase = true;
        _currentStep = 12;
        _isAnimationFinished = false;
      } else {
        _currentStep = 31; // セリフ「ワシも準備完了じゃ」へ
      }
      notifyListeners();
    }
  }

  void updateItemPlacement(String catIndex, ItemType? item) {
    // チュートリアルではアイテムの削除は許可しない
    if (item == null) return;
    
    if ((_currentStep == 7 && catIndex == '1' && item == ItemType.captureNet) ||
        (_currentStep == 25 &&
            catIndex == '0' &&
            item == ItemType.surpriseHorn)) {
      final newItemsMap = _bets.itemsToMap().map(
        (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
      );
      newItemsMap[catIndex] = item;

      _bets = Bets(_bets.toMap(), newItemsMap);

      if (_currentStep == 7) {
        _currentStep = 8;
      } else if (_currentStep == 10) {
        _currentStep = 11;
      } else if (_currentStep == 25) {
        _currentStep = 26;
      }
      notifyListeners();
    }
  }

  void catchFish() {
    if (_currentStep == 20) {
      _isFishingEffect = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1500), () {
        _isFishingEffect = false;
        _randomDiceResult = 4;
        _isDiceRolled = true;
        _currentStep = 21;
        notifyListeners();
      });
    }
  }

  void nextStep() {
    if (canProgress) {
      if (_currentStep == 21) {
        startRound2();
        return;
      }
      if (_currentStep == 17) {
        _isResultPhase = false;
        _currentStep = 18;
        notifyListeners();
        return;
      }
      if (_currentStep == 31) {
        _isResultPhase = true;
        _currentStep = 32;
        _isAnimationFinished = false;
        notifyListeners();
        return;
      }
      if (_currentStep == 38) {
        _isResultPhase = false;
        _isFinalResultPhase = true;
        _currentStep = 39;
        notifyListeners();
        return;
      }
      if (_currentStep == 41) {
        _showCharacterIntro = true;
        notifyListeners();
        return;
      }
      if (_currentStep == 42) {
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
    _currentStep = 42;
    notifyListeners();
  }

  void startRound2() {
    _currentStep = 22;
    _round = 2;
    _hasPlacedBet = false;
    _isDiceRolled = false;
    _isResultPhase = false;
    _bets = Bets.empty();

    // 第2ターンのカードセット
    final round2 = RoundCards(
      card1: const RegularCat(id: 'white1', displayName: 'しろねこ', baseCost: 3),
      card2: const RegularCat(id: 'white2', displayName: 'しろねこ', baseCost: 3),
      card3: const RegularCat(id: 'tabby2', displayName: 'とらねこ', baseCost: 1),
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
      _currentStep = 18;
    } else {
      _currentStep = 37; // 勝利宣言
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
