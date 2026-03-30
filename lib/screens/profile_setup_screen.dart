import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen_view_model.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../widgets/stereoscopic_ui.dart';
import '../widgets/user_icon_widget.dart';

/// 初回プロフィール設定画面
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameController;
  String? _selectedIconId;
  bool _isSaving = false;
  Timer? _checkNameTimer;
  bool _isCheckingName = false;
  bool? _isNameAvailable;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '');
    _selectedIconId = UserIcon.defaultIcon.id;
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {
      _isNameAvailable = null;
      _isCheckingName = false;
    });

    _checkNameTimer?.cancel();
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    _checkNameTimer = Timer(const Duration(milliseconds: 500), () {
      _checkDisplayNameAvailability(name);
    });
  }

  Future<void> _checkDisplayNameAvailability(String name) async {
    if (!mounted) return;
    setState(() => _isCheckingName = true);

    try {
      final repository = context.read<UserRepository>();
      final isTaken = await repository.isDisplayNameTaken(name);
      if (!mounted) return;
      setState(() {
        _isNameAvailable = !isTaken;
        _isCheckingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingName = false);
    }
  }

  @override
  void dispose() {
    _checkNameTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザー名を入力してください')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final viewModel = context.read<HomeScreenViewModel>();
      await viewModel.updateProfile(displayName: name, iconId: _selectedIconId);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('設定の保存に失敗しました: $message')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIcon = UserIcon.fromId(_selectedIconId ?? 'cat_orange');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9E6),
        body: Stack(
          children: [
            // 足跡パターンの背景
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/paw_background.png',
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.none,
                  scale: 1.5,
                ),
              ),
            ),
            Column(
              children: [
                // ヘッダー
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // アイコン選択セクション
                        _buildIconSelectionSection(selectedIcon),
                        const SizedBox(height: 16),

                        // ユーザー名セクション
                        _buildUsernameSection(),
                        const SizedBox(height: 24),

                        // 登録ボタン
                        _buildRegisterButton(),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFCE35),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4D331F),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ストライプ柄
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              child: CustomPaint(
                painter: StripePainter(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
          const Text(
            'プロフィール設定',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4D331F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelectionSection(UserIcon selectedIcon) {
    return Column(
      children: [
        const Text(
          'アイコンを選んでね！',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4D331F),
          ),
        ),
        Text(
          'あとから変更できるよ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4D331F).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),

        // プレビュー
        UserIconPreview(icon: selectedIcon, size: 110),
        const SizedBox(height: 4),
        Text(
          selectedIcon.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4D331F),
          ),
        ),
        const SizedBox(height: 24),

        // グリッド
        _buildIconGrid(),
      ],
    );
  }

  Widget _buildIconGrid() {
    final availableIcons = UserIcon.presets
        .where((icon) => !icon.isPremium)
        .toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: availableIcons.map((icon) {
        final isSelected = icon.id == _selectedIconId;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconId = icon.id),
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
                child: isSelected
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFCE35),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: UserIconWidget(icon: icon, size: 36),
                      )
                    : UserIconWidget(icon: icon, size: 36),
              ),
              const SizedBox(height: 4),
              Text(
                icon.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF4D331F)
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconWidget(UserIcon icon, {required double size}) {
    if (icon.imagePath != null) {
      return Image.asset(
        icon.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(icon.emoji, style: TextStyle(fontSize: size * 0.8));
        },
      );
    }
    return Text(icon.emoji, style: TextStyle(fontSize: size * 0.8));
  }

  Widget _buildUsernameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ユーザー名',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4D331F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4D331F), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFB38E5D),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4D331F),
                ),
                decoration: const InputDecoration(
                  hintText: 'なまえをにゅうりょく',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                maxLength: 12,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildValidationMessage(),
      ],
    );
  }

  Widget _buildValidationMessage() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return const Text(
        '※一意のユーザー名が必要です\n※あとから変更することはできません',
        style: TextStyle(
          fontSize: 11,
          color: Color(0xFFFF6B6B),
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isCheckingName) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('確認中...', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    }

    if (_isNameAvailable == false) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          SizedBox(width: 8),
          Text(
            'すでに使用されている名前です',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B6B),
            ),
          ),
        ],
      );
    }

    if (_isNameAvailable == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD4EDDA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF28A745), width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF28A745), size: 18),
            SizedBox(width: 8),
            Text(
              'このユーザー名は使用できます！',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF155724),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRegisterButton() {
    return StereoscopicButton(
      baseColor: const Color(0xFF5ABA61),
      shadowColor: const Color(0xFF3E7F43),
      borderRadius: 40,
      depth: 8,
      onPressed: _isSaving || _isCheckingName || _isNameAvailable != true
          ? null
          : _completeSetup,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'この内容で登録する！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
