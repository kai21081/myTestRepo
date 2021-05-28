
class GameplayData {
  final int startTime;
  final int endTime;
  final int score;
  final int numFlaps;
  final String emgRecordingPath;

  GameplayData(this.startTime, this.endTime, this.score, this.numFlaps, this.emgRecordingPath);

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'numFlaps':numFlaps,
      'savePath':emgRecordingPath
    };
  }
}
