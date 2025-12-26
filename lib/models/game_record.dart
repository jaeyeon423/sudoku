class GameRecord {
  final DateTime date;
  final int difficulty;
  final int durationSeconds;
  final int mistakes;

  GameRecord({
    required this.date,
    required this.difficulty,
    required this.durationSeconds,
    required this.mistakes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'difficulty': difficulty,
      'durationSeconds': durationSeconds,
      'mistakes': mistakes,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      date: DateTime.parse(json['date']),
      difficulty: json['difficulty'],
      durationSeconds: json['durationSeconds'],
      mistakes: json['mistakes'] ?? 0,
    );
  }
}
