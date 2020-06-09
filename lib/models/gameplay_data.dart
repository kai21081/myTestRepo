import 'package:gameplayground/models/session.dart';
import 'package:gameplayground/models/users.dart';

class GameplayData {
  final int startTime;
  final int endTime;
  final int score;
  final int activationCount;
  final String appVersion;
  final String sensorDataPath;

  User _user;
  Session _session;

  GameplayData(this.startTime, this.endTime, this.score, this.activationCount,
      this.appVersion, this.sensorDataPath);

  void addUser(User user) {
    _user = user;
  }

  void addSession(Session session) {
    _session = session;
  }

  Map<String, dynamic> asMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'activationCount': activationCount,
      'appVersion': appVersion,
      'sensorDataPath': sensorDataPath
    };
  }
}
