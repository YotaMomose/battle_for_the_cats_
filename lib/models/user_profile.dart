/// ユーザープロフィール情報を保持するデータモデル
///
/// Firestore の `users/{uid}` に保存され、アプリ起動時に自動的に読み込まれる。
class UserProfile {
  final String uid;
  final String displayName;
  final String iconId;
  final String? friendCode;
  final bool isSupporter;
  final bool adsRemoved;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.iconId,
    this.friendCode,
    this.isSupporter = false,
    this.adsRemoved = false,
  });

  /// デフォルトのプロフィール（初回ログイン時に使用）
  factory UserProfile.defaultProfile(String uid) {
    return UserProfile(
      uid: uid,
      displayName: 'ゲスト',
      iconId: UserIcon.defaultIcon.id,
      isSupporter: false,
      adsRemoved: false,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? iconId,
    String? friendCode,
    bool? isSupporter,
    bool? adsRemoved,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      iconId: iconId ?? this.iconId,
      friendCode: friendCode ?? this.friendCode,
      isSupporter: isSupporter ?? this.isSupporter,
      adsRemoved: adsRemoved ?? this.adsRemoved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'iconId': iconId,
      'isSupporter': isSupporter,
      'adsRemoved': adsRemoved,
      if (friendCode != null) 'friendCode': friendCode,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'ゲスト',
      iconId: map['iconId'] ?? UserIcon.defaultIcon.id,
      friendCode: map['friendCode'],
      isSupporter: map['isSupporter'] ?? false,
      adsRemoved: map['adsRemoved'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          uid == other.uid &&
          displayName == other.displayName &&
          iconId == other.iconId &&
          friendCode == other.friendCode &&
          isSupporter == other.isSupporter &&
          adsRemoved == other.adsRemoved;

  @override
  int get hashCode => Object.hash(
    uid,
    displayName,
    iconId,
    friendCode,
    isSupporter,
    adsRemoved,
  );

  @override
  String toString() =>
      'UserProfile(uid: $uid, displayName: $displayName, iconId: $iconId, friendCode: $friendCode, isSupporter: $isSupporter, adsRemoved: $adsRemoved)';
}

/// プリセットアイコンの定義
class UserIcon {
  final String id;
  final String label;
  final String emoji;
  final bool isPremium;

  const UserIcon({
    required this.id,
    required this.label,
    required this.emoji,
    this.isPremium = false,
  });

  /// デフォルトアイコン
  static const defaultIcon = UserIcon(
    id: 'cat_orange',
    label: '茶トラねこ',
    emoji: '🐱',
  );

  /// 選択可能なアイコン一覧
  static const List<UserIcon> presets = [
    UserIcon(id: 'cat_orange', label: '茶トラねこ', emoji: '🐱'),
    UserIcon(id: 'cat_white', label: '白ねこ', emoji: '🐈'),
    UserIcon(id: 'cat_black', label: '黒ねこ', emoji: '🐈‍⬛'),
    UserIcon(id: 'dog', label: '犬', emoji: '🐶'),
    UserIcon(id: 'fish', label: 'さかな', emoji: '🐟'),
    UserIcon(id: 'octopus', label: 'たこ', emoji: '🐙'),
    UserIcon(id: 'penguin', label: 'ペンギン', emoji: '🐧'),
    UserIcon(id: 'rabbit', label: 'うさぎ', emoji: '🐰'),

    // プレミアムアイコン
    UserIcon(id: 'cat_crown', label: '王冠ねこ', emoji: '🤴', isPremium: true),
    UserIcon(id: 'cat_diamond', label: '宝石ねこ', emoji: '💎', isPremium: true),
    UserIcon(id: 'trophy', label: 'トロフィー', emoji: '🏆', isPremium: true),
    UserIcon(id: 'star', label: 'スター', emoji: '⭐', isPremium: true),
  ];

  /// IDからアイコンを取得
  static UserIcon fromId(String id) {
    return presets.firstWhere(
      (icon) => icon.id == id,
      orElse: () => defaultIcon,
    );
  }
}
