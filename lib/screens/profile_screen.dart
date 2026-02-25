import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'home/home_screen_view_model.dart';
import '../models/user_profile.dart';

/// プロフィール設定画面
///
/// ユーザー名の編集とプリセットアイコンの選択ができる。
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  String? _selectedIconId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<HomeScreenViewModel>();
    final profile = viewModel.userProfile;
    _nameController = TextEditingController(
      text: profile?.displayName ?? 'ゲスト',
    );
    _selectedIconId = profile?.iconId ?? UserIcon.defaultIcon.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final viewModel = context.read<HomeScreenViewModel>();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザー名を入力してください')));
      setState(() => _isSaving = false);
      return;
    }

    if (name.length > 12) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザー名は12文字以内にしてください')));
      setState(() => _isSaving = false);
      return;
    }

    await viewModel.updateProfile(displayName: name, iconId: _selectedIconId);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 現在のアイコンプレビュー
            Center(
              child: Column(
                children: [
                  Text(
                    UserIcon.fromId(_selectedIconId ?? 'cat_orange').emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UserIcon.fromId(_selectedIconId ?? 'cat_orange').label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ユーザー名入力
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                hintText: '表示名を入力',
                border: OutlineInputBorder(),
                counterText: '最大12文字',
              ),
              maxLength: 12,
            ),
            const SizedBox(height: 12),

            // フレンドコード表示
            if (viewModel.userProfile?.friendCode != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, size: 20),
                    const SizedBox(width: 8),
                    const Text('フレンドコード: '),
                    Text(
                      viewModel.userProfile!.friendCode!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: viewModel.userProfile!.friendCode!,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('コピーしました')),
                        );
                      },
                      tooltip: 'コピー',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // アイコン選択
            Text('アイコンを選択', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: UserIcon.presets.length,
              itemBuilder: (context, index) {
                final icon = UserIcon.presets[index];
                final isSelected = icon.id == _selectedIconId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconId = icon.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(icon.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          icon.label,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '保存する'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
