import 'dart:math';
import 'package:flutter/material.dart';

import 'cell.dart';
import 'botmove.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';

// player turn enum
enum player { human, bot }

// main Tic Tac Four game logic
class tictaclogic extends StatefulWidget {
  final Cell? initialSymbol;
  const tictaclogic({super.key, this.initialSymbol});

  @override
  State<tictaclogic> createState() => _tictaclogicState();
}

class _tictaclogicState extends State<tictaclogic> {
  // board size
  static const int size = 4;
  // max tokens per player
  static const int maxtoken = 5;

  // bot AI engine
  final BotMoveEngine _botEngine = BotMoveEngine();

  late List<Cell> board;

  Cell humansymbol = Cell.X;
  Cell botsymbol = Cell.O;

  // player token positions
  final List<int> humantoken = [];
  final List<int> bottoken = [];

  // token texture IDs (1-5)
  int _humannexttokenid = 1;
  int _botnexttokenid = 1;

  // token ID mapping by cell
  final Map<int, int> _humantokenidbycell = {};
  final Map<int, int> _bottokenidbycell = {};

  player currentturn = player.human;
  bool gameover = false;
  bool _symbolchosen = false;
  Cell? winner;

  // game timing
  DateTime? starttime;
  Duration? elapsedtime;

  // scoring - starts at 100
  int score = 100;
  int humanmoves = 0;
  int botmoves = 0;
  int totalmoves = 0;



  @override
  void initState() {
    super.initState();
    _resetgame();
  }

  // reset game state to initial
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

    // reset token ID
    _humannexttokenid = 1;
    _botnexttokenid = 1;
    _humantokenidbycell.clear();
    _bottokenidbycell.clear();

    // If an initial symbol was provided from GameHome, use it, otherwise ask
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSymbol != null) {
        _setsymbolsthenstart(widget.initialSymbol!);
      } else {
        _showsymbolchoicedialog();
      }
    });

    setState(() {});
  }

  // show symbol selection dialog
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

  // set player symbol and start game
  void _setsymbolsthenstart(Cell chosen) {
    setState(() {
      humansymbol = chosen;
      botsymbol = (chosen == Cell.X) ? Cell.O : Cell.X;

      // X always goes first
      currentturn = (humansymbol == Cell.X) ? player.human : player.bot;

      _symbolchosen = true;
      starttime = DateTime.now();
    });

    if (currentturn == player.bot) {
      Future.delayed(const Duration(milliseconds: 400), _botmove);
    }
  }

  // check for 4-in-row win condition
  Cell? _checkwinner() {
    List<List<int>> lines = [];

    // Rows win
    for (int r = 0; r < size; r++) {
      lines.add([r * size, r * size + 1, r * size + 2, r * size + 3]);
    }
    // Columns win
    for (int c = 0; c < size; c++) {
      lines.add([c, c + size, c + 2 * size, c + 3 * size]);
    }
    // Diagonals win
    lines.add([0, 5, 10, 15]); // left to right diagonal
    lines.add([3, 6, 9, 12]); // right to left diagonal

    for (var line in lines) {
      Cell a = board[line[0]];
      if (a == Cell.empty) continue;
      if (line.every((idx) => board[idx] == a)) {
        return a;
      }
    }
    return null;
  }

  // end game and show result dialog
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
                Navigator.of(context).pop(); // Go back to game home
              },
              child: const Text('Main Menu'),
            ),
          ],
        );
      },
    );

    // If human won and user is not guest, store score
    if (winnersymbol == humansymbol) {
      final auth = AuthService.instance;
      if (!auth.isGuest && auth.currentUser != null) {
        final nick = auth.currentUser!.displayName ?? auth.currentUser!.email?.split('@').first ?? 'Player';
        final t = elapsedtime?.inSeconds ?? 0;
        DBService.instance.saveScore(nickname: nick, score: score, timeSeconds: t);
      }
    }
  }

  // apply score penalty based on move count
  void _applyscorepenalty() {
    if (humanmoves <= 5) return; // no penalty for first 5 player moves

    int penalty;
    if (humanmoves <= 10) {
      penalty = 1; // moves 6-10
    } else if (humanmoves <= 20) {
      penalty = 2; // moves 11-20
    } else if (humanmoves <= 30) {
      penalty = 5; // moves 21-30
    } else if (humanmoves <= 40) {
      penalty = 10; // moves 31-40
    } else {
      penalty = 20; // moves 41+
    }

    setState(() {
      score = max(0, score - penalty);
    });
  }

  // handle human player move on cell
  void _onCellTap(int index) {
    if (gameover) return;
    if (!_symbolchosen) return;
    if (currentturn != player.human) return;

    // Place new token (first 5 tokens)
    if (humantoken.length < maxtoken) {
      if (board[index] != Cell.empty) return;

      setState(() {
        board[index] = humansymbol;
        humantoken.add(index);

        // Assign token ID 1..5 once; then stays fixed for that token
        int id = _humannexttokenid;
        _humantokenidbycell[index] = id;
        if (_humannexttokenid < 5) {
          _humannexttokenid++; // after 5, no new IDs
        }

        humanmoves++;
        totalmoves++;
        _applyscorepenalty();
      });
    } else {
      // Move oldest token (cycle 1,2,3,4,5,1,2,...)
      if (board[index] != Cell.empty) return;

      int fromIndex = humantoken.removeAt(0);

      setState(() {
        // Carry the same token ID
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

  // execute bot move decision
  void _botmove() {
    if (gameover) return;

    // Ask the AI engine for a move
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
      int from = mv.$1;
      int to = mv.$2;

      if (from == -1) {
        // Bot places new token
        board[to] = botsymbol;
        bottoken.add(to);

        int id = _botnexttokenid;
        _bottokenidbycell[to] = id;
        if (_botnexttokenid < 5) {
          _botnexttokenid++;
        }
      } else {
        // Bot moves token
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

  // get texture asset for token
  ImageProvider _getTextureFor(Cell symbol, int boardIndex) {
    bool isHumanToken = (symbol == humansymbol);
    final map =
        isHumanToken ? _humantokenidbycell : _bottokenidbycell;

    int tokenId = map[boardIndex] ?? 1;
    String suffix = (symbol == Cell.X) ? "x" : "o";

    return AssetImage("assets/textures/puck${tokenId}${suffix}.png");
  }

  // build cell image widget
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

  // build status text for current game state
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
    final turnText = _buildTurnText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Four'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetgame,
          ),
        ],
      ),
      body: Column(
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
            child: Text(
              '4 in a row wins. Each player has 5 tokens; after that, tokens move in order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
