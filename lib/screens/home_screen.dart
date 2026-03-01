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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeScreenViewModel? _viewModel;
  bool _isNavigationPending = false;

  @override
  void dispose() {
    // _viewModel は Provider が dispose するのでここでは何もしない
    super.dispose();
  }

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
        );
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
