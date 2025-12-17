import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'startpage.dart';
import 'pages/login_page.dart';
import 'pages/game_home.dart';
import 'pages/leaderboard_page.dart';
import 'firebase_options.dart';

// this is the entry point of the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TicTacFourApp());
}

class TicTacFourApp extends StatelessWidget {
  const TicTacFourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Four',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StartPage(),
      // these are the different pages you can navigate to
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const GameHomePage(),
        '/leaderboard': (_) => const LeaderboardPage(),
      },
    );
  }
}
