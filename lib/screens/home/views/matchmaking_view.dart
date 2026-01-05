import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home_screen_view_model.dart';

/// ランダムマッチング中画面
class MatchmakingView extends StatelessWidget {
  const MatchmakingView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeScreenViewModel>();

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
                onPressed: () => viewModel.cancelMatchmaking(),
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
}
