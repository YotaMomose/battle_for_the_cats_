import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game/game_screen_view_model.dart';
import 'game/game_screen_state.dart';
import 'game/views/waiting_view.dart';
import 'game/views/rolling_phase_view.dart';
import 'game/views/betting_phase_view.dart';
import 'game/views/round_result_view.dart';
import 'game/views/final_result_view.dart';
import '../services/game_service.dart';

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

    return Scaffold(
      appBar: _buildAppBar(context, viewModel),
      body: _buildBody(context, state, viewModel),
    );
  }

  Widget _buildBody(
      BuildContext context, GameScreenState state, GameScreenViewModel vm) {
    // エラー表示
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
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
      _ => const Center(child: Text('不明な状態')),
    };
  }

  AppBar _buildAppBar(BuildContext context, GameScreenViewModel vm) {
    return AppBar(
      title: Text('ルーム: ${vm.roomCode}'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: vm.roomCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ルームコードをコピーしました')),
            );
          },
          tooltip: 'ルームコードをコピー',
        ),
      ],
    );
  }
}
