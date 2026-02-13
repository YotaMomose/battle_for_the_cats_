import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/domain/win_condition.dart';
import 'package:battle_for_the_cats/models/won_cat.dart';
import 'package:battle_for_the_cats/models/cat_inventory.dart';

void main() {
  group('StandardWinCondition Tests', () {
    late WinCondition winCondition;

    setUp(() {
      winCondition = StandardWinCondition();
    });

    CatInventory createCats(List<String> names) {
      return CatInventory(
        names.map((name) => WonCat(name: name, cost: 1)).toList(),
      );
    }

    test('should NOT win with less than 3 cats', () {
      expect(winCondition.checkWin(CatInventory()), isFalse);
      expect(winCondition.checkWin(createCats(['茶トラねこ'])), isFalse);
      expect(winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ'])), isFalse);
    });

    test('should win with 3 cats of the SAME type', () {
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ', '茶トラねこ'])),
        isTrue,
      );
    });

    test('should win with 3 cats of DIFFERENT types', () {
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '白ねこ', '黒ねこ'])),
        isTrue,
      );
    });

    test('should NOT win with 3 cats but only 2 types (2+1)', () {
      // 茶トラねこx2 + 白ねこx1 = 3 cats, but neither "3 of same" nor "3 types"
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ', '白ねこ'])),
        isFalse,
      );
    });

    test('should win with 4 cats containing 3 of same type', () {
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ', '白ねこ', '茶トラねこ'])),
        isTrue,
      );
    });

    test('should NOT win with 3 cats if one is "アイテム屋"', () {
      // 2 different cats + 1 Item Shop = 3 entries, but only 2 cats
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '白ねこ', 'アイテム屋'])),
        isFalse,
      );

      // 2 same cats + 1 Item Shop = 3 entries
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ', 'アイテム屋'])),
        isFalse,
      );

      // 3 Item Shops = 3 entries, but not cats
      expect(
        winCondition.checkWin(createCats(['アイテム屋', 'アイテム屋', 'アイテム屋'])),
        isFalse,
      );
    });

    test('should win with valid cat names from GameConstants', () {
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '白ねこ', '黒ねこ'])),
        isTrue,
        reason: '3 different types',
      );
      expect(
        winCondition.checkWin(createCats(['茶トラねこ', '茶トラねこ', '茶トラねこ'])),
        isTrue,
        reason: '3 same type',
      );
    });

    test('should win with Boss Cats and Regular Cats mixed', () {
      expect(
        winCondition.checkWin(createCats(['ボス黒ねこ', '黒ねこ', '黒ねこ'])),
        isTrue,
        reason: 'Boss Cat + 2 regular cats of same type',
      );
      expect(
        winCondition.checkWin(createCats(['ボス茶トラねこ', 'ボス茶トラねこ', '茶トラねこ'])),
        isTrue,
        reason: '2 Boss Cats + 1 regular cat of same type',
      );
      expect(
        winCondition.checkWin(createCats(['ボス茶トラねこ', '白ねこ', 'ボス黒ねこ'])),
        isTrue,
        reason: 'Boss Cats mixed in 3 different types',
      );
    });
  });
}
