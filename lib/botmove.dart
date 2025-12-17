// lib/botmove.dart
import 'dart:math';
import 'cell.dart';


class BotMoveEngine {
  // random number generator
  final Random _rng = Random();

  // index for legal moves
  List<(int from, int to)> _legalMoves(
    List<Cell> board,
    List<int> tokens,
    int maxTokens,
  ) {
    List<(int, int)> moves = [];

    if (tokens.length < maxTokens) {
      // Place a new token in any empty cell
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Cell.empty) {
          moves.add((-1, i));
        }
      }
    } else {
      // Move the oldest token
      int from = tokens.first;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Cell.empty) {
          moves.add((from, i));
        }
      }
    }
    return moves;
  }

  // simulate move on simulated board
  void _applyMoveSim(
    Cell symbol,
    List<Cell> simBoard,
    List<int> simTokens,
    (int from, int to) mv,
  ) {
    int from = mv.$1;
    int to = mv.$2;

    if (from == -1) {
      // place new
      simBoard[to] = symbol;
      simTokens.add(to);
    } else {
      // move
      simBoard[from] = Cell.empty;
      simBoard[to] = symbol;
      int idx = simTokens.indexOf(from);
      if (idx >= 0) {
        simTokens.removeAt(idx);
      } else if (simTokens.isNotEmpty) {
        simTokens.removeAt(0);
      }
      simTokens.add(to);
    }
  }

  // check winner on simulated board
  Cell? _checkWinnerSim(List<Cell> board, int size) {
    List<List<int>> lines = [];

    // Rows
    for (int r = 0; r < size; r++) {
      lines.add([r * size, r * size + 1, r * size + 2, r * size + 3]);
    }
    // Columns
    for (int c = 0; c < size; c++) {
      lines.add([c, c + size, c + 2 * size, c + 3 * size]);
    }
    // Diagonals win conditions
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

  // evaluate board position for bot
  int _evaluateBoard(
    List<Cell> board,
    int size,
    Cell botSymbol,
    Cell humanSymbol,
  ) {
    int botScore = 0;
    int humanScore = 0;

    List<List<int>> lines = [];

    // Rows 
    for (int r = 0; r < size; r++) {
      lines.add([r * size, r * size + 1, r * size + 2, r * size + 3]);
    }
    // Columns
    for (int c = 0; c < size; c++) {
      lines.add([c, c + size, c + 2 * size, c + 3 * size]);
    }
    // Diagonals win conditions
    lines.add([0, 5, 10, 15]);
    lines.add([3, 6, 9, 12]);

    for (var line in lines) {
      int botCount = 0;
      int humanCount = 0;

      for (int idx in line) {
        if (board[idx] == botSymbol) botCount++;
        if (board[idx] == humanSymbol) humanCount++;
      }

      // analyze current win condition
      if (botCount > 0 && humanCount > 0) continue;

      if (botCount > 0) {
        if (botCount == 4) botScore += 100000;
        else if (botCount == 3) botScore += 1000;
        else if (botCount == 2) botScore += 100;
        else if (botCount == 1) botScore += 10;
      }

      if (humanCount > 0) {
        if (humanCount == 4) humanScore += 100000;
        else if (humanCount == 3) humanScore += 1000;
        else if (humanCount == 2) humanScore += 100;
        else if (humanCount == 1) humanScore += 10;
      }
    }

    return botScore - humanScore;
  }

  // check and choose best move for bot
  (int from, int to) chooseMove({
    required List<Cell> board,
    required List<int> botTokens,
    required List<int> humanTokens,
    required Cell botSymbol,
    required Cell humanSymbol,
    required int maxTokens,
    required int boardSize,
    required int botMoves,
    required int totalMoves,
    required int score,
  }) {
    final moves = _legalMoves(board, botTokens, maxTokens);
    if (moves.isEmpty) return (-1, -1);

    // blunder frequency logic
    int blunderFreq;
    if (score <= 0) {
      blunderFreq = 2;
    } else if (totalMoves <= 20) {
      blunderFreq = 5;
    } else if (totalMoves <= 30) {
      blunderFreq = 4;
    } else {
      blunderFreq = 3;
    }

    // check blunder percentage
    bool shouldBlunder = (botMoves % blunderFreq == 0);

    // check blunder
    if (!shouldBlunder) {
      // check if bot can win
      for (var mv in moves) {
        List<Cell> simBoard = List<Cell>.from(board);
        List<int> simBotTokens = List<int>.from(botTokens);

        _applyMoveSim(botSymbol, simBoard, simBotTokens, mv);
        if (_checkWinnerSim(simBoard, boardSize) == botSymbol) {
          return mv;
        }
      }

      // simulate player moves, and tag it as unsafe
      List<(int, int)> safeMoves = [];
      for (var mv in moves) {
        List<Cell> afterBoard = List<Cell>.from(board);
        List<int> afterBotTokens = List<int>.from(botTokens);
        List<int> afterHumanTokens = List<int>.from(humanTokens);

        _applyMoveSim(botSymbol, afterBoard, afterBotTokens, mv);

        // check possible player move
        bool givesImmediateLoss = false;
        final humanMoves =
            _legalMoves(afterBoard, afterHumanTokens, maxTokens);

        for (var hm in humanMoves) {
          List<Cell> simBoard2 = List<Cell>.from(afterBoard);
          List<int> simHumanTokens2 = List<int>.from(afterHumanTokens);

          _applyMoveSim(humanSymbol, simBoard2, simHumanTokens2, hm);
          if (_checkWinnerSim(simBoard2, boardSize) == humanSymbol) {
            givesImmediateLoss = true;
            break;
          }
        }

        if (!givesImmediateLoss) {
          safeMoves.add(mv);
        }
      }

      // search for safe moves
      final candidates = safeMoves.isNotEmpty ? safeMoves : moves;

      // choose best move by evaluating board position
      int bestScore = -0x7fffffff;
      (int, int) bestMove = candidates.first;

      for (var mv in candidates) {
        List<Cell> simBoard = List<Cell>.from(board);
        List<int> simBotTokens = List<int>.from(botTokens);

        _applyMoveSim(botSymbol, simBoard, simBotTokens, mv);
        int eval = _evaluateBoard(simBoard, boardSize, botSymbol, humanSymbol);

        if (eval > bestScore) {
          bestScore = eval;
          bestMove = mv;
        }
      }

      return bestMove;
    }

    //return random move (blunder) 
    return moves[_rng.nextInt(moves.length)];
  }
}
