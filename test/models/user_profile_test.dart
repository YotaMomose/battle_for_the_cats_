import 'package:battle_for_the_cats/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserIcon presets', () {
    test('non-premium icons are limited to six person images', () {
      final availableIcons = UserIcon.presets.where((icon) => !icon.isPremium).toList();

      expect(availableIcons, hasLength(6));
      expect(
        availableIcons.map((icon) => icon.imagePath).toList(),
        const [
          'assets/images/person1.png',
          'assets/images/person2.png',
          'assets/images/person3.png',
          'assets/images/person4.png',
          'assets/images/person5.png',
          'assets/images/person6.png',
        ],
      );
    });

    test('legacy cat_black id resolves to kuro neko image', () {
      final icon = UserIcon.fromId('cat_black');

      expect(icon.imagePath, 'assets/images/kuroneko.png');
      expect(icon.label, 'くろねこ');
    });
  });
}
