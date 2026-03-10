import 'package:flutter/material.dart';

class PawBackground extends StatelessWidget {
  final Widget child;

  const PawBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景画像 (SafeAreaの外に配置して全画面をカバー)
        Positioned.fill(
          child: Image.asset(
            'assets/images/paw_background.png',
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}
