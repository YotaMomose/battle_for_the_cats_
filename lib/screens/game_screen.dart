import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_room.dart';
import '../services/game_service.dart';

/// ゲーム画面
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
  
  // 各猫への賭け（猫のインデックス -> 魚の数）
  final Map<String, int> _bets = {'0': 0, '1': 0, '2': 0};
  bool _hasPlacedBet = false;

  // 賭けの合計を計算
  int get _totalBet => _bets.values.reduce((a, b) => a + b);

  void _placeBets() async {
    if (_totalBet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('少なくとも1匹以上の魚を置いてください')),
      );
      return;
    }

    try {
      await _gameService.placeBets(widget.roomCode, widget.playerId, _bets);
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

          return SingleChildScrollView(
            child: Padding(
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
                  const SizedBox(height: 24),

                  // 3匹の猫カード
                  ...List.generate(3, (index) {
                    final catIndex = index.toString();
                    final catName = room.cats[index];
                    final currentBet = _bets[catIndex] ?? 0;

                    return Column(
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.pets, size: 40, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Text(
                                      catName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!myReady) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '置いた魚: $currentBet 🐟',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: _hasPlacedBet || currentBet == 0
                                            ? null
                                            : () {
                                                setState(() {
                                                  _bets[catIndex] = currentBet - 1;
                                                });
                                              },
                                        icon: const Icon(Icons.remove_circle),
                                        iconSize: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        onPressed: _hasPlacedBet || _totalBet >= myFishCount
                                            ? null
                                            : () {
                                                setState(() {
                                                  _bets[catIndex] = currentBet + 1;
                                                });
                                              },
                                        icon: const Icon(Icons.add_circle),
                                        iconSize: 32,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // 自分の情報
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '残りの魚: ${myFishCount - _totalBet} / $myFishCount 🐟',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (!myReady) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _hasPlacedBet ? null : _placeBets,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen(GameRoom room) {
    final isHost = widget.isHost;
    final myBets = isHost ? room.hostBets : room.guestBets;
    final opponentBets = isHost ? room.guestBets : room.hostBets;
    final winners = room.winners ?? {};

    // 各プレイヤーの勝利数をカウント
    int myWins = 0;
    int opponentWins = 0;
    int draws = 0;

    for (int i = 0; i < 3; i++) {
      final catIndex = i.toString();
      final winner = winners[catIndex];
      if (winner == (isHost ? 'host' : 'guest')) {
        myWins++;
      } else if (winner == (isHost ? 'guest' : 'host')) {
        opponentWins++;
      } else {
        draws++;
      }
    }

    String resultText;
    Color resultColor;

    if (myWins > opponentWins) {
      resultText = 'あなたの勝利！';
      resultColor = Colors.green;
    } else if (opponentWins > myWins) {
      resultText = '敗北...';
      resultColor = Colors.red;
    } else {
      resultText = '引き分け';
      resultColor = Colors.grey;
    }

    return Center(
      child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Text(
                'あなた $myWins - $opponentWins 相手',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 32),
              
              // 各猫の結果
              ...List.generate(3, (index) {
                final catIndex = index.toString();
                final catName = room.cats[index];
                final myBet = myBets[catIndex] ?? 0;
                final opponentBet = opponentBets[catIndex] ?? 0;
                final winner = winners[catIndex];

                Color cardColor;
                String winnerText;
                if (winner == (isHost ? 'host' : 'guest')) {
                  cardColor = Colors.green.shade50;
                  winnerText = 'あなたの獲得！';
                } else if (winner == (isHost ? 'guest' : 'host')) {
                  cardColor = Colors.red.shade50;
                  winnerText = '相手の獲得';
                } else {
                  cardColor = Colors.grey.shade50;
                  winnerText = '引き分け';
                }

                return Column(
                  children: [
                    Card(
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pets, size: 40, color: Colors.orange),
                                const SizedBox(width: 12),
                                Text(
                                  catName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              winnerText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: winner == 'draw' ? Colors.grey : (winner == (isHost ? 'host' : 'guest') ? Colors.green : Colors.red),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'あなた: $myBet 🐟  vs  相手: $opponentBet 🐟',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

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
      ),
    );
  }
}
