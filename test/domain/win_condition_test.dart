import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/win_condition.dart';

void main() {
  group('StandardWinCondition Tests', () {
    late WinCondition winCondition;

    setUp(() {
      winCondition = StandardWinCondition();
    });

    test('should NOT win with less than 3 cats', () {
      expect(winCondition.checkWin([]), isFalse);
      expect(winCondition.checkWin(['Mike']), isFalse);
      expect(winCondition.checkWin(['Mike', 'Mike']), isFalse);
    });

    test('should win with 3 cats of the SAME type', () {
      expect(winCondition.checkWin(['Mike', 'Mike', 'Mike']), isTrue);
    });

    test('should win with 3 cats of DIFFERENT types', () {
      expect(winCondition.checkWin(['Mike', 'Tama', 'Kuro']), isTrue);
    });

    test('should NOT win with 3 cats but only 2 types (2+1)', () {
      // Mikex2 + Tamax1 = 3 cats, but neither "3 of same" nor "3 types"
      expect(winCondition.checkWin(['Mike', 'Mike', 'Tama']), isFalse);
    });

    test('should win with 4 cats containing 3 of same type', () {
      expect(winCondition.checkWin(['Mike', 'Mike', 'Tama', 'Mike']), isTrue);
    });
  });
}
