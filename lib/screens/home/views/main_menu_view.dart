import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home_screen_state.dart';
import '../home_screen_view_model.dart';
import '../../../models/user_profile.dart';
import '../../profile_screen.dart';
import '../../friend_management/friend_management_screen.dart';

/// メインメニュー画面
class MainMenuView extends StatefulWidget {
  const MainMenuView({super.key});

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();
    final isNotIdle = viewModel.state is! IdleState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ねこ争奪戦！'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 招待通知アイコン
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: '招待',
                onPressed: () => _showInvitationsBox(context, viewModel),
              ),
              if (viewModel.invitations.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${viewModel.invitations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'フレンド管理',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const FriendManagementScreen(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'プロフィール設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const ProfileScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // プロフィール表示
              if (viewModel.userProfile != null)
                Center(
                  child: Column(
                    children: [
                      Text(
                        UserIcon.fromId(viewModel.userProfile!.iconId).emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.userProfile!.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isNotIdle ? null : () => viewModel.createRoom(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: (viewModel.state is LoadingState)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ルームを作成', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isNotIdle
                    ? null
                    : () => viewModel.startRandomMatch(),
                icon: const Icon(Icons.shuffle),
                label: const Text('ランダムマッチ', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _roomCodeController,
                decoration: const InputDecoration(
                  labelText: 'ルームコード',
                  border: OutlineInputBorder(),
                  hintText: '6桁のコードを入力',
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !isNotIdle,
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isNotIdle
                    ? null
                    : () => viewModel.joinRoom(_roomCodeController.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ルームに参加', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvitationsBox(
    BuildContext context,
    HomeScreenViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final invitations = viewModel.invitations;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '届いている招待',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  if (invitations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('招待はありません'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: invitations.length,
                        itemBuilder: (context, index) {
                          final invitation = invitations[index];
                          return ListTile(
                            leading: Text(
                              UserIcon.fromId(invitation.senderIconId).emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            title: Text('${invitation.senderName} さん'),
                            subtitle: const Text('対戦に招待されています'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    viewModel.rejectInvitation(invitation);
                                    if (viewModel.invitations.isEmpty) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text(
                                    '拒否',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    viewModel.acceptInvitation(invitation);
                                  },
                                  child: const Text('参加'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
