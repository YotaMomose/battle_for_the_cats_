import 'dart:math';
import '../models/game_room.dart';
import '../models/cards/round_cards.dart';
import '../constants/game_constants.dart';
import 'battle_evaluator.dart';
import 'win_condition.dart';

/// ラウンドの解決（勝敗判定、報酬付与、ゲーム終了判定）をオーケストレートするドメインサービス
class RoundResolver {
  final BattleEvaluator _evaluator;
  final WinCondition _winCondition;
  final Random _random;

  RoundResolver({
    BattleEvaluator? evaluator,
    WinCondition? winCondition,
    Random? random,
  }) : _evaluator = evaluator ?? BattleEvaluator(),
       _winCondition = winCondition ?? StandardWinCondition(),
       _random = random ?? Random();

  /// ラウンドの結果を判定し、ルームの状態を更新する
  void resolve(GameRoom room) {
    if (room.guest == null) return;
    if (room.currentRound == null) return;

    // 1. 各カードの勝敗を判定 (BattleEvaluator)
    final winnersMap = _evaluator.evaluate(
      room.currentRound!,
      room.host,
      room.guest!,
    );

    // 2. 判定結果をルームに反映 (コスト支払い、カード付与)
    room.applyRoundResults(winnersMap);

    // 3. 最終勝利判定 (WinCondition)
    // 犬の効果などで保留中のアクションがある場合は、判定をスキップする
    final hasPendingEffects =
        room.host.pendingDogChases > 0 || room.guest!.pendingDogChases > 0;

    Winner? finalWinner;
    if (!hasPendingEffects) {
      finalWinner = _winCondition.determineFinalWinner(room.host, room.guest!);
    }

    // 4. ステータスの更新
    room.updatePostRoundState(
      finalWinner,
      hasPendingEffects: hasPendingEffects,
    );
  }

  /// ラウンド結果画面から次へ進む
  void advanceFromRoundResult(GameRoom room) {
    if (!room.bothConfirmedRoundResult) return;
    if (room.status != GameStatus.roundResult) return;

    // 太っちょネコイベント発生
    if (_random.nextDouble() < GameConstants.fatCatEventProbability) {
      room.triggerFatCatEvent();
    } else {
      // 通常通り次へ
      room.prepareNextTurn(RoundCards.random());
    }
  }

  /// 太っちょネコイベント画面から次へ進む
  void advanceFromFatCatEvent(GameRoom room) {
    if (!room.bothConfirmedFatCatEvent) return;
    if (room.status != GameStatus.fatCatEvent) return;

    // 確認後に次のターンへ
    room.prepareNextTurn(RoundCards.random());
  }
}
