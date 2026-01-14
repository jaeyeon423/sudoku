import 'package:flutter/material.dart';
import '../state/game_state.dart';
import 'game_screen.dart';
import 'statistics_screen.dart';
import '../widgets/banner_ad_widget.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  final GameController _tempController = GameController();
  bool _hasSave = false;
  bool _isLoading = true;

  // Use IndexedStack or just switch body
  final List<Widget> _screens = []; // Will init in initState

  @override
  void initState() {
    super.initState();
    debugPrint("MainMenuScreen initState");
    _checkSave();
  }

  Future<void> _checkSave() async {
    debugPrint("Checking for saved game...");
    try {
      final hasSave = await _tempController.hasSavedGame();
      debugPrint("Has saved game: $hasSave");
      if (mounted) {
        setState(() {
          _hasSave = hasSave;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking save: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshHome() async {
    debugPrint("Refreshing home...");
    await _checkSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Sudoku" : "Statistics",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _currentIndex == 0 ? _buildHomeView() : const StatisticsScreen(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 0)
                _checkSave(); // Refresh save status when going home
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: "Statistics",
              ),
            ],
            selectedItemColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grid_on, size: 100, color: Colors.teal),
          const SizedBox(height: 48),
          if (_hasSave)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(loadSaved: true),
                      ),
                    ).then((_) => _checkSave());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showDifficultyDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasSave ? Colors.white : Colors.teal,
                foregroundColor: _hasSave ? Colors.teal : Colors.white,
                side: _hasSave
                    ? const BorderSide(color: Colors.teal, width: 2)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text("New Game", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Select Difficulty"),
          children: [
            _buildDifficultyOption(context, "Easy", 25),
            _buildDifficultyOption(context, "Medium", 40),
            _buildDifficultyOption(context, "Hard", 55),
            _buildDifficultyOption(context, "Expert", 64), // Very few hints
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
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(difficulty: emptyCells),
          ),
        ).then((_) => _checkSave());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(label),
      ),
    );
  }
}
