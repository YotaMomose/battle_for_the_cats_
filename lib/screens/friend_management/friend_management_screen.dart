import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'friend_management_view_model.dart';
import '../home/home_screen_view_model.dart';
import '../../models/user_profile.dart';
import '../../models/friend.dart';
import '../../repositories/friend_repository.dart';
import '../../repositories/user_repository.dart';
import '../../constants/game_constants.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 自分のフレンドコード表示
            _buildMyCodeSection(context, myProfile),
            const SizedBox(height: 16),

            // 検索セクション
            _buildSearchSection(viewModel, myProfile),
            const SizedBox(height: 24),

            // 申請セクション
            if (viewModel.incomingRequests.isNotEmpty) ...[
              Text('届いている申請', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...viewModel.incomingRequests.map(
                (req) => _buildRequestItem(viewModel, req),
              ),
              const SizedBox(height: 24),
            ],

            // フレンド一覧
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('フレンド一覧', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${viewModel.friends.length} / ${GameConstants.maxFriendLimit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
    );
  }

  Widget _buildMyCodeSection(BuildContext context, UserProfile myProfile) {
    final code = myProfile.friendCode ?? '---';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '自分のフレンドコード',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: myProfile.friendCode == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('フレンドコードをコピーしました')),
                    );
                  },
            icon: const Icon(Icons.copy),
            tooltip: 'コピー',
          ),
        ],
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'フレンドコードを入力',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => viewModel.searchUser(_searchController.text),
              child: const Text('検索'),
            ),
          ],
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
          Card(
            margin: const EdgeInsets.only(top: 16),
            child: ListTile(
              leading: Text(
                UserIcon.fromId(viewModel.searchResult!.iconId).emoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(viewModel.searchResult!.displayName),
              subtitle: Text(viewModel.searchResult!.friendCode ?? ''),
              trailing: viewModel.isSearchResultFriend
                  ? const Text(
                      'すでにフレンドです',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => viewModel.sendRequest(
                        myProfile,
                        viewModel.searchResult!.uid,
                      ),
                      child: const Text('申請する'),
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
    return Card(
      child: ListTile(
        leading: Text(
          UserIcon.fromId(request.fromIconId).emoji,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(request.fromName),
        subtitle: const Text('フレンド申請が届いています'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => viewModel.respondToRequest(request, false),
              child: const Text('拒否', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => viewModel.respondToRequest(request, true),
              child: const Text('承認'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(BuildContext context, Friend friend) {
    final profile = friend.profile;
    return Card(
      child: ListTile(
        leading: Text(
          UserIcon.fromId(profile.iconId).emoji,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(profile.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.friendCode ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatBadge(context, '${friend.winCount}勝', Colors.green),
                const SizedBox(width: 4),
                _buildStatBadge(context, '${friend.lossCount}敗', Colors.red),
                const SizedBox(width: 8),
                Text(
                  '勝率 ${(friend.winRate * 100).toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
