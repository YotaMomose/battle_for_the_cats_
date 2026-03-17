import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/paw_background.dart';
import '../../../services/se_service.dart';
import '../home_screen_view_model.dart';
import '../../../widgets/stereoscopic_ui.dart';

/// ランダムマッチング中画面
class MatchmakingView extends StatelessWidget {
  const MatchmakingView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();

    return PawBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 6),
                    const SizedBox(height: 32),
                    const Text(
                      'マッチング中...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '対戦相手を探しています',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      height: 56,
                      width: 200,
                      child: StereoscopicButton(
                        onPressed: () {
                          SeService().play('button_buni.mp3');
                          viewModel.cancelMatchmaking();
                        },
                        baseColor: Colors.grey.shade400,
                        shadowColor: Colors.grey.shade700,
                        borderRadius: 28,
                        depth: 6,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.close, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'キャンセル',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 画面下部の猫アニメーション
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/neko3_walk.gif',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
