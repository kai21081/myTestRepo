import 'dart:collection';
import 'package:flutter/foundation.dart';

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

class UsersModel extends ChangeNotifier {
  final List<User> _users = [
    User('Jacob', 100, 0),
  ];

  UnmodifiableListView<User> get users => UnmodifiableListView(_users);

  void add(User user) {
    _users.add(user);
    notifyListeners();
  }
}