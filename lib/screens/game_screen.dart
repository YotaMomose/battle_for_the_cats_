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
        onOpponentLeft: () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
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

    return Scaffold(
      appBar: _buildAppBar(context, viewModel),
      body: _buildBody(context, state, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GameScreenState state,
    GameScreenViewModel vm,
  ) {
    // エラー表示
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      });
    }

    // 相手が退出した場合のポップアップ表示
    // 最終画面(FinishedState)以外の場合のみ表示する
    if (state.isOpponentLeft && state is! FinishedState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOpponentLeftDialog(context, vm);
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
    final state = vm.uiState;
    final isWaiting = state is WaitingState;

    return AppBar(
      automaticallyImplyLeading: false,
      title: isWaiting ? Text('ルーム: ${vm.roomCode}') : null,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        if (isWaiting)
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: vm.roomCode));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('ルームコードをコピーしました')));
            },
            tooltip: 'ルームコードをコピー',
          ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () {
            _showLeaveDialog(context, vm);
          },
          tooltip: '退出する',
        ),
      ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.leaveRoom();
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOpponentLeftDialog(BuildContext context, GameScreenViewModel vm) {
    showDialog(
      context: context,
      barrierDismissible: false, // 閉じられないようにする
      builder: (context) => AlertDialog(
        title: const Text('対戦相手が退出しました'),
        content: const Text('対戦相手が退出したため、ゲームを終了します。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }
}
