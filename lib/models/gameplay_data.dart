
class GameplayData {
  final int startTime;
  final int endTime;
  final int score;
  final int numFlaps;
  final String emgRecordingPath;
  final String deviceName;

  GameplayData(this.startTime, this.endTime, this.score, this.numFlaps, this.emgRecordingPath,this.deviceName);

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'numFlaps':numFlaps,
      'savePath':emgRecordingPath,
      'deviceName':deviceName
    };
  }
}
