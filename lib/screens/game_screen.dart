import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../logic/ad_manager.dart';
import '../widgets/banner_ad_widget.dart'; // Import

class GameScreen extends StatefulWidget {
  final int? difficulty;
  final bool loadSaved;

  const GameScreen({super.key, this.difficulty, this.loadSaved = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final AdManager _adManager; // AdManager
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _adManager = AdManager(); // Init
    _adManager.loadRewardedAd(); // Load Ad

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.loadSaved) {
        _controller.loadGame().then((success) {
          if (!success && mounted) {
            _controller.startNewGame(difficultyLevel: widget.difficulty);
          }
        });
      } else if (widget.difficulty != null) {
        _controller.startNewGame(difficultyLevel: widget.difficulty);
      }
    });

    _controller.addListener(_onGameStatusChanged);
  }
  // ... (rest of file until dispose)

  void _onGameStatusChanged() {
    if (_controller.status == GameStatus.won && !_isDialogShowing) {
      _showWonDialog();
    } else if (_controller.status == GameStatus.lost && !_isDialogShowing) {
      _showLostDialog();
    }
  }

  void _showWonDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Congratulations!"),
        content: Text("You solved the puzzle in ${_controller.timeString}!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _isDialogShowing = false;
              _showNewGameDialog();
            },
            child: const Text("New Game"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop screen to go back to Main Menu
              _isDialogShowing = false;
            },
            child: const Text("Main Menu"),
          ),
        ],
      ),
    );
  }

  void _showLostDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("You made too many mistakes (3/3)."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _isDialogShowing = false;
              _showNewGameDialog();
            },
            child: const Text("New Game"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Back to menu
              _isDialogShowing = false;
            },
            child: const Text("Main Menu"),
          ),
        ],
      ),
    );
  }

  void _showNewGameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("New Game"),
          children: [
            _buildDifficultyOption(context, "Easy", 25),
            _buildDifficultyOption(context, "Medium", 40),
            _buildDifficultyOption(context, "Hard", 55),
            _buildDifficultyOption(context, "Expert", 64),
          ],
        );
      },
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String label,
    int emptyCells,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        _controller.startNewGame(difficultyLevel: emptyCells);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameStatusChanged);
    _controller.dispose();
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sudoku", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _showNewGameDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.board == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Difficulty",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _getDifficultyText(_controller.difficulty),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          const Text(
                            "Mistakes",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "${_controller.mistakes} / 3",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _controller.mistakes >= 3
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Time",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _controller.timeString,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SudokuGrid(controller: _controller),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: NumberPad(
                    isNoteMode: _controller.isNoteMode,
                    completedNumbers: _controller.completedNumbers,
                    canUndo: _controller.canUndo,
                    onNumberPressed: (num) => _controller.inputNumber(num),
                    onClearPressed: () => _controller.clearCell(),
                    onNotePressed: () => _controller.toggleNoteMode(),
                    onUndoPressed: () => _controller.undo(),
                    onHintPressed: () {
                      if (_controller.selectedCell == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Select a cell first to get a hint!"),
                          ),
                        );
                        return;
                      }

                      if (_adManager.isAdReady) {
                        _adManager.showRewardedAd(
                          onUserEarnedReward: (reward) {
                            if (!mounted) return;
                            _controller.useHint();
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Ad not ready yet. Try again in a moment.",
                            ),
                          ),
                        );
                        // Try loading again just in case
                        _adManager.loadRewardedAd();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const BannerAdWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDifficultyText(int empty) {
    if (empty < 30) return "Easy";
    if (empty < 45) return "Medium";
    if (empty < 60) return "Hard";
    return "Expert";
  }
}
