
class GameplayData {
  final int startTime;
  final int endTime;
  final int score;
  final int flaps;

  GameplayData(this.startTime, this.endTime, this.score, this.flaps);

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'flaps': flaps,
    };
  }
}
