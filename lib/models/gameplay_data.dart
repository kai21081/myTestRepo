
class GameplayData {
  final int startTime;
  final int endTime;
  final int score;

  GameplayData(this.startTime, this.endTime, this.score);

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
    };
  }
}
