import 'package:flutter/material.dart';

/// 対戦相手待機画面
class WaitingView extends StatelessWidget {
  final String roomCode;

  const WaitingView({
    super.key,
    required this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
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
            'ルームコード: $roomCode',
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
}
