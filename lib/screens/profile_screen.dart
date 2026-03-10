import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/se_service.dart';
import '../widgets/paw_background.dart';
import '../services/settings_service.dart';
import 'home/home_screen_view_model.dart';
import '../models/user_profile.dart';
import '../services/iap_service.dart';

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
    // 名前変更は不可なので、アイコンのみ更新

    try {
      await viewModel.updateProfile(iconId: _selectedIconId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $message')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();
    return PawBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('プロフィール設定'),
          backgroundColor: Colors.transparent,
          elevation: 0,
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

              // ユーザー名表示（変更不可）
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ユーザー名 (変更不可)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                          SeService().play('button_buni.mp3');
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

              // 開発者応援・広告非表示セクション
              if (viewModel.shouldShowAds)
                Column(
                  children: [
                    // 開発者応援カード
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '開発者を応援する（限定アイコン解放）',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const Text(
                                        'プレミアムアイコンがすべて解放され、広告も非表示になります。',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  SeService().play('button_buni.mp3');
                                  IapService().buySupporter();
                                },
                                icon: const Icon(
                                  Icons.volunteer_activism,
                                  size: 18,
                                ),
                                label: const Text('応援する（投げ銭）'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 広告非表示カード
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.block, color: Colors.blueGrey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '広告を非表示にする',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const Text(
                                        'ゲーム内の広告が表示されなくなります。',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  SeService().play('button_buni.mp3');
                                  IapService().buyRemoveAds();
                                },
                                icon: const Icon(
                                  Icons.ad_units_outlined,
                                  size: 18,
                                ),
                                label: const Text('広告非表示を購入'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  final isLocked =
                      icon.isPremium &&
                      !(viewModel.userProfile?.isSupporter ?? false);

                  return GestureDetector(
                    onTap: () {
                      SeService().play('button_buni.mp3');
                      if (isLocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('このアイコンは開発者を応援すると解放されます'),
                          ),
                        );
                        return;
                      }
                      setState(() => _selectedIconId = icon.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : isLocked
                            ? Colors.grey.withOpacity(0.1)
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: isLocked ? 0.3 : 1.0,
                                child: Text(
                                  icon.emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                icon.label,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isLocked ? Colors.grey : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (isLocked)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // 音設定
              Text('サウンド設定', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Consumer<SettingsService>(
                builder: (context, settings, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BGM設定
                      Row(
                        children: [
                          const Icon(Icons.music_note, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Text('BGM音量'),
                          const Spacer(),
                          Text(
                            (settings.bgmVolume * 10).round().toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.bgmVolume,
                        min: 0,
                        max: 1.0,
                        divisions: 10,
                        label: (settings.bgmVolume * 10).round().toString(),
                        onChanged: (value) {
                          settings.setBgmVolume(value);
                        },
                        onChangeEnd: (value) {
                          SeService().play('button_buni.mp3');
                        },
                      ),
                      const SizedBox(height: 16),
                      // SE設定
                      Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Text('SE音量'),
                          const Spacer(),
                          Text(
                            (settings.seVolume * 10).round().toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.seVolume,
                        min: 0,
                        max: 1.0,
                        divisions: 10,
                        label: (settings.seVolume * 10).round().toString(),
                        onChanged: (value) {
                          settings.setSeVolume(value);
                        },
                        onChangeEnd: (value) {
                          SeService().play('button_buni.mp3');
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // 保存ボタン
              FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        SeService().play('button_buni.mp3');
                        _saveProfile();
                      },
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
      ),
    );
  }
}
