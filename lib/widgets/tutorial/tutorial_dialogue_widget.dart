import 'package:flutter/material.dart';
import '../stereoscopic_ui.dart';

/// チュートリアル用の案内ダイアログウィジェット
class TutorialDialogueWidget extends StatelessWidget {
  final String message;
  final String characterImagePath;
  final VoidCallback? onNext;
  final bool isLast;
  final bool isEnabled;

  const TutorialDialogueWidget({
    super.key,
    required this.message,
    this.characterImagePath = 'assets/images/tyatoranekopng.png',
    this.onNext,
    this.isLast = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // キャラクター（長老ねこ役）
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  characterImagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              // 吹き出し
              Expanded(
                child: GestureDetector(
                  onTap: isEnabled ? onNext : null,
                  child: StereoscopicContainer(
                    baseColor: Colors.white,
                    shadowColor: const Color(0xFF4D331F),
                    borderRadius: 24,
                    depth: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4D331F),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: isEnabled ? 1.0 : 0.5,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    onNext != null ? (isLast ? '了解！' : 'つぎへ') : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isEnabled ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  if (onNext != null)
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: isEnabled ? Colors.blue : Colors.grey,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
