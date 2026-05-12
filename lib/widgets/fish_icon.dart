import 'package:flutter/material.dart';

/// 共通のさかなアイコンウィジェット
class FishIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const FishIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/fish.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
    );
  }
}
