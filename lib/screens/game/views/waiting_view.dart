import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_screen_view_model.dart';
import '../../../models/user_profile.dart';

/// 対戦相手待機画面
class WaitingView extends StatelessWidget {
  final String roomCode;

  const WaitingView({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GameScreenViewModel>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 48),

          // フレンド招待ボタン
          ElevatedButton.icon(
            onPressed: () => _showInviteFriendDialog(context, viewModel),
            icon: const Icon(Icons.person_add),
            label: const Text('フレンドを招待'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
                  onPressed: () => Navigator.pop(context),
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
