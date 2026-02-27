import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/friend_request.dart';
import '../../repositories/friend_repository.dart';
import '../../repositories/user_repository.dart';

class FriendManagementViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final FriendRepository _friendRepository;
  final String _currentUserId;

  FriendManagementViewModel({
    required UserRepository userRepository,
    required FriendRepository friendRepository,
    required String currentUserId,
  }) : _userRepository = userRepository,
       _friendRepository = friendRepository,
       _currentUserId = currentUserId;

  List<UserProfile> _friends = [];
  List<UserProfile> get friends => _friends;

  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> get incomingRequests => _incomingRequests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _searchError;
  String? get searchError => _searchError;

  UserProfile? _searchResult;
  UserProfile? get searchResult => _searchResult;

  bool _isSearchResultFriend = false;
  bool get isSearchResultFriend => _isSearchResultFriend;

  void initialize() {
    _loadFriends();
    _watchRequests();
  }

  Future<void> _loadFriends() async {
    _isLoading = true;
    notifyListeners();

    try {
      final friendIds = await _friendRepository.getFriendIds(_currentUserId);
      final profiles = <UserProfile>[];
      for (final id in friendIds) {
        final profile = await _userRepository.getProfile(id);
        if (profile != null) profiles.add(profile);
      }
      _friends = profiles;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _watchRequests() {
    _friendRepository
        .watchIncomingRequests(_currentUserId)
        .listen(
          (requests) {
            _incomingRequests = requests;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[FriendManagementViewModel] watchRequests Error: $e');
            _searchError = 'リクエストの監視中にエラーが発生しました';
            notifyListeners();
          },
        );
  }

  /// フレンドコードで検索
  Future<void> searchUser(String code) async {
    _searchError = null;
    _searchResult = null;
    if (code.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _userRepository.findByFriendCode(code);
      if (result == null) {
        _searchError = 'ユーザーが見つかりませんでした';
      } else if (result.uid == _currentUserId) {
        _searchError = '自分自身は検索できません';
      } else {
        _searchResult = result;
        // フレンドかどうかチェック
        _isSearchResultFriend = await _friendRepository.isFriend(
          _currentUserId,
          result.uid,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 申請送信
  Future<void> sendRequest(UserProfile from, String toId) async {
    try {
      await _friendRepository.sendFriendRequest(from, toId);
      _searchResult = null;
      notifyListeners();
    } catch (e) {
      _searchError = e.toString();
      notifyListeners();
    }
  }

  /// 申請に回答
  Future<void> respondToRequest(FriendRequest request, bool accept) async {
    try {
      await _friendRepository.respondToRequest(request, accept);
      if (accept) {
        _loadFriends(); // 一覧を再取得
      }
    } catch (e) {
      _searchError = 'リクエストへの回答に失敗しました: $e';
      notifyListeners();
    }
  }
}
