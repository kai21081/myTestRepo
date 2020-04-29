import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/gameplay_database.dart';
import 'package:gameplayground/models/session.dart';
import 'package:gameplayground/models/users.dart';
import 'package:gameplayground/models/surface_emg_game_database.dart';


class SessionDataModel extends ChangeNotifier {
  User _user;
  Session _session;
  final SurfaceEmgGameDatabase _database;

  SessionDataModel(this._database);

  String get currentUserId => _user.id;

  // Creates a _Session with the provided start time. Should maybe check to make
  // sure there isn't already a current session.
  void startSession(int startTime) {
    _session = Session(startTime);
  }

  // Get all users from User Database.
  UnmodifiableListView<User> getUsers() {
    return _database.getUserData();
  }

  // Checks if user already exists with same ID.
  Future<bool> canAddUser(User user) async {
    return _database.containsUserWithId(user.id);
  }

  // Adds user to User Database.
  void createUser(String id) {
    _database.createUserIfAbsent(id);
    notifyListeners();
  }

  // Deletes user from User Database.
  void deleteUser(String id) {
    _database.deleteUser(id);
    notifyListeners();
  }

  // Set the user as the current user.
  // Verify it is one of the possible users.
  void setUser(String id) {
    _user = _database.getUserWithId(id);
  }

  // User must be set.
  // Adds a row to the Gameplay Database.
  // Updates high score if indicated.
  //
  // Need to define a GameplayData class that holds:
  //  - Game ID (timestamp of game start, or something else)
  //  - Game Start (timestamp of game start)
  //  - Game End (timestamp of game end)
  //  - Game Score (int of score of game)
  //  - Activation Count (int of number of "muscle activations")
  //  - App Version (some identifier of app (or sensor stuff))
  //  - Sensor Data Path (how will this be generated?)
  //
  // In addition to these values, it will use this class's _User and _Session to
  // add:
  //  - Session ID
  //  - User ID
  void handleGameplayData(GameplayData gameplayData) {
    _database.insertDataFromSingleGame(
        gameplayData.startTime, gameplayData.endTime, _user.id,
        gameplayData.score);
  }
}