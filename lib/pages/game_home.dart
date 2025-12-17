import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../tictacfourlogic.dart';
import '../cell.dart';
import '../startpage.dart';

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> {
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

  // shows dialog with game rules
  void _showRules() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Rules'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. You have 5 tokens',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '2. You must make a connecting line between sides similar to Tic-Tac-Toe',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '3. After placing the fifth token, the placed token will be moved on your next turn starting from the first token',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: _onMenuPressed,
                        ),
                        const SizedBox(width: 8),
                        const Text('Game Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _showRules,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          ),
                          child: const Text('Rules'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('Choose your symbol', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => tictaclogic(initialSymbol: Cell.X)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(80),
                            ),
                            child: const Text('Play as X\n(X goes first)', textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => tictaclogic(initialSymbol: Cell.O)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(80),
                            ),
                            child: const Text('Play as O\n(O goes second)', textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                    Center(child: Text('Signed in as: ${AuthService.instance.currentUser?.displayName ?? (AuthService.instance.isGuest ? "Guest" : AuthService.instance.currentUser?.email ?? "Unknown") }')),
                    const SizedBox(height: 12),
                  ],
                ),
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
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.leaderboard),
                          title: const Text('Leaderboard'),
                          onTap: () {
                            _closeTopMenu();
                            Navigator.of(context).pushNamed('/leaderboard');
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