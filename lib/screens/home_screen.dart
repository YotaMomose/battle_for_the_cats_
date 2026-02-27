import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'game_screen.dart';
import 'home/home_screen_state.dart';
import 'home/home_screen_view_model.dart';
import 'home/views/main_menu_view.dart';
import 'home/views/matchmaking_view.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        late final HomeScreenViewModel viewModel;
        viewModel = HomeScreenViewModel(
          gameService: GameService(),
          onNavigateToGame: (roomCode, playerId, isHost) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  roomCode: roomCode,
                  playerId: playerId,
                  isHost: isHost,
                ),
              ),
            );
          },
          onNavigateToProfileSetup: () {
            // 次のフレームで遷移させる（ビルド中のナビゲーションを避けるため）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true, // 下から競り上がるスタイル
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const ProfileSetupScreen(),
                  ),
                ),
              );
            });
          },
        );
        return viewModel;
      },
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();

    // エラーメッセージの表示
    final errorMessage = viewModel.state.errorMessage;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(context, viewModel, errorMessage);
      });
    }

    // 状態に応じた画面を表示
    return switch (viewModel.state) {
      IdleState() => const MainMenuView(),
      LoadingState() => const MainMenuView(),
      MatchmakingState() => const MatchmakingView(),
      _ => const MainMenuView(),
    };
  }

  void _showErrorDialog(
    BuildContext context,
    HomeScreenViewModel viewModel,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearError();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
