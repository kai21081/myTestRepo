
class GameplayData {
  final int startTime;
  final int endTime;
  final int score;
  final int numFlaps;

  GameplayData(this.startTime, this.endTime, this.score, this.numFlaps);

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'numFlaps':numFlaps,
    };
  }
}
