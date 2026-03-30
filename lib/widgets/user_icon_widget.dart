import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// ユーザーアイコンを表示する基本ウィジェット
class UserIconWidget extends StatelessWidget {
  final UserIcon icon;
  final double size;
  final bool isLocked;

  const UserIconWidget({
    super.key,
    required this.icon,
    this.size = 40,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (icon.imagePath != null) {
      iconWidget = Image.asset(
        icon.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              icon.emoji,
              style: TextStyle(fontSize: size * 0.8),
            ),
          );
        },
      );
    } else {
      iconWidget = Center(
        child: Text(
          icon.emoji,
          style: TextStyle(fontSize: size * 0.8),
        ),
      );
    }

    if (isLocked) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.3, child: iconWidget),
          Icon(Icons.lock, size: size * 0.4, color: Colors.grey),
        ],
      );
    }

    return iconWidget;
  }
}

/// ProfileSetupScreen等で使用される、二重リング状のプレビュー表示
class UserIconPreview extends StatelessWidget {
  final UserIcon icon;
  final double size;
  final Color ringColor;

  const UserIconPreview({
    super.key,
    required this.icon,
    this.size = 80,
    this.ringColor = const Color(0xFFFFCE35),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 3),
      ),
      padding: EdgeInsets.all(size * 0.03),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 1.5),
        ),
        padding: EdgeInsets.all(size * 0.08),
        alignment: Alignment.center,
        child: UserIconWidget(icon: icon, size: size * 0.6),
      ),
    );
  }
}
