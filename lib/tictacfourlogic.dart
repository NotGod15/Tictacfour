import 'dart:math';
import 'package:flutter/material.dart';

import 'cell.dart';
import 'botmove.dart';
import 'startpage.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';

enum player { human, bot }

class tictaclogic extends StatefulWidget {
  final Cell? initialSymbol;
  const tictaclogic({super.key, this.initialSymbol});

  @override
  State<tictaclogic> createState() => _tictaclogicState();
}

class _tictaclogicState extends State<tictaclogic> {
  static const int size = 4;
  static const int maxtoken = 5;

  final BotMoveEngine _botEngine = BotMoveEngine();

  late List<Cell> board;

  Cell humansymbol = Cell.X;
  Cell botsymbol = Cell.O;

  final List<int> humantoken = [];
  final List<int> bottoken = [];

  int _humannexttokenid = 1;
  int _botnexttokenid = 1;

  final Map<int, int> _humantokenidbycell = {};
  final Map<int, int> _bottokenidbycell = {};

  player currentturn = player.human;
  bool gameover = false;
  bool _symbolchosen = false;
  Cell? winner;

  DateTime? starttime;
  Duration? elapsedtime;

  int score = 100;
  int humanmoves = 0;
  int botmoves = 0;
  int totalmoves = 0;

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

  void _showAbandonConfirmation(String title, String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text('Are you sure you want to $action? This will abandon your current game'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    _resetgame();
  }

  void _resetgame() {
    board = List<Cell>.filled(size * size, Cell.empty);
    humantoken.clear();
    bottoken.clear();

    score = 100;
    humanmoves = 0;
    botmoves = 0;
    totalmoves = 0;

    gameover = false;
    winner = null;
    starttime = null;
    elapsedtime = null;

    currentturn = player.human;
    _symbolchosen = false;

    _humannexttokenid = 1;
    _botnexttokenid = 1;
    _humantokenidbycell.clear();
    _bottokenidbycell.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSymbol != null) {
        _setsymbolsthenstart(widget.initialSymbol!);
      } else {
        _showsymbolchoicedialog();
      }
    });

    setState(() {});
  }

  void _showsymbolchoicedialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Choose Your Symbol'),
          content: const Text(
            'X goes first.\n\nChoose whether you want to play as X or O.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _setsymbolsthenstart(Cell.X);
                Navigator.of(context).pop();
              },
              child: const Text('Play as X'),
            ),
            TextButton(
              onPressed: () {
                _setsymbolsthenstart(Cell.O);
                Navigator.of(context).pop();
              },
              child: const Text('Play as O'),
            ),
          ],
        );
      },
    );
  }

  void _setsymbolsthenstart(Cell chosen) {
    setState(() {
      humansymbol = chosen;
      botsymbol = (chosen == Cell.X) ? Cell.O : Cell.X;

      currentturn = (humansymbol == Cell.X) ? player.human : player.bot;

      _symbolchosen = true;
      starttime = DateTime.now();
    });

    if (currentturn == player.bot) {
      Future.delayed(const Duration(milliseconds: 400), _botmove);
    }
  }

  // this is for checking if someone won the game by getting 4 in a row
  Cell? _checkwinner() {
    List<List<int>> lines = [];

    for (int r = 0; r < size; r++) {
      lines.add([r * size, r * size + 1, r * size + 2, r * size + 3]);
    }
    for (int c = 0; c < size; c++) {
      lines.add([c, c + size, c + 2 * size, c + 3 * size]);
    }
    lines.add([0, 5, 10, 15]);
    lines.add([3, 6, 9, 12]);

    for (var line in lines) {
      Cell a = board[line[0]];
      if (a == Cell.empty) continue;
      if (line.every((idx) => board[idx] == a)) {
        return a;
      }
    }
    return null;
  }

  // for showing the end game dialog and saving score to database if player won
  void _finishGame(Cell? winnersymbol) {
    gameover = true;
    winner = winnersymbol;
    elapsedtime = DateTime.now().difference(starttime ?? DateTime.now());

    String title;
    bool isWin = winnersymbol == humansymbol;
    bool isDraw = winnersymbol == null;
    
    if (isDraw) {
      title = 'Draw!';
    } else if (isWin) {
      title = 'You Win!';
    } else {
      title = 'You Lose!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWin) ...[
                Text('Score: $score'),
                if (elapsedtime != null)
                  Text('Time: ${elapsedtime!.inSeconds}s'),
                const SizedBox(height: 12),
                const Text(
                  'When tied with other players, ranking is based on time taken.',
                  style: TextStyle(fontSize: 12),
                ),
              ] else if (isDraw) ...[
                const Text('No winner this time!'),
              ] else ...[
                const Text('Better luck next time!'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetgame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Main Menu'),
            ),
          ],
        );
      },
    );

    if (winnersymbol == humansymbol) {
      final auth = AuthService.instance;
      if (!auth.isGuest && auth.currentUser != null) {
        final nick = auth.currentUser!.displayName ?? auth.currentUser!.email?.split('@').first ?? 'Player';
        final t = elapsedtime?.inSeconds ?? 0;
        DBService.instance.saveScore(nickname: nick, score: score, timeSeconds: t);
      }
    }
  }

  // this function reduces player score based on how many moves they made
  // more moves = bigger penalty to make game harder
  void _applyscorepenalty() {
    if (humanmoves <= 5) return;

    int penalty;
    if (humanmoves <= 10) {
      penalty = 1;
    } else if (humanmoves <= 20) {
      penalty = 2;
    } else if (humanmoves <= 30) {
      penalty = 5;
    } else if (humanmoves <= 40) {
      penalty = 10;
    } else {
      penalty = 20;
    }

    setState(() {
      score = max(0, score - penalty);
    });
  }

  // handles when player taps on a cell to place or move their token
  void _onCellTap(int index) {
    if (gameover) return;
    if (!_symbolchosen) return;
    if (currentturn != player.human) return;

    // for placing new tokens (first 5 moves)
    if (humantoken.length < maxtoken) {
      if (board[index] != Cell.empty) return;

      setState(() {
        board[index] = humansymbol;
        humantoken.add(index);

        int id = _humannexttokenid;
        _humantokenidbycell[index] = id;
        if (_humannexttokenid < 5) {
          _humannexttokenid++;
        }

        humanmoves++;
        totalmoves++;
        _applyscorepenalty();
      });
    } else {
      // this is for moving the oldest token when all 5 tokens are placed
      if (board[index] != Cell.empty) return;

      int fromIndex = humantoken.removeAt(0);

      setState(() {
        int id = _humantokenidbycell[fromIndex] ?? 1;

        board[fromIndex] = Cell.empty;
        _humantokenidbycell.remove(fromIndex);

        board[index] = humansymbol;
        humantoken.add(index);
        _humantokenidbycell[index] = id;

        humanmoves++;
        totalmoves++;
        _applyscorepenalty();
      });
    }

    Cell? win = _checkwinner();
    if (win != null) {
      _finishGame(win);
      return;
    }

    setState(() {
      currentturn = player.bot;
    });

    Future.delayed(const Duration(milliseconds: 400), _botmove);
  }

  // for making the bot take its turn
  void _botmove() {
    if (gameover) return;

    final mv = _botEngine.chooseMove(
      board: board,
      botTokens: bottoken,
      humanTokens: humantoken,
      botSymbol: botsymbol,
      humanSymbol: humansymbol,
      maxTokens: maxtoken,
      boardSize: size,
      botMoves: botmoves,
      totalMoves: totalmoves,
      score: score,
    );

    if (mv.$1 == -1 && mv.$2 == -1) {
      _finishGame(null);
      return;
    }

    botmoves++;
    totalmoves++;

    setState(() {
      // this handles bot placing or moving tokens
      int from = mv.$1;
      int to = mv.$2;

      if (from == -1) {
        board[to] = botsymbol;
        bottoken.add(to);

        int id = _botnexttokenid;
        _bottokenidbycell[to] = id;
        if (_botnexttokenid < 5) {
          _botnexttokenid++;
        }
      } else {
        board[from] = Cell.empty;

        int id = _bottokenidbycell[from] ?? 1;
        _bottokenidbycell.remove(from);

        board[to] = botsymbol;

        int idx = bottoken.indexOf(from);
        if (idx >= 0) {
          bottoken.removeAt(idx);
        } else if (bottoken.isNotEmpty) {
          bottoken.removeAt(0);
        }
        bottoken.add(to);

        _bottokenidbycell[to] = id;
      }
    });

    Cell? win = _checkwinner();
    if (win != null) {
      _finishGame(win);
      return;
    }

    if (!gameover) {
      setState(() {
        currentturn = player.human;
      });
    }
  }

  // gets the correct texture image for each token based on its ID
  ImageProvider _getTextureFor(Cell symbol, int boardIndex) {
    bool isHumanToken = (symbol == humansymbol);
    final map =
        isHumanToken ? _humantokenidbycell : _bottokenidbycell;

    int tokenId = map[boardIndex] ?? 1;
    String suffix = (symbol == Cell.X) ? "x" : "o";

    return AssetImage("assets/textures/puck${tokenId}${suffix}.png");
  }

  Widget _buildCellImage(int index) {
    Cell cell = board[index];
    if (cell == Cell.empty) {
      return const SizedBox.shrink();
    }

    return Image(
      image: _getTextureFor(cell, index),
      fit: BoxFit.contain,
    );
  }

  String _buildTurnText() {
    if (gameover) {
      if (winner == null) {
        return 'Draw';
      } else {
        if (winner == humansymbol) {
          return 'You Won!';
        } else {
          return 'Bot Won';
        }
      }
    } else {
      if (!_symbolchosen) {
        return 'Choose X or O to start';
      } else {
        if (currentturn == player.human) {
          return 'Your turn';
        } else {
          return 'Bot is thinking...';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFEDE8D0);
    final turnText = _buildTurnText();

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
                        const Text('Tic Tac Four', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _showAbandonConfirmation('Restart game?', 'restart', _resetgame);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          turnText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Score: $score'),
                        const SizedBox(height: 4),
                        Text('Your moves: $humanmoves   |   Bot moves: $botmoves'),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: GridView.builder(
                                itemCount: size * size,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: size,
                                ),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _onCellTap(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black54),
                                      ),
                                      child: Center(
                                        child: _buildCellImage(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                        ),
                      ],
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
                            _showAbandonConfirmation('Leaving the game?', 'go home', () {
                              Navigator.of(context).pop();
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.leaderboard),
                          title: const Text('Leaderboard'),
                          onTap: () {
                            _closeTopMenu();
                            _showAbandonConfirmation('Leaving the game?', 'view leaderboard', () {
                              Navigator.of(context).pushNamed('/leaderboard');
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Log out'),
                          onTap: () {
                            _closeTopMenu();
                            _showAbandonConfirmation('Leaving the game?', 'log out', () async {
                              await AuthService.instance.signOut();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const StartPage()),
                                (route) => false,
                              );
                            });
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