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
  int _lastTurn = 0;  // 最後に処理したターン番号を記録

  // 賭けの合計を計算
  int get _totalBet => _bets.values.reduce((a, b) => a + b);
  
  // ローカル状態をリセット
  void _resetLocalState() {
    setState(() {
      _bets['0'] = 0;
      _bets['1'] = 0;
      _bets['2'] = 0;
      _hasPlacedBet = false;
    });
  }

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
          
          // 新しいターンになったらローカル状態をリセット
          if (room.currentTurn != _lastTurn && room.status == 'playing') {
            // 次のフレームで状態をリセット（build中の setState を避ける）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _resetLocalState();
                _lastTurn = room.currentTurn;
              }
            });
          }

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
            return _buildFinalResultScreen(room);
          }

          // ラウンド結果表示
          if (room.status == 'roundResult') {
            return _buildRoundResultScreen(room);
          }

          // ゲーム中
          final isHost = widget.isHost;
          final myFishCount = isHost ? room.hostFishCount : room.guestFishCount;
          final myReady = isHost ? room.hostReady : room.guestReady;
          final opponentReady = isHost ? room.guestReady : room.hostReady;
          final myCatsWon = isHost ? room.hostCatsWon : room.guestCatsWon;
          final opponentCatsWon = isHost ? room.guestCatsWon : room.hostCatsWon;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ターン情報とスコア表示
                  Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            'ターン ${room.currentTurn}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'あなた: $myCatsWon匹  |  相手: $opponentCatsWon匹',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                  const SizedBox(height: 16),

                  // 3匹の猫カード（横並び）
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: List.generate(3, (index) {
                        final catIndex = index.toString();
                        final catName = room.cats[index];
                        final currentBet = _bets[catIndex] ?? 0;

                        return Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.pets, size: 24, color: Colors.orange),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: Text(
                                        catName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!myReady) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '$currentBet 🐟',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
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
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            onPressed: _hasPlacedBet || _totalBet >= myFishCount
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _bets[catIndex] = currentBet + 1;
                                                    });
                                                  },
                                            icon: const Icon(Icons.add_circle),
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

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

  // ラウンド結果画面（次のターンへ進むボタン付き）
  Widget _buildRoundResultScreen(GameRoom room) {
    final isHost = widget.isHost;
    final myBets = isHost ? room.hostBets : room.guestBets;
    final opponentBets = isHost ? room.guestBets : room.hostBets;
    final winners = room.winners ?? {};
    final myCatsWon = isHost ? room.hostCatsWon : room.guestCatsWon;
    final opponentCatsWon = isHost ? room.guestCatsWon : room.hostCatsWon;

    // このラウンドで獲得した猫数をカウント
    int myRoundWins = 0;
    int opponentRoundWins = 0;

    for (int i = 0; i < 3; i++) {
      final catIndex = i.toString();
      final winner = winners[catIndex];
      if (winner == (isHost ? 'host' : 'guest')) {
        myRoundWins++;
      } else if (winner == (isHost ? 'guest' : 'host')) {
        opponentRoundWins++;
      }
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ターン ${room.currentTurn} 結果',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'このターン: あなた $myRoundWins匹 - $opponentRoundWins匹 相手',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '累計: あなた $myCatsWon匹 - $opponentCatsWon匹 相手',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // 各猫の結果（横並び）
              SizedBox(
                height: 160,
                child: Row(
                  children: List.generate(3, (index) {
                    final catIndex = index.toString();
                    final catName = room.cats[index];
                    final myBet = myBets[catIndex] ?? 0;
                    final opponentBet = opponentBets[catIndex] ?? 0;
                    final winner = winners[catIndex];

                    Color cardColor;
                    String winnerText;
                    if (winner == (isHost ? 'host' : 'guest')) {
                      cardColor = Colors.green.shade50;
                      winnerText = 'あなた獲得';
                    } else if (winner == (isHost ? 'guest' : 'host')) {
                      cardColor = Colors.red.shade50;
                      winnerText = '相手獲得';
                    } else {
                      cardColor = Colors.grey.shade50;
                      winnerText = '引き分け';
                    }

                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Card(
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pets, size: 24, color: Colors.orange),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    catName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  winnerText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: winner == 'draw' ? Colors.grey : (winner == (isHost ? 'host' : 'guest') ? Colors.green : Colors.red),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'あなた: $myBet',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '相手: $opponentBet',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  await _gameService.nextTurn(widget.roomCode);
                  // ローカル状態のリセットは StreamBuilder で自動的に行われる
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                ),
                child: const Text('次のターンへ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 最終結果画面（ゲーム終了）
  Widget _buildFinalResultScreen(GameRoom room) {
    final isHost = widget.isHost;
    final myCatsWon = isHost ? room.hostCatsWon : room.guestCatsWon;
    final opponentCatsWon = isHost ? room.guestCatsWon : room.hostCatsWon;

    String resultText;
    Color resultColor;

    if (room.finalWinner == 'draw') {
      resultText = '引き分け';
      resultColor = Colors.grey;
    } else if ((room.finalWinner == 'host' && isHost) ||
        (room.finalWinner == 'guest' && !isHost)) {
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
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      '最終スコア',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'あなた: $myCatsWon匹',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '相手: $opponentCatsWon匹',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '全${room.currentTurn}ターン',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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

  // 旧バージョン（削除済み）
}
