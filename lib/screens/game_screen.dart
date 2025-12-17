import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_room.dart';
import '../services/game_service.dart';

class GameScreen extends StatefulWidget {
  final String roomCode;
  final String playerId;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomCode,
    required this.playerId,
    required this.isHost,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _gameService = GameService();
  int _selectedFish = 0;
  bool _hasPlacedBet = false;

  void _placeBet() async {
    if (_selectedFish == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('魚の数を選択してください')),
      );
      return;
    }

    try {
      await _gameService.placeBet(widget.roomCode, widget.playerId, _selectedFish);
      setState(() => _hasPlacedBet = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ルームコードをコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ルーム: ${widget.roomCode}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyRoomCode,
            tooltip: 'ルームコードをコピー',
          ),
        ],
      ),
      body: StreamBuilder<GameRoom>(
        stream: _gameService.watchRoom(widget.roomCode),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = snapshot.data!;

          // 待機中
          if (room.status == 'waiting') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    '対戦相手を待っています...',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ルームコード: ${widget.roomCode}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('このコードを相手に共有してください'),
                ],
              ),
            );
          }

          // ゲーム終了
          if (room.status == 'finished') {
            return _buildResultScreen(room);
          }

          // ゲーム中
          final isHost = widget.isHost;
          final myFishCount = isHost ? room.hostFishCount : room.guestFishCount;
          final myReady = isHost ? room.hostReady : room.guestReady;
          final opponentReady = isHost ? room.guestReady : room.hostReady;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 対戦相手の状態
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '対戦相手',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          opponentReady ? '準備完了！' : '選択中...',
                          style: TextStyle(
                            fontSize: 16,
                            color: opponentReady ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 猫カード
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.pets, size: 80, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text(
                          'ねこ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 自分の情報
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'あなたの魚: $myFishCount 🐟',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (!myReady) ...[
                          const SizedBox(height: 16),
                          const Text('何匹の魚を置きますか?'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: List.generate(myFishCount + 1, (index) {
                              return ChoiceChip(
                                label: Text('$index'),
                                selected: _selectedFish == index,
                                onSelected: _hasPlacedBet
                                    ? null
                                    : (selected) {
                                        setState(() => _selectedFish = index);
                                      },
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _hasPlacedBet ? null : _placeBet,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              _hasPlacedBet ? '確定済み' : '確定',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            '準備完了！',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('結果を待っています...'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen(GameRoom room) {
    final isHost = widget.isHost;
    final myBet = isHost ? room.hostBet ?? 0 : room.guestBet ?? 0;
    final opponentBet = isHost ? room.guestBet ?? 0 : room.hostBet ?? 0;

    String resultText;
    Color resultColor;

    if (room.winner == 'draw') {
      resultText = '引き分け';
      resultColor = Colors.grey;
    } else if ((room.winner == 'host' && isHost) ||
        (room.winner == 'guest' && !isHost)) {
      resultText = 'あなたの勝利！';
      resultColor = Colors.green;
    } else {
      resultText = '敗北...';
      resultColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              resultText,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.pets, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'あなた: $myBet 🐟',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '相手: $opponentBet 🐟',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
