class User {
  final String _id;
  int highScore;
  int mostRecentActivityTimestamp;
  String _deviceName;

  User(this._id, this.highScore, this.mostRecentActivityTimestamp,
      this._deviceName);

  String get id => _id;

  String get deviceName => _deviceName;

  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('User $_id, High Score: $highScore');
    buffer.write(', Device Name: ');
    buffer.write(_deviceName == null ? 'none' : '$_deviceName');
    buffer.write('.');
    return buffer.toString();
  }
}
