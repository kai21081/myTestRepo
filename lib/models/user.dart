
class User {
  final String _id;
  int highScore;
  int mostRecentActivityTimestamp;

  User(this._id, this.highScore, this.mostRecentActivityTimestamp);

  String get id => _id;

  String toString() {
    return 'User $_id, High Score: $highScore.';
  }
}