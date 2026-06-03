import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/paw_background.dart';
import '../services/se_service.dart';
import 'game/game_screen_view_model.dart';
import 'game/game_screen_state.dart';
import 'game/views/waiting_view.dart';
import 'game/views/fishing_phase_view.dart';
import 'game/views/betting_phase_view.dart';
import 'game/views/round_result_view.dart';
import 'game/views/final_result_view.dart';
import 'game/views/fat_cat_event_view.dart';
import '../services/game_service.dart';
import '../widgets/stereoscopic_ui.dart';
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
              MaterialPageRoute(
                builder: (context) =>
                    const HomeScreen(message: 'ホストに退出させられました'),
              ),
            );
          }
        },
        onRoomClosed: () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(message: 'ルームが閉鎖されました'),
              ),
            );
          }
        },
      ),
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatefulWidget {
  const _GameScreenContent();

  @override
  State<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<_GameScreenContent> with WidgetsBindingObserver {
  Type? _lastStateType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    final viewModel = context.read<GameScreenViewModel>();
    viewModel.updateAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();
    final state = viewModel.uiState;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 680;

    // フェーズが変わったら開いているダイアログを閉じる
    if (_lastStateType != null && _lastStateType != state.runtimeType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ダイアログが開いている場合は閉じる
          // Navigator.of(context).pop() を呼び出す前に、
          // modal route がトップにあるか確認するのが理想的だが、
          // ここでは単純に Navigator.popUntil を使って
          // GameScreen 自体は閉じないように制御する。
          Navigator.of(
            context,
          ).popUntil((route) => route.isFirst || route is! PopupRoute);
        }
      });
    }
    _lastStateType = state.runtimeType;

    return PopScope(
      canPop: false, // スワイプや戻るボタンでの退出を禁止
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 戻る操作が試行された際の処理が必要ならここに記述（現在は退出ボタンがあるため何もしない）
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PawBackground(
          child: Stack(
            children: [
              // メインコンテンツ（FatCatEventは全画面表示のためSafeAreaを外す）
              state is FatCatEventState
                  ? _buildBody(context, state, viewModel)
                  : SafeArea(child: _buildBody(context, state, viewModel)),

              // 退出ボタン（待機画面、最終結果画面以外で表示）
              if (state is! FinishedState && state is! WaitingState)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 8.0 : 12.0,
                        bottom: isSmallScreen ? 8.0 : 12.0,
                      ),
                      child: _buildCircleButton(
                        icon: Icons.exit_to_app,
                        isSmallScreen: isSmallScreen,
                        onPressed: () {
                          SeService().play('button_buni.mp3');
                          _showLeaveDialog(context, viewModel);
                        },
                      ),
                    ),
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: StereoscopicContainer(
          baseColor: Colors.white,
          shadowColor: Colors.grey.shade400,
          borderRadius: 32,
          depth: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '退出しますか？',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331F),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '本当に退出してもよろしいですか？\n退出すると負け扱いになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4D331F),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StereoscopicButton(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
                        Navigator.pop(context);
                      },
                      baseColor: Colors.grey.shade300,
                      shadowColor: Colors.grey.shade500,
                      borderRadius: 20,
                      depth: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text(
                          'キャンセル',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    StereoscopicButton(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
                        Navigator.pop(context);
                        vm.leaveRoom();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      baseColor: const Color(0xFFFF5252),
                      shadowColor: const Color(0xFFD32F2F),
                      borderRadius: 20,
                      depth: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Text(
                          '退出',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      RollingState(:final room) => FishingPhaseView(room: room),
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
