import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'repositories/firestore_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/friend_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 匿名認証を実行（既存セッションがあれば自動復元）
  final authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
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
      title: 'ねこ争奪戦！',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
