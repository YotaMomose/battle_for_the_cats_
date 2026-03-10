import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/bgm_service.dart';
import 'services/settings_service.dart';
import 'repositories/firestore_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/friend_repository.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面を縦向きに固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 設定の初期化
  final settingsService = SettingsService();
  await settingsService.initialize();

  // BGMの初期化と再生
  final bgmService = BgmService();
  await bgmService.initialize();
  await bgmService.playBgm('bgm_main.mp3');

  // 認証を初期化
  final authService = AuthService();
  await authService.initialize();

  // 広告の初期化
  final adService = AdService();
  await adService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => BgmService()),
        Provider(create: (_) => FirestoreRepository()),
        ProxyProvider<FirestoreRepository, UserRepository>(
          update: (_, firestore, __) => UserRepository(repository: firestore),
        ),
        ProxyProvider<FirestoreRepository, FriendRepository>(
          update: (_, firestore, __) => FriendRepository(repository: firestore),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle for the Cats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
