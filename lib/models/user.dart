class User {
  final String _id;
  int highScore;
  int mostRecentActivityTimestamp;
  int lastLevelCompleted = 1;
  String _deviceName;

  User(this._id, this.highScore, this.lastLevelCompleted, this.mostRecentActivityTimestamp,
      this._deviceName);

  String get id => _id;

  String get deviceName => _deviceName;

  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('User $_id, High Score: $highScore');
    buffer.write(', Device Name: ');
    buffer.write(_deviceName == null ? 'none' : '$_deviceName');
    buffer.write('Last Level Completed: $lastLevelCompleted');
    buffer.write('.');
    return buffer.toString();
  }
}
