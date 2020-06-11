import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:gameplayground/models/game_record_saving_utils.dart';
import 'package:gameplayground/models/game_settings.dart';

import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:gameplayground/models/users.dart';
import 'package:gameplayground/models/surface_emg_game_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SessionDataModel extends ChangeNotifier {
  static final String _jsonExtension = '.json';

  User _currentUser;
  final SurfaceEmgGameDatabase _database;
  GameSettings _gameSettings;

  SessionDataModel(this._database);

  String get currentUserId => _currentUser.id;

  int get currentUserHighScore => _currentUser.highScore;

  GameSettings get gameSettings => _gameSettings;

  void updateGameSettings(GameSettings settings) {
    _gameSettings = settings;
    _database.updateUserGameSettings(
        currentUserId, _gameSettings.userModifiableSettings);
  }

  // Get all users from User Database.
  Future<UnmodifiableListView<User>> getUsers() async {
    return _database.getUserData();
  }

  // Checks if user already exists with same ID. Returns false if exists.
  Future<bool> canAddUser(User user) async {
    return _database.containsUserWithId(user.id).then((value) => !value);
  }

  // Adds user to User Database with default user modifiable settings.
  Future<void> createUser(String id) async {
    await _database.createUserIfAbsent(
        id, GameSettings().userModifiableSettings);
    notifyListeners();
  }

  // Deletes user from User Database.
  void deleteUser(String id) async {
    await _database.deleteUser(id);
    notifyListeners();
  }

  // Set the user as the current user.
  // Verify it is one of the possible users.
  Future<void> setUser(String id) async {
    _currentUser = await _database.getUserWithId(id);
    _gameSettings = GameSettings.withUserModifiableSettings(
        await _database.getUserSettings(id));
    _database.updateUserMostRecentActivity(
        id, DateTime.now().millisecondsSinceEpoch);
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
  void handleGameplayData(GameplayData gameplayData, GameSettings gameSettings,
      UnmodifiableListView<ProcessedDataPoint> emgData) async {
    _database.insertDataFromSingleGame(gameplayData.startTime,
        gameplayData.endTime, _currentUser.id, gameplayData.score);
    _currentUser = await _database.getUserWithId(_currentUser.id);

    final supportDirectory = await getApplicationSupportDirectory();
    final String savePath = path.join(
        supportDirectory.path,
        _makeTimestampIdFilename(gameplayData.startTime, _currentUser.id) +
            _jsonExtension);

    saveGameRecord(_currentUser.id, gameSettings, emgData, gameplayData, savePath);
  }

  void handleCalibrationData(int value) {
    _database.addCalibrationValue(
        _currentUser.id, value, DateTime.now().millisecondsSinceEpoch);
  }
}

String _makeTimestampIdFilename(int timestamp, String id) {
  return 'timestamp_${timestamp}_user_$id';
}
