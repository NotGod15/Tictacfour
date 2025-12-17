import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../startpage.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _menuOpen = false;

  void _onMenuPressed() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
  }

  void _closeTopMenu() {
    setState(() {
      _menuOpen = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFEDE8D0);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onVerticalDragUpdate: (d) {
          if (d.primaryDelta != null && d.primaryDelta! < -10) {
            _closeTopMenu();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: _onMenuPressed,
                        ),
                        const SizedBox(width: 8),
                        const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<ScoreEntry>>(
                      stream: DBService.instance.topScoresStream(limit: 20),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          print('[Leaderboard Error] ${snap.error}');
                          return Center(child: Text('Error: ${snap.error}'));
                        }
                        final list = snap.data ?? [];
                        print('[Leaderboard] Fetched ${list.length} scores');
                        for (final e in list) {
                          print('[Leaderboard] Score: ${e.nickname} - ${e.score} pts - ${e.timeSeconds}s');
                        }
                        if (list.isEmpty) {
                          return const Center(child: Text('No scores yet'));
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final e = list[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(e.nickname),
                              subtitle: Text('Time: ${e.timeSeconds}s'),
                              trailing: Text('${e.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: 0,
                top: _menuOpen ? 0 : -180,
                right: 0,
                child: Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('Home'),
                          onTap: () {
                            _closeTopMenu();
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.leaderboard),
                          title: const Text('Leaderboard'),
                          onTap: () {
                            _closeTopMenu();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Log out'),
                          onTap: () async {
                            await AuthService.instance.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const StartPage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_menuOpen)
                Positioned(
                  top: 180,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeTopMenu,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
