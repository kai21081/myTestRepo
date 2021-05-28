import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gameplayground/models/bluetooth_manager.dart';
import 'package:gameplayground/models/emg_recording.dart';
import 'package:gameplayground/models/emg_sample.dart';
import 'package:gameplayground/models/game_record_saving_utils.dart';
import 'package:gameplayground/models/game_settings.dart';

import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:gameplayground/models/user.dart';
import 'package:gameplayground/models/surface_emg_game_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'calibration_data.dart';

class SessionDataModel extends ChangeNotifier {
  static final String _jsonExtension = '.json';

  User _currentUser;
  final SurfaceEmgGameDatabase _database;
  final BluetoothManager bluetoothManager;
  GameSettings _gameSettings;

  SessionDataModel(this._database, this.bluetoothManager);

  User get currentUser => _currentUser;

  String get currentUserId => _currentUser.id;

  int get currentUserHighScore => _currentUser.highScore;

  String get currentUserDeviceName => _currentUser.deviceName;

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

  //Added this method for use in the gameplay data screen
  Future<User> getUser(String id) async {
    return _database.getUserWithId(id);
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

  Future<UnmodifiableListView<GameplayData>> getUserGameplayData(User user) async{
    return _database.getOneUserData(user);
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
  //  - Number of Flaps (int of number of "muscle activations")
  //  - App Version (some identifier of app (or sensor stuff))
  //  - Sensor Data Path (how will this be generated?)
  //
  // In addition to these values, it will use this class's _User and _Session to
  // add:
  //  - Session ID
  //  - User ID

  // Writes general data about the game to a database. Writes game results and
  // EMG sensor data to file on disk.
  //
  // Returns a future that is fulfilled when database write is completed.
  Future<void> handleGameplayData(
      GameplayData gameplayData,
      GameSettings gameSettings,
      EmgRecording emgRecording) async {
    Directory supportDirectory = await getApplicationSupportDirectory();

    final String savePath = path.join(
          supportDirectory.path,
          _makeTimestampIdFilename(gameplayData.startTime, _currentUser.id) +
              _jsonExtension);

    gameplayData = new GameplayData(gameplayData.startTime, gameplayData.endTime,
        gameplayData.score, gameplayData.numFlaps,savePath);

    Future<void> databaseWriteAndUserUpdateFuture = _database
        .insertDataFromSingleGame(gameplayData.startTime, gameplayData.endTime,
        _currentUser.id, gameplayData.score, gameplayData.numFlaps,gameplayData.emgRecordingPath).then((_) async {
      _currentUser = await _database.getUserWithId(_currentUser.id);
    });

    saveGameRecord(
          _currentUser.id, gameSettings, emgRecording, gameplayData, savePath);

    return databaseWriteAndUserUpdateFuture;
  }

  Future<UserCalibrationData> getMostRecentCurrentUserCalibrationValue() async {
    return _database.getMostRecentUserCalibrationValue(currentUserId);
  }

  Future<void> handleCalibrationData(int value) {
    return _database.addCalibrationValue(
        _currentUser.id, value, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> handleDeviceName(String deviceName) {
    return _database
        .updateDeviceNameForUser(_currentUser.id, deviceName)
        .then((_) async {
      _currentUser = await _database.getUserWithId(_currentUser.id);
    });
  }
}

String _makeTimestampIdFilename(int timestamp, String id) {
  return 'timestamp_${timestamp}_user_$id';
}
