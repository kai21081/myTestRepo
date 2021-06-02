import 'dart:math';

class User {
  final String _id;
  int highScore;
  int dailyHighScore;
  int mostRecentActivityTimestamp;
  int lastLevelCompleted = 1;
  String _deviceName;

  User(this._id, this.highScore, this.dailyHighScore, this.lastLevelCompleted, this.mostRecentActivityTimestamp,
      this._deviceName);

  String get id => _id;

  int getDailyHighScore() {
    var now = DateTime.now();
    var lastPlayed = DateTime.fromMillisecondsSinceEpoch(mostRecentActivityTimestamp);
    if (now.difference(lastPlayed).inDays.abs() < 1) {
      return dailyHighScore;
    } else {
      return 0;
    }
  }

  String get deviceName => _deviceName;

  List updateScores(int score) {
    var scoreList = [false, false];
    if (score > highScore) {
      highScore = score;
      scoreList[0] = true;
    }
    if (score > dailyHighScore) {
      dailyHighScore = score;
      scoreList[1] = true;
    }
    return scoreList;
  }
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('User $_id, High Score: $highScore');
    buffer.write(', Device Name: ');
    buffer.write(_deviceName == null ? 'none' : '$_deviceName');
    buffer.write('Last Level Completed: $lastLevelCompleted');
    buffer.write('Daily High Score: $dailyHighScore');
    buffer.write('.');
    return buffer.toString();
  }
}
