import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/se_service.dart';
import '../../widgets/paw_background.dart';
import 'friend_management_view_model.dart';
import '../home/home_screen_view_model.dart';
import '../../models/user_profile.dart';
import '../../models/friend.dart';
import '../../repositories/friend_repository.dart';
import '../../repositories/user_repository.dart';
import '../../constants/game_constants.dart';
import '../../widgets/stereoscopic_ui.dart';
import '../../widgets/user_icon_widget.dart';
import 'package:flutter/cupertino.dart';

class FriendManagementScreen extends StatelessWidget {
  const FriendManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.read<HomeScreenViewModel>();
    final userProfile = homeViewModel.userProfile;

    if (userProfile == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    return ChangeNotifierProvider(
      create: (context) => FriendManagementViewModel(
        userRepository: context.read<UserRepository>(),
        friendRepository: context.read<FriendRepository>(),
        currentUserId: userProfile.uid,
      )..initialize(),
      child: const _FriendManagementView(),
    );
  }
}

class _FriendManagementView extends StatefulWidget {
  const _FriendManagementView();

  @override
  State<_FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<_FriendManagementView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendManagementViewModel>();
    final homeViewModel = context.read<HomeScreenViewModel>();
    final myProfile = homeViewModel.userProfile!;

    return PawBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F), // 明るい黄色
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: StripePainter(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'フレンド管理',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.brown.shade900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          SeService().play('button_buni.mp3');
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.brown.shade900,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 自分のフレンドコード表示
              _buildMyCodeSection(context, myProfile),
              const SizedBox(height: 20),

              // 検索セクション
              _buildSearchSection(viewModel, myProfile),
              const SizedBox(height: 32),

              // 申請セクション
              if (viewModel.incomingRequests.isNotEmpty) ...[
                _buildSectionHeader(context, '届いている申請'),
                const SizedBox(height: 12),
                ...viewModel.incomingRequests.map(
                  (req) => _buildRequestItem(viewModel, req),
                ),
                const SizedBox(height: 32),
              ],

              // フレンド一覧
              _buildSectionHeader(
                context,
                'フレンド一覧',
                trailing:
                    '${viewModel.friends.length} / ${GameConstants.maxFriendLimit}',
              ),
              const SizedBox(height: 12),
              if (viewModel.isLoading && viewModel.friends.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.friends.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('フレンドがまだいません'),
                  ),
                )
              else
                ...viewModel.friends.map(
                  (friend) => _buildFriendItem(context, friend),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCodeSection(BuildContext context, UserProfile myProfile) {
    final code = myProfile.friendCode ?? '---';
    return StereoscopicContainer(
      baseColor: Colors.white,
      shadowColor: const Color(0xFFD7CCC8),
      borderRadius: 24,
      showDots: true,
      showStripes: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildCapsuleLabel(
                  '自分のフレンドコード',
                  color: const Color(0xFFFFD54F),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4D331F),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  width: 64,
                  child: StereoscopicButton(
                    onPressed: myProfile.friendCode == null
                        ? null
                        : () {
                            SeService().play('button_buni.mp3');
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('フレンドコードをコピーしました')),
                            );
                          },
                    baseColor: const Color(0xFFFFD54F),
                    shadowColor: const Color(0xFF8D6E63),
                    borderRadius: 16,
                    depth: 3,
                    child: const Center(
                      child: Text(
                        'コピー',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4D331F),
                        ),
                      ),
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

  Widget _buildSearchSection(
    FriendManagementViewModel viewModel,
    UserProfile myProfile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StereoscopicContainer(
          baseColor: Colors.white,
          shadowColor: const Color(0xFFD7CCC8),
          borderRadius: 40,
          showDots: true,
          showStripes: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'フレンドコードを入力',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(
                  height: 48,
                  width: 80,
                  child: StereoscopicButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            SeService().play('button_buni.mp3');
                            viewModel.searchUser(_searchController.text);
                          },
                    baseColor: const Color(0xFF66BB6A),
                    shadowColor: const Color(0xFF2E7D32),
                    borderRadius: 24,
                    depth: 4,
                    child: const Center(
                      child: Text(
                        '検索',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (viewModel.searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              viewModel.searchError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (viewModel.searchResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildFriendCard(
              context,
              name: viewModel.searchResult!.displayName,
              iconId: viewModel.searchResult!.iconId,
              friendCode: viewModel.searchResult!.friendCode ?? '',
              trailing: viewModel.isSearchResultFriend
                  ? const Text(
                      'すでにフレンドです',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : StereoscopicButton(
                      onPressed: () {
                        SeService().play('button_buni.mp3');
                        viewModel.sendRequest(
                          myProfile,
                          viewModel.searchResult!.uid,
                        );
                      },
                      baseColor: const Color(0xFF66BB6A),
                      shadowColor: const Color(0xFF2E7D32),
                      borderRadius: 12,
                      depth: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '申請する',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildRequestItem(
    FriendManagementViewModel viewModel,
    dynamic request,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildFriendCard(
        context,
        name: request.fromName,
        iconId: request.fromIconId,
        subtitle: 'フレンド申請が届いています',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                SeService().play('button_buni.mp3');
                viewModel.respondToRequest(request, false);
              },
              child: const Text('拒否', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            StereoscopicButton(
              onPressed: () {
                SeService().play('button_buni.mp3');
                viewModel.respondToRequest(request, true);
              },
              baseColor: const Color(0xFFFFD54F),
              shadowColor: const Color(0xFF8D6E63),
              borderRadius: 12,
              depth: 4,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '承認',
                  style: TextStyle(
                    color: Color(0xFF4D331F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(BuildContext context, Friend friend) {
    final profile = friend.profile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildFriendCard(
        context,
        name: profile.displayName,
        iconId: profile.iconId,
        friendCode: profile.friendCode ?? '',
        stats: Row(
          children: [
            _buildStatBadge(
              context,
              '${friend.winCount}勝',
              const Color(0xFF66BB6A),
            ),
            const SizedBox(width: 6),
            _buildStatBadge(
              context,
              '${friend.lossCount}敗',
              const Color(0xFFEF5350),
            ),
            const SizedBox(width: 10),
            _buildStatBadge(
              context,
              '勝率 ${(friend.winRate * 100).toStringAsFixed(1)}%',
              const Color(0xFFFFD54F),
              textColor: const Color(0xFF4D331F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String label,
    Color color, {
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// 汎用的なフレンドカード
  Widget _buildFriendCard(
    BuildContext context, {
    required String name,
    required String iconId,
    String? friendCode,
    String? subtitle,
    Widget? stats,
    Widget? trailing,
  }) {
    return StereoscopicContainer(
      baseColor: Colors.white,
      shadowColor: const Color(0xFFD7CCC8),
      borderRadius: 24,
      showDots: true,
      showStripes: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserIconWidget(
              icon: UserIcon.fromId(iconId),
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4D331F),
                    ),
                  ),
                  if (friendCode != null)
                    Text(
                      friendCode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade300,
                      ),
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (stats != null) ...[const SizedBox(height: 8), stats],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? trailing,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4D331F),
          ),
        ),
        const Spacer(),
        if (trailing != null) _buildCapsuleLabel(trailing),
      ],
    );
  }

  Widget _buildCapsuleLabel(
    String text, {
    Color color = const Color(0xFFFFD54F),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4D331F),
        ),
      ),
    );
  }
}

class StripePainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double gap;

  StripePainter({required this.color, this.stripeWidth = 20, this.gap = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width; i += stripeWidth + gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
