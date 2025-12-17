import 'dart:math';
import 'cell.dart';

class BotMoveEngine {
  final Random _rng = Random();

  // this function finds all the legal moves that can be made
  List<(int from, int to)> _legalMoves(
    List<Cell> board,
    List<int> tokens,
    int maxTokens,
  ) {
    List<(int, int)> moves = [];

    if (tokens.length < maxTokens) {
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Cell.empty) {
          moves.add((-1, i));
        }
      }
    } else {
      int from = tokens.first;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Cell.empty) {
          moves.add((from, i));
        }
      }
    }
    return moves;
  }

  // for simulating a move on a copy of the board without changing the real board
  void _applyMoveSim(
    Cell symbol,
    List<Cell> simBoard,
    List<int> simTokens,
    (int from, int to) mv,
  ) {
    int from = mv.$1;
    int to = mv.$2;

    if (from == -1) {
      simBoard[to] = symbol;
      simTokens.add(to);
    } else {
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

  // checks winner on simulated board, same logic as main game
  Cell? _checkWinnerSim(List<Cell> board, int size) {
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

  // this is for scoring the board position to see if its good for bot or player
  // higher score means better for bot
  int _evaluateBoard(
    List<Cell> board,
    int size,
    Cell botSymbol,
    Cell humanSymbol,
  ) {
    int botScore = 0;
    int humanScore = 0;

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
      int botCount = 0;
      int humanCount = 0;

      for (int idx in line) {
        if (board[idx] == botSymbol) botCount++;
        if (board[idx] == humanSymbol) humanCount++;
      }

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

  // this is the main AI function that picks the best move for bot
  // it tries to win, blocks player from winning, and sometimes makes mistakes on purpose
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

    // for making bot make mistakes sometimes so its not too hard
    bool shouldBlunder = (botMoves % blunderFreq == 0);

    if (!shouldBlunder) {
      // check if bot can win in this move
      for (var mv in moves) {
        List<Cell> simBoard = List<Cell>.from(board);
        List<int> simBotTokens = List<int>.from(botTokens);

        _applyMoveSim(botSymbol, simBoard, simBotTokens, mv);
        if (_checkWinnerSim(simBoard, boardSize) == botSymbol) {
          return mv;
        }
      }

      // this part checks if a move lets player win on next turn
      List<(int, int)> safeMoves = [];
      for (var mv in moves) {
        List<Cell> afterBoard = List<Cell>.from(board);
        List<int> afterBotTokens = List<int>.from(botTokens);
        List<int> afterHumanTokens = List<int>.from(humanTokens);

        _applyMoveSim(botSymbol, afterBoard, afterBotTokens, mv);

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

      final candidates = safeMoves.isNotEmpty ? safeMoves : moves;

      // for finding the move with highest score
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

    // return random move when bot should blunder
    return moves[_rng.nextInt(moves.length)];
  }
}
