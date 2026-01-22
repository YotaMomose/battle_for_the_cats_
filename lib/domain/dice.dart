import 'dart:math';
import '../constants/game_constants.dart';

/// サイコロのインターフェース
abstract class Dice {
  /// サイコロを振る
  int roll();
}

/// 1から6の標準的なサイコロ
class StandardDice implements Dice {
  final Random _random;

  StandardDice({Random? random}) : _random = random ?? Random();

  @override
  int roll() {
    return _random.nextInt(GameConstants.diceMax) + GameConstants.diceMin;
  }
}
