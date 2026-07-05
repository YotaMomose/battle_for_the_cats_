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
  final bool hasCompletedTutorial;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.iconId,
    this.friendCode,
    this.isSupporter = false,
    this.adsRemoved = false,
    this.hasCompletedTutorial = false,
  });

  /// デフォルトのプロフィール（初回ログイン時に使用）
  factory UserProfile.defaultProfile(String uid) {
    return UserProfile(
      uid: uid,
      displayName: 'ゲスト',
      iconId: UserIcon.defaultIcon.id,
      isSupporter: false,
      adsRemoved: false,
      hasCompletedTutorial: false,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? iconId,
    String? friendCode,
    bool? isSupporter,
    bool? adsRemoved,
    bool? hasCompletedTutorial,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      iconId: iconId ?? this.iconId,
      friendCode: friendCode ?? this.friendCode,
      isSupporter: isSupporter ?? this.isSupporter,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      hasCompletedTutorial: hasCompletedTutorial ?? this.hasCompletedTutorial,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'iconId': iconId,
      'isSupporter': isSupporter,
      'adsRemoved': adsRemoved,
      'hasCompletedTutorial': hasCompletedTutorial,
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
      hasCompletedTutorial: map['hasCompletedTutorial'] ?? false,
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
          adsRemoved == other.adsRemoved &&
          hasCompletedTutorial == other.hasCompletedTutorial;

  @override
  int get hashCode => Object.hash(
    uid,
    displayName,
    iconId,
    friendCode,
    isSupporter,
    adsRemoved,
    hasCompletedTutorial,
  );

  @override
  String toString() =>
      'UserProfile(uid: $uid, displayName: $displayName, iconId: $iconId, friendCode: $friendCode, isSupporter: $isSupporter, adsRemoved: $adsRemoved, hasCompletedTutorial: $hasCompletedTutorial)';
}

/// プリセットアイコンの定義
class UserIcon {
  final String id;
  final String label;
  final String emoji;
  final String? imagePath;
  final bool isPremium;

  const UserIcon({
    required this.id,
    required this.label,
    required this.emoji,
    this.imagePath,
    this.isPremium = false,
  });

  /// デフォルトアイコン
  static const defaultIcon = UserIcon(
    id: 'person1',
    label: '人物1',
    emoji: '😸',
    imagePath: 'assets/images/person1.png',
  );

  /// 選択可能なアイコン一覧
  static const List<UserIcon> presets = [
    UserIcon(
      id: 'person1',
      label: '',
      emoji: '😸',
      imagePath: 'assets/images/person1.png',
    ),
    UserIcon(
      id: 'person2',
      label: '',
      emoji: '😺',
      imagePath: 'assets/images/person2.png',
    ),
    UserIcon(
      id: 'person3',
      label: '',
      emoji: '😼',
      imagePath: 'assets/images/person3.png',
    ),
    UserIcon(
      id: 'person4',
      label: '',
      emoji: '🙀',
      imagePath: 'assets/images/person4.png',
    ),
    UserIcon(
      id: 'person5',
      label: '',
      emoji: '😹',
      imagePath: 'assets/images/person5.png',
    ),
    UserIcon(
      id: 'person6',
      label: '',
      emoji: '😿',
      imagePath: 'assets/images/person6.png',
    ),
  ];

  /// IDからアイコンを取得
  static UserIcon fromId(String id) {
    switch (id) {
      case 'cat_black':
        return const UserIcon(
          id: 'cat_black',
          label: 'くろねこ',
          emoji: '🐈‍⬛',
          imagePath: 'assets/images/kuroneko.png',
        );
      case 'cat_white':
        return const UserIcon(
          id: 'cat_white',
          label: 'しろねこ',
          emoji: '🐈',
          imagePath: 'assets/images/sironeko.png',
        );
      case 'cat_orange':
        return const UserIcon(
          id: 'cat_orange',
          label: 'とらねこ',
          emoji: '🐱',
          imagePath: 'assets/images/tyatoranekopng.png',
        );
      case 'fisherman':
        return const UserIcon(
          id: 'fisherman',
          label: '漁師',
          emoji: '🎣',
          imagePath: 'assets/images/ryousi.png',
        );
      default:
        return presets.firstWhere(
          (icon) => icon.id == id,
          orElse: () => defaultIcon,
        );
    }
  }
}
