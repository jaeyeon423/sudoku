import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_record.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<GameRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recordsJson = prefs.getStringList('sudoku_stats') ?? [];

    setState(() {
      _records = recordsJson
          .map((str) => GameRecord.fromJson(jsonDecode(str)))
          .toList()
          .reversed // Newest first
          .toList();
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String _getDifficultyText(int empty) {
    if (empty < 30) return "Easy";
    if (empty < 45) return "Medium";
    if (empty < 60) return "Hard";
    if (empty == 1) return "Test";
    return "Expert";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No games played yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.check, color: Colors.teal),
            ),
            title: Text(
              _getDifficultyText(record.difficulty),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${record.date.year}/${record.date.month}/${record.date.day} • Mistakes: ${record.mistakes}",
            ),
            trailing: Text(
              _formatDuration(record.durationSeconds),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
        );
      },
    );
  }
}
