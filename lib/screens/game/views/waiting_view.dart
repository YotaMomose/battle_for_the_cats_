import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../game_screen_view_model.dart';
import '../../../models/user_profile.dart';
import 'package:flutter/services.dart';
import '../../../widgets/stereoscopic_ui.dart';

/// 対戦相手待機画面
class WaitingView extends StatelessWidget {
  final String roomCode;

  const WaitingView({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!viewModel.hasGuest) ...[
                  Image.asset(
                    'assets/images/neko3_walk.gif',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text('対戦相手を待っています...', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 16),
                  Text(
                    'ルームコード: $roomCode',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('このコードを相手に共有してください'),
                ] else ...[
                  // 参加者がいる場合
                  Text(
                    viewModel.isHost ? '参加希望者がいます！' : '参加しました！',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 相手のプロフィール表示（ホストならゲストを表示、ゲストならホストを表示）
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Column(
                      children: [
                        Text(
                          viewModel.opponentIconEmoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${viewModel.opponentDisplayName} さん',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (viewModel.isHost) ...[
                    const Text('このユーザーと対戦しますか？'),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: StereoscopicButton(
                        onPressed: () {
                          SeService().play('button_buni.mp3');
                          viewModel.startGame();
                        },
                        baseColor: Colors.pink,
                        shadowColor: Colors.pink.shade900,
                        borderRadius: 28,
                        depth: 6,
                        child: const Center(
                          child: Text(
                            'バトル開始！',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: StereoscopicButton(
                        onPressed: () {
                          SeService().play('button_buni.mp3');
                          _showRejectConfirmDialog(context, viewModel);
                        },
                        baseColor: Colors.grey.shade300,
                        shadowColor: Colors.grey.shade600,
                        borderRadius: 24,
                        depth: 4,
                        child: const Center(
                          child: Text(
                            'お断りする',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Image.asset(
                      'assets/images/neko3_walk.gif',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ホストが開始するのを待っています...',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ],

                const SizedBox(height: 48),

                // ボタン群を縦に配置
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!viewModel.hasGuest) ...[
                      // ルームコードコピーボタン
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: StereoscopicButton(
                          onPressed: () {
                            SeService().play('button_buni.mp3');
                            Clipboard.setData(ClipboardData(text: roomCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ルームコードをコピーしました')),
                            );
                          },
                          baseColor: Colors.blue.shade100,
                          shadowColor: Colors.blue.shade800,
                          borderRadius: 24,
                          depth: 4,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.copy, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'コードをコピー',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // フレンド招待ボタン
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: StereoscopicButton(
                          onPressed: () {
                            SeService().play('button_buni.mp3');
                            _showInviteFriendDialog(context, viewModel);
                          },
                          baseColor: Colors.orange,
                          shadowColor: Colors.orange.shade900,
                          borderRadius: 24,
                          depth: 4,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person_add, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'フレンドを招待',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 退出ボタン
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: StereoscopicButton(
                        onPressed: () {
                          SeService().play('button_buni.mp3');
                          _showLeaveDialog(context, viewModel);
                        },
                        baseColor: Colors.grey.shade300,
                        shadowColor: Colors.grey.shade700,
                        borderRadius: 24,
                        depth: 4,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.exit_to_app, color: Colors.black54),
                              SizedBox(width: 8),
                              Text(
                                'ルームを閉じる',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
        // 画面下部の猫アニメーション (対戦相手がまだいない時のみ表示)
        if (!viewModel.hasGuest)
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
    );
  }

  void _showRejectConfirmDialog(BuildContext context, GameScreenViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お断りしますか？'),
        content: const Text('このユーザーはこのルームから退出させられます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          StereoscopicButton(
            onPressed: () {
              SeService().play('button_buni.mp3');
              Navigator.pop(context);
              vm.rejectGuest();
            },
            baseColor: Colors.red.shade400,
            shadowColor: Colors.red.shade900,
            borderRadius: 12,
            depth: 4,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'お断りする',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInviteFriendDialog(
    BuildContext context,
    GameScreenViewModel viewModel,
  ) {
    viewModel.loadFriends();

    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: Consumer<GameScreenViewModel>(
          builder: (context, vm, child) {
            return AlertDialog(
              title: const Text('フレンドを招待'),
              content: SizedBox(
                width: double.maxFinite,
                child: vm.isLoadingFriends
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : vm.friends.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('フレンドがいません', textAlign: TextAlign.center),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: vm.friends.length,
                        itemBuilder: (context, index) {
                          final friend = vm.friends[index];
                          return ListTile(
                            leading: Text(
                              UserIcon.fromId(friend.iconId).emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(friend.displayName),
                            trailing: StereoscopicButton(
                              onPressed: () {
                                SeService().play('button_buni.mp3');
                                vm.inviteFriend(friend);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${friend.displayName} さんに招待を送りました',
                                    ),
                                  ),
                                );
                              },
                              baseColor: Colors.pink.shade300,
                              shadowColor: Colors.pink.shade800,
                              borderRadius: 12,
                              depth: 4,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '招待',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    Navigator.pop(context);
                  },
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
