import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../home_screen_state.dart';
import '../home_screen_view_model.dart';
import '../../../models/user_profile.dart';
import '../../../models/player.dart';
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
    // プロフィールが未取得、またはフレンドコードが未作成（初期設定中）の場合は操作不可にする
    final isProfileNotReady =
        viewModel.userProfile == null ||
        viewModel.userProfile?.friendCode == null;
    final isNotIdle = viewModel.state is! IdleState || isProfileNotReady;

    return Scaffold(
      body: Stack(
        children: [
          // 背景画像 (SafeAreaの外に配置して全画面をカバー)
          Positioned.fill(
            child: Image.asset(
              'assets/images/paw_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // 左上の自分のアイコン
                if (viewModel.userProfile != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildCircleButton(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
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
                      tooltip: 'プロフィール',
                      child: Text(
                        UserIcon.fromId(viewModel.userProfile!.iconId).emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // タイトルをより大きく（flex: 3）表示し、画面に収まるよう調整
                        Flexible(
                          flex: 3,
                          child: Center(
                            child: Image.asset(
                              'assets/images/title.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isNotIdle
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  SeService().play('button_buni.mp3');
                                  viewModel.createRoom();
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          child: (viewModel.state is LoadingState)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ルームを作成',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isNotIdle
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  SeService().play('button_buni.mp3');
                                  viewModel.startRandomMatch();
                                },
                          icon: const Icon(Icons.shuffle),
                          label: const Text(
                            'ランダムマッチ',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _roomCodeController,
                          decoration: const InputDecoration(
                            labelText: 'ルームコード',
                            border: OutlineInputBorder(),
                            hintText: '6桁のコードを入力',
                            isDense: true, // 入力フィールドをコンパクトに
                          ),
                          textCapitalization: TextCapitalization.characters,
                          enabled: !isNotIdle,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: isNotIdle
                              ? null
                              : () => _handleJoinRoom(context, viewModel),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          child: (viewModel.state is LoadingState)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ルームに参加',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右上の丸いボタンメニュー
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 設定ボタン
                      _buildCircleButton(
                        icon: Icons.settings,
                        tooltip: 'プロフィール設定',
                        onPressed: isNotIdle
                            ? null
                            : () {
                                SeService().play('button_buni.mp3');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: viewModel,
                                          child: const ProfileScreen(),
                                        ),
                                  ),
                                );
                              },
                      ),
                      // 通知ボタン
                      _buildCircleButton(
                        icon: Icons.notifications,
                        tooltip: '招待',
                        onPressed: isNotIdle
                            ? null
                            : () {
                                SeService().play('button_buni.mp3');
                                _showInvitationsBox(context, viewModel);
                              },
                        badge: viewModel.invitations.isNotEmpty
                            ? Container(
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
                              )
                            : null,
                      ),
                      // フレンド管理ボタン
                      _buildCircleButton(
                        icon: Icons.people,
                        tooltip: 'フレンド管理',
                        onPressed: isNotIdle
                            ? null
                            : () {
                                SeService().play('button_buni.mp3');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChangeNotifierProvider.value(
                                          value: viewModel,
                                          child: const FriendManagementScreen(),
                                        ),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  /// 丸いアイコンボタンを構築する
  Widget _buildCircleButton({
    IconData? icon,
    Widget? child,
    required VoidCallback? onPressed,
    String? tooltip,
    Widget? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.pink.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: child ?? Icon(icon, color: Colors.pink.shade900),
                onPressed: onPressed,
              ),
              if (badge != null) Positioned(right: 0, top: 0, child: badge),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoinRoom(
    BuildContext context,
    HomeScreenViewModel viewModel,
  ) async {
    FocusScope.of(context).unfocus();
    SeService().play('button_buni.mp3');

    final roomCode = _roomCodeController.text;
    final host = await viewModel.findRoom(roomCode);

    if (host != null && context.mounted) {
      final confirmed = await _showJoinConfirmation(context, host);
      if (confirmed == true && context.mounted) {
        viewModel.joinRoom(roomCode);
      }
    }
  }

  Future<bool?> _showJoinConfirmation(BuildContext context, Player host) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルームに参加しますか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('対戦相手:'),
            const SizedBox(height: 16),
            Text(
              UserIcon.fromId(host.iconId).emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              '${host.displayName} さん',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('参加する'),
          ),
        ],
      ),
    );
  }
}
