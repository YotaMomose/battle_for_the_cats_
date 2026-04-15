import 'package:flutter/material.dart';
import '../../constants/game_constants.dart';
import '../../models/game_room.dart';
import '../../models/player.dart';
import '../../models/bets.dart';
import '../../models/cards/round_cards.dart';
import '../../models/cards/regular_cat.dart';
import '../../models/item.dart';
import '../../models/cat_inventory.dart';
import '../../models/item_inventory.dart';
import '../game/player_data.dart';

class TutorialViewModel extends ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // チュートリアル用の固定データ
  late GameRoom _room;
  Bets _bets = Bets.empty();
  bool _hasPlacedBet = false;

  TutorialViewModel() {
    _initTutorialRoom();
  }

  void _initTutorialRoom() {
    final host = Player(
      id: 'player_id',
      displayName: 'あなた',
      iconId: 'cat_orange',
      fishCount: 10,
    );
    final guest = Player(
      id: 'elder_cat',
      displayName: '長老ねこ',
      iconId: 'cat_black',
      fishCount: 10,
    );

    _room = GameRoom(
      roomId: 'TUTORIAL',
      host: host,
      guest: guest,
      status: GameStatus.playing,
      currentTurn: 1,
      currentRound: const RoundCards(
        card1: RegularCat(id: 't_cat_1', displayName: 'しろねこ', baseCost: 3),
        card2: RegularCat(id: 't_cat_2', displayName: 'くろねこ', baseCost: 2),
        card3: RegularCat(id: 't_cat_3', displayName: '茶トラねこ', baseCost: 1),
      ),
    );
  }

  // --- チュートリアル用の状態 ---
  int? _randomFishResult;
  bool _isFished = false;

  // --- Getters ---
  int get totalBet => _bets.total;
  Map<String, int> get bets => _bets.toMap();
  bool get hasPlacedBet => _hasPlacedBet;
  bool get isMyReady => _hasPlacedBet;
  bool get isMyRolled => _isFished;
  int get currentTurn => 1;
  int? get currentDiceRoll => _randomFishResult;
  String get confirmBetsButtonLabel => _hasPlacedBet ? '確定済み' : '確定する';

  String get myDisplayName => 'あなた';
  String get myIconEmoji => '🐱';
  String get myIconId => 'cat_orange';
  String get opponentDisplayName => '長老ねこ';
  String get opponentIconEmoji => '👴';
  String get opponentIconId => 'cat_black';

  String get opponentReadyStatusLabel => '選択中...';
  Color get opponentReadyStatusColor => const Color.fromARGB(255, 255, 38, 0);

  PlayerData get playerData {
    // 判定フェーズ（ステップ9〜12）以降は、魚を消費し、猫を獲得した状態にする
    final bool isAfterResult = _currentStep >= 9;
    final int fishAfterBet = 10 - 3; // しろねこに3匹
    final myCurrentFish = _isFished
        ? (fishAfterBet + (_randomFishResult ?? 0))
        : (isAfterResult ? fishAfterBet : 10);

    final myInventory = CatInventory();
    if (isAfterResult) {
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
      myDiceRoll: _randomFishResult,
      opponentDiceRoll: null,
      myRolled: _isFished,
      opponentRolled: false,
      myReady: _hasPlacedBet,
      opponentReady: false,
      myBets: isAfterResult ? Bets.empty() : _bets, // 判定後は盤面から消える
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

  /// 猫の画像パスを取得 (UI用)
  String? getCatImagePath(String catName) {
    if (catName.contains('しろ')) return 'assets/images/sironeko.png';
    if (catName.contains('くろ')) return 'assets/images/kuroneko.png';
    if (catName.contains('茶トラ')) return 'assets/images/tyatoranekopng.png';
    return null;
  }

  /// 猫のアイコン種類を取得 (UI用)
  IconData getCatIconData(String catName) => Icons.pets;

  /// 猫のアイコン色を取得 (UI用)
  Color getCatIconColor(String catName) {
    if (catName.contains('しろ')) return Colors.grey[300]!;
    if (catName.contains('くろ')) return Colors.grey[800]!;
    if (catName.contains('茶トラ')) return Colors.orange;
    return Colors.grey;
  }

  // --- チュートリアルのメッセージ ---
  String get currentMessage {
    switch (_currentStep) {
      case 0:
        return 'ほっほっほ。ようこそ、猫争奪戦へ！ワシがルールを教えてやろう。';
      case 1:
        return 'このゲームは、お魚をあげて猫たちの信頼を勝ち取るゲームじゃ。';
      case 2:
        return '真ん中に3匹の猫がおるじゃろう？それぞれ「コスト」が決まっておる。';
      case 3:
        return 'まずは左の「しろ」にお魚を3つ置いてみるのじゃ。下の魚をドラッグして、お皿まで持っていっておくれ。';
      case 4:
        return 'おお！上手じゃ！これで「しろ」を獲得する準備ができたぞ。';
      case 5:
        return '次は「ねこじゃらし」を使ってみるかの。これは特別なアイテムじゃ。';
      case 6:
        return 'ねこじゃらしを置いた猫は、もし相手がお魚を置いていなければ、お魚を使わずに仲間にできるのじゃ。';
      case 7:
        return '真ん中の「くろ」に、下の「ねこじゃらし」をドラッグして置いてみるのじゃ。';
      case 8:
        return 'よしよし！これでバッチリじゃ！あとは画面右下のボタンで「確定」するのじゃ。';
      case 9:
        return 'おっと、結果発表じゃ！見てみるのじゃ。お主が「しろ」と「くろ」を仲間にしたぞ！';
      case 10:
        return '「しろ」にお魚を3匹置いて、相手（ワシ）は0匹。お主の勝ちじゃ！これがお魚による勝利じゃな。';
      case 11:
        return 'そして「くろ」には「ねこじゃらし」を使ったな。相手が置いておらんから、0匹で仲間にできたのじゃ。お得じゃろう？';
      case 12:
        return 'しかし、手持ちのお魚を見てみるのじゃ。さっきの3匹を使ったので、残りが少なくなっておるな。';
      case 13:
        return 'お魚がなくなったらどうするか？そう、「つり」をするのじゃ。';
      case 14:
        return 'つりで釣り上げた魚の数だけお魚が補充されるぞ。右下の「つりをはじめる」を押してみるのじゃ。';
      case 15:
        return '完璧じゃ！これでお主も立派なプレイヤーじゃ。さあ、本番へ行くがよい！';
      default:
        return '';
    }
  }

  bool get canProgress {
    // 操作が必要なステップ以外は「次へ」で進める
    if (_currentStep == 3) return false; // 魚配置待ち
    if (_currentStep == 7) return false; // アイテム配置待ち
    if (_currentStep == 8) return false; // 確定待ち
    if (_currentStep == 14) return false; // つり待ち

    return _currentStep < 15;
  }

  void nextStep() {
    if (canProgress) {
      _currentStep++;
      notifyListeners();
    }
  }

  // --- アクション ---
  void updateBet(String catIndex, int amount) {
    if (_currentStep != 3) return;

    // チュートリアルでは「しろ（index 0）」に「3個」置くことを許可
    if (catIndex == '0' && amount <= 3) {
      final newMap = Map<String, int>.from(_bets.toMap());
      newMap[catIndex] = amount;
      _bets = Bets(
        newMap,
        _bets.itemsToMap().map(
          (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
        ),
      );

      if (amount == 3) {
        _currentStep = 4; // 3つ置いたら次のステップ（成功メッセージ）へ
      }
      notifyListeners();
    }
  }

  void placeBets() {
    if (_currentStep == 8) {
      _hasPlacedBet = true;
      _currentStep = 9; // 次のステップ（判定結果）へ
      notifyListeners();
    }
  }

  void updateItemPlacement(String catIndex, ItemType? item) {
    if (_currentStep != 7) return; // ステップ7以外は置かせない

    // チュートリアルでは「くろ（index 1）」に「ねこじゃらし」だけを許可
    if (catIndex == '1' && item == ItemType.catTeaser) {
      final newItemsMap = Map<String, ItemType?>.from(
        _bets.itemsToMap().map(
          (k, v) => MapEntry(k, v != null ? ItemType.fromString(v) : null),
        ),
      );
      newItemsMap[catIndex] = item;

      _bets = Bets(_bets.toMap(), newItemsMap);

      _currentStep = 8; // 次のステップ（確定指示）へ
      notifyListeners();
    }
  }

  void catchFish() {
    if (_currentStep == 14) {
      _randomFishResult = 4; // 固定の結果
      _isFished = true;
      _currentStep = 15; // 完了メッセージへ
      notifyListeners();
    }
  }

  Future<void> completeTutorial() async {
    // 完了フラグ更新ロジックは呼び出し側（TutorialScreen）で処理させるか、ここで行う
    // 今回はScreen側で行う前提とする
  }
}
