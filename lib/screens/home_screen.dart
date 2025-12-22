import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isMatchmaking = false;
  String? _currentPlayerId;

  /// ルームを作成
  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    
    try {
      final playerId = DateTime.now().millisecondsSinceEpoch.toString();
      final roomCode = await _gameService.createRoom(playerId);
      
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              roomCode: roomCode,
              playerId: playerId,
              isHost: true,
            ),
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ルーム作成に失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ランダムマッチングを開始
  Future<void> _startRandomMatch() async {
    setState(() {
      _isMatchmaking = true;
      _currentPlayerId = DateTime.now().millisecondsSinceEpoch.toString();
    });

    try {
      // 待機リストに登録
      await _gameService.joinMatchmaking(_currentPlayerId!);

      if (!mounted) return;

      // マッチング監視を開始
      await for (final roomCode in _gameService.watchMatchmaking(_currentPlayerId!)) {
        if (!mounted) return;
        
        if (roomCode != null) {
          // マッチング成立！
          setState(() => _isMatchmaking = false);
          
          // マッチング情報を取得してホストかゲストか判定
          final isHost = await _gameService.isHostInMatch(_currentPlayerId!);
          
          // ゲーム画面へ遷移
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                roomCode: roomCode,
                playerId: _currentPlayerId!,
                isHost: isHost,
              ),
            ),
          );
          
          // マッチング情報をクリーンアップ
          await _gameService.cancelMatchmaking(_currentPlayerId!);
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMatchmaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('マッチングに失敗しました: $e')),
        );
      }
    }
  }

  /// ランダムマッチングをキャンセル
  Future<void> _cancelRandomMatch() async {
    if (_currentPlayerId != null) {
      await _gameService.cancelMatchmaking(_currentPlayerId!);
    }
    setState(() {
      _isMatchmaking = false;
      _currentPlayerId = null;
    });
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();
    
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルームコードを入力してください')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final playerId = DateTime.now().millisecondsSinceEpoch.toString();
      final success = await _gameService.joinRoom(roomCode, playerId);
      
      // 参加に失敗した場合はエラーメッセージを表示
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルームが見つからないか、すでに満員です')),
        );
        return;
      }
      
      // 参加成功後、ゲーム画面へ遷移
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            roomCode: roomCode,
            playerId: playerId,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ルーム参加に失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ホーム画面のUI
  @override
  Widget build(BuildContext context) {
    // マッチング中の画面
    if (_isMatchmaking) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ランダムマッチング'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 6),
                const SizedBox(height: 32),
                const Text(
                  'マッチング中...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '対戦相手を探しています',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: _cancelRandomMatch,
                  icon: const Icon(Icons.close),
                  label: const Text('キャンセル', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 通常のホーム画面
    return Scaffold(
      appBar: AppBar(
        title: const Text('ねこ争奪戦！'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.pets,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'ねこ争奪戦！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('ルームを作成', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startRandomMatch,
                icon: const Icon(Icons.shuffle),
                label: const Text('ランダムマッチ', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _roomCodeController,
                decoration: const InputDecoration(
                  labelText: 'ルームコード',
                  border: OutlineInputBorder(),
                  hintText: '6桁のコードを入力',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ルームに参加', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // マッチング中の場合はキャンセル
    if (_isMatchmaking && _currentPlayerId != null) {
      _gameService.cancelMatchmaking(_currentPlayerId!);
    }
    _roomCodeController.dispose();
    super.dispose();
  }
}
