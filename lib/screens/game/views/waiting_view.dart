import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../game_screen_view_model.dart';
import '../../../models/user_profile.dart';
import 'package:flutter/services.dart';

/// 対戦相手待機画面
class WaitingView extends StatelessWidget {
  final String roomCode;

  const WaitingView({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!viewModel.hasGuest) ...[
              const CircularProgressIndicator(),
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
                ElevatedButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    viewModel.startGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('バトル開始！'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    SeService().play('button_buni.mp3');
                    _showRejectConfirmDialog(context, viewModel);
                  },
                  child: const Text(
                    'お断りする',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(),
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
                        Clipboard.setData(ClipboardData(text: roomCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ルームコードをコピーしました')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('コードをコピー'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // フレンド招待ボタン
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
                        _showInviteFriendDialog(context, viewModel);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('フレンドを招待'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // 退出ボタン
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SeService().play('button_buni.mp3');
                      _showLeaveDialog(context, viewModel);
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('ルームを閉じる'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.rejectGuest();
            },
            child: const Text('お断りする', style: TextStyle(color: Colors.red)),
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
                            trailing: ElevatedButton(
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
                              child: const Text('招待'),
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
