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
      iconWidget = Transform.scale(
        scale: 1.25,
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          icon.imagePath!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                icon.emoji,
                style: TextStyle(fontSize: size * 0.8),
              ),
            );
          },
        ),
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
      padding: EdgeInsets.only(top: size * 0.03, left: size * 0.03, right: size * 0.03),
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.only(top: size * 0.08, left: size * 0.08, right: size * 0.08),
        foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.bottomCenter,
        child: UserIconWidget(icon: icon, size: size * 0.6),
      ),
    );
  }
}
