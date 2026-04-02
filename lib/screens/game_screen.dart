import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/paw_background.dart';
import '../services/se_service.dart';
import 'game/game_screen_view_model.dart';
import 'game/game_screen_state.dart';
import 'game/views/waiting_view.dart';
import 'game/views/rolling_phase_view.dart';
import 'game/views/betting_phase_view.dart';
import 'game/views/round_result_view.dart';
import 'game/views/final_result_view.dart';
import 'game/views/fat_cat_event_view.dart';
import '../services/game_service.dart';
import 'home_screen.dart';

/// ゲーム画面（MVVM）
class GameScreen extends StatelessWidget {
  final String roomCode;
  final String playerId;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomCode,
    required this.playerId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameScreenViewModel(
        gameService: GameService(),
        roomCode: roomCode,
        playerId: playerId,
        isHost: isHost,
        onOpponentLeft: () {
          // 何もしない（ViewModel側でFinishedStateに遷移させるように変更）
        },
        onKicked: () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen(message: 'ホストに退出させられました')),
            );
          }
        },
        onRoomClosed: () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen(message: 'ルームが閉鎖されました')),
            );
          }
        },
      ),
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatelessWidget {
  const _GameScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final state = viewModel.uiState;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PawBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildBody(context, state, viewModel),
              // 退出ボタン（待機画面、最終結果画面以外で表示）
              if (state is! FinishedState && state is! WaitingState)
                Positioned(
                  bottom: isSmallScreen ? 8 : 12,
                  left: isSmallScreen ? 8 : 12,
                  child: _buildCircleButton(
                    icon: Icons.exit_to_app,
                    isSmallScreen: isSmallScreen,
                    onPressed: () {
                      SeService().play('button_buni.mp3');
                      _showLeaveDialog(context, viewModel);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isSmallScreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        iconSize: isSmallScreen ? 20 : 24,
        padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: Colors.grey.shade700),
        onPressed: onPressed,
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, GameScreenViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出しますか？'),
        content: const Text('退出するとゲームが中断されます。'),
        actions: [
          TextButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              Navigator.pop(context);
              vm.leaveRoom();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GameScreenState state,
    GameScreenViewModel vm,
  ) {
    // ホストにキックされた、またはルームが閉鎖された場合はボディを表示しない（即座にポップされるため）
    if (state.isKicked || state.isRoomClosed) {
      return const SizedBox.shrink();
    }

    // エラー表示
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      });
    }

    // 状態別View
    return switch (state) {
      LoadingState() => const Center(child: CircularProgressIndicator()),
      WaitingState() => WaitingView(roomCode: vm.roomCode),
      RollingState(:final room) => RollingPhaseView(room: room),
      PlayingState(:final room) => BettingPhaseView(room: room),
      RoundResultState(:final room) => RoundResultView(room: room),
      FinishedState(:final room) => FinalResultView(room: room),
      FatCatEventState(:final room) => FatCatEventView(
        room: room,
        onConfirm: vm.confirmFatCatEvent,
      ),
    };
  }
}
