import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/stereoscopic_ui.dart';
import '../tutorial_view_model.dart';
import '../../../services/se_service.dart';

class TutorialCharactersDialog extends StatefulWidget {
  const TutorialCharactersDialog({super.key});

  @override
  State<TutorialCharactersDialog> createState() =>
      _TutorialCharactersDialogState();
}

class _TutorialCharactersDialogState extends State<TutorialCharactersDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _characters = [
    {
      'name': '漁師',
      'icon': Icons.phishing,
      'image': 'assets/images/ryousi.png',
      'color': Colors.blue,
      'description':
          '仲間にすると、毎ターンの『つり』のたびに、おさかなを1匹追加で獲ってきてくれる頼もしい味方じゃ！たくさん集めればさかなに困ることはなくなるぞ。',
    },
    {
      'name': '犬',
      'icon': Icons.pets,
      'image': 'assets/images/inu.png',
      'color': Colors.brown,
      'description':
          '仲間にすると、相手がすでに獲得しているキャラクターを1匹追い出してしまう恐ろしいヤツじゃ。逆転のチャンスに狙ってみるのじゃ！',
    },
    {
      'name': 'アイテム屋',
      'icon': Icons.storefront,
      'image': 'assets/images/shop.png',
      'color': Colors.purple,
      'description':
          '勝負に勝って仲間に引き入れると、すでに使用したアイテムを1つ復活してくれるぞ。戦いを有利に進めるために、見かけたらぜひ狙いたいところじゃな。',
    },
    {
      'name': 'ふとっちょにゃんこ',
      'icon': Icons.pets,
      'image': 'assets/images/fatcat.png',
      'color': Colors.deepOrange,
      'description':
          'こやつは要注意じゃ！ターンのはじめに突然現れ、お主と相手の持っているおさかなをすべて食べてゼロにしてしまうハプニングメーカーじゃ！さかなを溜め込んでいるときは特に注意じゃ！',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    SeService().play('button_buni.mp3');
    if (_currentPage < _characters.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 完了
      context.read<TutorialViewModel>().completeCharacterIntro();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54, // 背景を半透明の黒に
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: StereoscopicContainer(
        baseColor: const Color(0xFFFDEFD5), // バトル画面のようなクリーム色
        shadowColor: const Color(0xFFD4B886),
        borderRadius: 24,
        depth: 8,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトル
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4D331F), width: 2),
                ),
                child: const Text(
                  'キャラ紹介',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331F),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // カルーセル (PageView)
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _characters.length,
                  itemBuilder: (context, index) {
                    final char = _characters[index];
                    return _buildCharacterPage(char);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ページインジケーター
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _characters.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 12 : 8,
                    height: _currentPage == index ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF4D331F)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 次へ / 閉じるボタン
              StereoscopicButton(
                baseColor: _currentPage == _characters.length - 1
                    ? Colors.green
                    : Colors.blue,
                shadowColor: _currentPage == _characters.length - 1
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
                borderRadius: 20,
                depth: 6,
                onPressed: _nextPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Text(
                    _currentPage == _characters.length - 1 ? '閉じる' : '次へ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterPage(Map<String, dynamic> char) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // アイコン表示領域
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4D331F), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: char.containsKey('image')
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(char['image'], fit: BoxFit.contain),
                  )
                : Icon(char['icon'], size: 60, color: char['color']),
          ),
        ),
        const SizedBox(height: 12),
        // キャラクター名
        Text(
          char['name'],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: char['color'],
          ),
        ),
        const SizedBox(height: 12),
        // 説明文
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            char['description'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4D331F),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
