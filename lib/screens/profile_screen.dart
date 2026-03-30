import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/se_service.dart';
import '../widgets/paw_background.dart';
import '../services/settings_service.dart';
import 'home/home_screen_view_model.dart';
import '../models/user_profile.dart';
import '../services/iap_service.dart';
import '../widgets/stereoscopic_ui.dart';
import '../widgets/user_icon_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();
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
                      'プロフィール設定',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 現在のアイコンプレビュー
              _buildMainProfileCard(context, viewModel),
              const SizedBox(height: 24),

              // アイコン選択
              _buildSectionHeader('アイコンを選択'),
              const SizedBox(height: 16),
              _buildIconGrid(context, viewModel),
              const SizedBox(height: 32),

              // 音設定
              _buildSectionHeader('サウンド設定'),
              const SizedBox(height: 16),
              _buildSoundSettings(context),
              const SizedBox(height: 40),

              // 開発者応援・広告非表示セクション（一番下に移動）
              if (viewModel.shouldShowAds) ...[
                _buildSupportSection(context, viewModel),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainProfileCard(
    BuildContext context,
    HomeScreenViewModel viewModel,
  ) {
    final code = viewModel.userProfile?.friendCode ?? '---';
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
              children: [
                UserIconPreview(
                  icon: UserIcon.fromId(_selectedIconId ?? 'cat_orange'),
                  size: 80,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4D331F),
                        ),
                      ),
                      _buildCapsuleLabel('ユーザー名', color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCapsuleLabel('フレンドコード', color: const Color(0xFFFFD54F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFF4D331F),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: viewModel.userProfile?.friendCode == null
                      ? null
                      : () {
                          SeService().play('button_buni.mp3');
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('コピーしました')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC80),
                    foregroundColor: const Color(0xFF4D331F),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'コピー',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(
    BuildContext context,
    HomeScreenViewModel viewModel,
  ) {
    return Column(
      children: [
        _buildSectionHeader('開発者を応援する'),
        const SizedBox(height: 16),
        StereoscopicContainer(
          baseColor: const Color(0xFFFFF9C4), // 薄黄色
          shadowColor: const Color(0xFFFBC02D).withOpacity(0.5),
          borderRadius: 24,
          showDots: true,
          showStripes: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.volunteer_activism, color: Color(0xFFEC407A)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '限定アイコン解放＆広告非表示',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4D331F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: StereoscopicButton(
                    onPressed: () {
                      SeService().play('button_buni.mp3');
                      IapService().buySupporter();
                    },
                    baseColor: const Color(0xFF66BB6A),
                    shadowColor: const Color(0xFF2E7D32),
                    borderRadius: 24,
                    depth: 4,
                    child: const Center(
                      child: Text(
                        'サポーターになる (応援)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.block, color: Color(0xFF90A4AE)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '広告を非表示にする',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4D331F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: StereoscopicButton(
                    onPressed: () {
                      SeService().play('button_buni.mp3');
                      IapService().buyRemoveAds();
                    },
                    baseColor: const Color(0xFF42A5F5), // 青
                    shadowColor: const Color(0xFF1565C0),
                    borderRadius: 24,
                    depth: 4,
                    child: const Center(
                      child: Text(
                        '広告非表示を購入',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconGrid(BuildContext context, HomeScreenViewModel viewModel) {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: UserIcon.presets.map((icon) {
          final isSelected = icon.id == _selectedIconId;
          final isLocked =
              icon.isPremium && !(viewModel.userProfile?.isSupporter ?? false);

          return GestureDetector(
            onTap: () async {
              SeService().play('button_buni.mp3');
              if (isLocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('このアイコンはサポーターになると解放されます')),
                );
                return;
              }
              if (icon.id == _selectedIconId) return;

              setState(() => _selectedIconId = icon.id);

              // 即座に保存
              try {
                await viewModel.updateProfile(iconId: icon.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                }
              }
            },
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white70,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: const Color(0xFFFFCE35), width: 3)
                        : Border.all(color: Colors.black12, width: 1),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFCE35).withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  padding: EdgeInsets.all(isSelected ? 2 : 6),
                  child: UserIconWidget(icon: icon, size: 36, isLocked: isLocked),
                ),
                const SizedBox(height: 4),
                Text(
                  icon.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? const Color(0xFF4D331F) : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return StereoscopicContainer(
          baseColor: Colors.white,
          shadowColor: const Color(0xFFD7CCC8),
          borderRadius: 24,
          showDots: true,
          showStripes: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildVolumeSlider(
                  label: 'BGM音量',
                  value: settings.bgmVolume,
                  icon: Icons.music_note,
                  onChanged: settings.setBgmVolume,
                ),
                const SizedBox(height: 16),
                _buildVolumeSlider(
                  label: 'SE音量',
                  value: settings.seVolume,
                  icon: Icons.volume_up,
                  onChanged: settings.setSeVolume,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required IconData icon,
    required Function(double) onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF4D331F)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              (value * 10).round().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1.0,
          divisions: 10,
          activeColor: const Color(0xFFFFD54F),
          inactiveColor: Colors.grey.shade200,
          onChanged: onChanged,
          onChangeEnd: (_) => SeService().play('button_buni.mp3'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4D331F),
      ),
    );
  }

  Widget _buildCapsuleLabel(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4D331F), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
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
