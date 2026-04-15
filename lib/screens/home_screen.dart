import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'game_screen.dart';
import 'home/home_screen_state.dart';
import 'home/home_screen_view_model.dart';
import '../repositories/user_repository.dart';
import 'home/views/main_menu_view.dart';
import 'home/views/matchmaking_view.dart';
import 'profile_setup_screen.dart';
import 'tutorial/tutorial_screen.dart';
import 'tutorial/tutorial_view_model.dart';

class HomeScreen extends StatefulWidget {
  final String? message;
  const HomeScreen({super.key, this.message});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeScreenViewModel? _viewModel;
  bool _isNavigationPending = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    return ChangeNotifierProvider(
      create: (providerContext) {
        _viewModel = HomeScreenViewModel(
          gameService: GameService(),
          authService: authService,
          userRepository: userRepository,
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
            if (_isNavigationPending) return;
            _isNavigationPending = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ChangeNotifierProvider.value(
                    value: _viewModel!,
                    child: const ProfileSetupScreen(),
                  ),
                ),
              ).then((_) => _isNavigationPending = false);
            });
          },
          onNavigateToTutorial: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (_) => TutorialViewModel()),
                    ChangeNotifierProvider.value(value: _viewModel!),
                  ],
                  child: const TutorialScreen(),
                ),
              ),
            );
          },
        );

        // メッセージがあればセットする
        if (widget.message != null) {
          _viewModel!.setNotification(widget.message);
        }

        return _viewModel!;
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

    // システムメッセージ（一回限りの通知）の表示
    if (viewModel.notificationMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInfoDialog(context, viewModel, viewModel.notificationMessage!);
      });
    }

    // エラーメッセージの表示
    final errorMessage = viewModel.state.errorMessage;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(context, viewModel, errorMessage);
      });
    }

    // チュートリアルプロンプトの表示
    if (viewModel.shouldShowTutorialPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorialDialog(context, viewModel);
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

  void _showInfoDialog(
    BuildContext context,
    HomeScreenViewModel viewModel,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('通知'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearNotification();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  void _showTutorialDialog(
    BuildContext context,
    HomeScreenViewModel viewModel,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'チュートリアル',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('猫争奪戦へようこそ！\n最初に遊び方のチュートリアルをプレイしますか？'),
          actions: [
            TextButton(
              onPressed: () {
                viewModel.completeTutorial(); // 完了フラグを立ててスキップ
                Navigator.pop(context);
              },
              child: const Text('スキップ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                viewModel.completeTutorial(); // 先にフラグを立てておく（戻ってきた時に出ないよう）
                Navigator.pop(context);
                viewModel.onNavigateToTutorial();
              },
              child: const Text('開始する'),
            ),
          ],
        );
      },
    );
  }
}
