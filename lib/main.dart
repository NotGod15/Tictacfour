import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'startpage.dart';
import 'pages/login_page.dart';
import 'pages/game_home.dart';
import 'pages/leaderboard_page.dart';
import 'firebase_options.dart';

// initialize Firebase and run app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TicTacFourApp());
}

// root app widget
class TicTacFourApp extends StatelessWidget {
  const TicTacFourApp({super.key});

  @override
  Widget build(BuildContext context) {
    // set Material Design theme and navigation routes
    return MaterialApp(
      title: 'Tic Tac Four',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // start from StartPage
      home: const StartPage(),
      // define app routes
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const GameHomePage(),
        '/leaderboard': (_) => const LeaderboardPage(),
      },
    );
  }
}
