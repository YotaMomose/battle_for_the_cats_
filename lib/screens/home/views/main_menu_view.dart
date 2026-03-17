import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/se_service.dart';
import '../home_screen_state.dart';
import '../home_screen_view_model.dart';
import '../../../models/user_profile.dart';
import '../../../models/player.dart';
import '../../../widgets/paw_background.dart';
import '../../profile_screen.dart';
import '../../friend_management/friend_management_screen.dart';
import '../../../widgets/stereoscopic_ui.dart';

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
      backgroundColor: Colors.transparent, // 背景を透過させてPawBackgroundが見えるようにする
      body: PawBackground(
        child: SafeArea(
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
                      // 3匹の猫
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/tyatoranekopng.png',
                            height: 60,
                          ),
                          const SizedBox(width: 16),
                          Image.asset('assets/images/sironeko.png', height: 60),
                          const SizedBox(width: 16),
                          Image.asset('assets/images/kuroneko.png', height: 60),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: StereoscopicButton(
                          onPressed: isNotIdle
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  SeService().play('button_buni.mp3');
                                  viewModel.createRoom();
                                },
                          baseColor: Colors.pink.shade300,
                          shadowColor: Colors.pink.shade800,
                          child: Center(
                            child: (viewModel.state is LoadingState)
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'ルームを作成',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: StereoscopicButton(
                          onPressed: isNotIdle
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  SeService().play('button_buni.mp3');
                                  viewModel.startRandomMatch();
                                },
                          baseColor: Colors.orange,
                          shadowColor: Colors.orange.shade900,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.shuffle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'ランダムマッチ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      SizedBox(
                        height: 52,
                        child: StereoscopicButton(
                          onPressed: isNotIdle
                              ? null
                              : () => _handleJoinRoom(context, viewModel),
                          baseColor: Colors.blue.shade400,
                          shadowColor: Colors.blue.shade900,
                          child: Center(
                            child: (viewModel.state is LoadingState)
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'ルームに参加',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
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
                                StereoscopicButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    viewModel.acceptInvitation(invitation);
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
                                      '参加',
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
        child: SizedBox(
          width: 52,
          height: 52,
          child: StereoscopicButton(
            onPressed: onPressed,
            baseColor: Colors.pink.shade100,
            shadowColor: Colors.pink.shade800,
            borderRadius: 26,
            depth: 4,
            showStripes: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: child ?? Icon(icon, color: Colors.pink.shade900)),
                if (badge != null) Positioned(right: 4, top: 4, child: badge),
              ],
            ),
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
          StereoscopicButton(
            onPressed: () => Navigator.pop(context, true),
            baseColor: Colors.pink.shade300,
            shadowColor: Colors.pink.shade800,
            borderRadius: 12,
            depth: 4,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '参加する',
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
}
