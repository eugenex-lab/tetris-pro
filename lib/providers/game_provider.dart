import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/block.dart';

class GameProvider with ChangeNotifier {
  List<List<Color?>> grid = List.generate(
    AppConstants.gridRows,
    (_) => List.filled(AppConstants.gridColumns, null),
  );

  Block? currentBlock;
  Block? nextBlock;
  Block? holdBlock;
  bool canHold = true;

  // Audio callback
  void Function(String)? onSoundTrigger;

  Block? get ghostBlock {
    if (currentBlock == null) return null;

    // Clone current block
    Block ghost = Block(
      shape: currentBlock!.shape,
      color: currentBlock!.color,
      type: currentBlock!.type,
      x: currentBlock!.x,
      y: currentBlock!.y,
    );

    // Drop it to the bottom
    while (_isValidMove(ghost)) {
      ghost.y += 1;
    }
    ghost.y -= 1; // Step back to valid position

    return ghost;
  }

  bool isGameOver = false;
  bool isPaused = false;
  bool showContinueDialog = false;
  int score = 0;
  int highScore = 0;
  int level = 1;
  int lives = 3;
  int continuesRemaining = 3;
  int coins = 100;
  int linesClearedTotal = 0;
  int _lastLevelUpLines = 0;
  bool showGhostPiece = true;
  bool hapticsEnabled = true;

  int get linesUntilNextLevel {
    int linesNeeded = 10;
    int progress = linesClearedTotal - _lastLevelUpLines;
    int remaining = linesNeeded - progress;
    return remaining > 0 ? remaining : 0;
  }

  Timer? _timer;
  Duration _speed = const Duration(milliseconds: 800);

  GameProvider() {
    _loadData();
    _generateNextBlock();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('high_score') ?? 0;
    coins = prefs.getInt('coins') ?? 100;
    showGhostPiece = prefs.getBool('show_ghost_piece') ?? true;
    hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('high_score', highScore);
    }
    await prefs.setInt('coins', coins);
    await prefs.setBool('show_ghost_piece', showGhostPiece);
    await prefs.setBool('haptics_enabled', hapticsEnabled);
  }

  void startGame() {
    _resetGame();
    _spawnBlock();
    _startTimer();
    notifyListeners();
  }

  void pauseGame() {
    isPaused = !isPaused;
    if (isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void restartGame() {
    startGame();
  }

  void _resetGame() {
    grid = List.generate(
      AppConstants.gridRows,
      (_) => List.filled(AppConstants.gridColumns, null),
    );
    score = 0;
    level = 1;
    lives = 3;
    continuesRemaining = 3;
    linesClearedTotal = 0;
    _lastLevelUpLines = 0;
    _speed = const Duration(milliseconds: 800);
    isGameOver = false;
    isPaused = false;
    showContinueDialog = false;
    currentBlock = null;
    holdBlock = null;
    canHold = true;
    _generateNextBlock();
  }

  void _generateNextBlock() {
    final random = Random();
    final keys = AppConstants.tetrominos.keys.toList();
    final type = keys[random.nextInt(keys.length)];
    final shape = AppConstants.tetrominos[type]!;
    final color = AppConstants.kBlockColors[type] ?? Colors.white;

    nextBlock = Block(shape: shape, color: color, type: type);
  }

  void _spawnBlock() {
    currentBlock = nextBlock;
    _generateNextBlock();
    canHold = true;

    if (currentBlock != null) {
      currentBlock!.x =
          (AppConstants.gridColumns - currentBlock!.shape[0].length) ~/ 2;
      currentBlock!.y = 0;

      if (!_isValidMove(currentBlock!)) {
        onSoundTrigger?.call('gameOver');
        finalGameOver();
      }
    }
    notifyListeners();
  }

  void gameOver() {
    finalGameOver();
  }

  // Called when player fails but has continues left
  void pauseForContinue() {
    showContinueDialog = true;
    isPaused = true;
    _timer?.cancel();
    notifyListeners();
  }

  // Called after rewarded ad completes
  void continueGame() {
    if (continuesRemaining > 0) {
      continuesRemaining--;
      showContinueDialog = false;

      // Clear bottom 5 rows for breathing room
      for (
        int r = AppConstants.gridRows - 1;
        r >= AppConstants.gridRows - 5;
        r--
      ) {
        grid[r] = List.filled(AppConstants.gridColumns, null);
      }

      isPaused = false;
      _spawnBlock();
      _startTimer();
      notifyListeners();
    }
  }

  // Called when player gives up or runs out of continues
  void finalGameOver() {
    isGameOver = true;
    showContinueDialog = false;
    continuesRemaining = 0;
    _timer?.cancel();
    _saveData();
    notifyListeners();
  }

  void toggleGhostPiece() {
    showGhostPiece = !showGhostPiece;
    _saveData();
    notifyListeners();
  }

  void toggleHaptics() {
    hapticsEnabled = !hapticsEnabled;
    _saveData();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    highScore = 0;
    coins = 100;
    showGhostPiece = true;
    hapticsEnabled = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Reset everything
    _resetGame();
    notifyListeners();
  }

  // Legacy revive method for coin-based revive (keep for backwards compatibility)
  void revive() {
    if (coins >= 50) {
      coins -= 50;
      continueGame();
      _saveData();
    }
  }

  // Called when player watches an ad to earn coins
  void addRewardCoins(int amount) {
    coins += amount;
    _saveData();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_speed, (timer) {
      if (!isPaused && !isGameOver) {
        moveDown();
      }
    });
  }

  bool _isValidMove(Block block) {
    for (int r = 0; r < block.shape.length; r++) {
      for (int c = 0; c < block.shape[r].length; c++) {
        if (block.shape[r][c] == 1) {
          int newX = block.x + c;
          int newY = block.y + r;

          if (newX < 0 ||
              newX >= AppConstants.gridColumns ||
              newY >= AppConstants.gridRows) {
            return false;
          }

          if (newY >= 0 && grid[newY][newX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void moveDown() {
    if (currentBlock == null) return;

    currentBlock!.y += 1;
    if (!_isValidMove(currentBlock!)) {
      currentBlock!.y -= 1;
      _lockBlock();
    } else {
      notifyListeners();
    }
  }

  void moveLeft() {
    if (currentBlock == null || isPaused || isGameOver) return;
    currentBlock!.x -= 1;
    if (!_isValidMove(currentBlock!)) {
      currentBlock!.x += 1;
    }
    notifyListeners();
  }

  void moveRight() {
    if (currentBlock == null || isPaused || isGameOver) return;
    currentBlock!.x += 1;
    if (!_isValidMove(currentBlock!)) {
      currentBlock!.x -= 1;
    }
    notifyListeners();
  }

  void rotateBlock() {
    if (currentBlock == null || isPaused || isGameOver) return;

    List<List<int>> oldShape = currentBlock!.shape
        .map((row) => List<int>.from(row))
        .toList();
    currentBlock!.rotate();

    if (!_isValidMove(currentBlock!)) {
      currentBlock!.x -= 1;
      if (!_isValidMove(currentBlock!)) {
        currentBlock!.x += 2;
        if (!_isValidMove(currentBlock!)) {
          currentBlock!.x -= 1;
          currentBlock!.shape = oldShape;
        }
      }
    }
    notifyListeners();
  }

  void dropBlock() {
    if (currentBlock == null || isPaused || isGameOver) return;
    while (_isValidMove(currentBlock!)) {
      currentBlock!.y += 1;
    }
    currentBlock!.y -= 1;
    _lockBlock();
  }

  void hold() {
    if (!canHold || isPaused || isGameOver) return;

    if (holdBlock == null) {
      holdBlock = currentBlock;
      _spawnBlock();
    } else {
      Block temp = holdBlock!;
      holdBlock = currentBlock;
      currentBlock = temp;
      currentBlock!.x =
          (AppConstants.gridColumns - currentBlock!.shape[0].length) ~/ 2;
      currentBlock!.y = 0;
    }
    canHold = false;
    notifyListeners();
  }

  void _lockBlock() {
    for (int r = 0; r < currentBlock!.shape.length; r++) {
      for (int c = 0; c < currentBlock!.shape[r].length; c++) {
        if (currentBlock!.shape[r][c] == 1) {
          int finalX = currentBlock!.x + c;
          int finalY = currentBlock!.y + r;

          if (finalY >= 0 && finalY < AppConstants.gridRows) {
            grid[finalY][finalX] = currentBlock!.color;
          }
        }
      }
    }

    _clearLines();
    _spawnBlock();
  }

  void _clearLines() {
    int linesCleared = 0;

    for (int r = AppConstants.gridRows - 1; r >= 0; r--) {
      bool isFull = true;
      for (int c = 0; c < AppConstants.gridColumns; c++) {
        if (grid[r][c] == null) {
          isFull = false;
          break;
        }
      }

      if (isFull) {
        grid.removeAt(r);
        grid.insert(0, List.filled(AppConstants.gridColumns, null));
        linesCleared++;
        r++;
      }
    }

    if (linesCleared > 0) {
      onSoundTrigger?.call('lineClear');
      linesClearedTotal += linesCleared;

      int points = 0;
      switch (linesCleared) {
        case 1:
          points = 100;
          break;
        case 2:
          points = 300;
          break;
        case 3:
          points = 500;
          break;
        case 4:
          points = 800;
          break;
      }
      score += points * level;

      coins += linesCleared * 2;

      // Level up logic: every 10 lines
      if (linesClearedTotal - _lastLevelUpLines >= 10) {
        level++;
        _lastLevelUpLines = (linesClearedTotal ~/ 10) * 10;
        int newSpeed = max(100, 800 - (level * 50));
        _speed = Duration(milliseconds: newSpeed);
        _startTimer();
      }

      notifyListeners();
    }
  }
}
