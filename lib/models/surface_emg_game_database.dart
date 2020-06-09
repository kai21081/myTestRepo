import 'dart:collection';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gameplayground/models/game_settings.dart';
import 'package:gameplayground/models/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// TODO: If the database read is fast enough, don't cache, it's confusing.
class SurfaceEmgGameDatabase extends ChangeNotifier {
  final String _databaseFilename = 'surface_emg_game.db';

  final String _userDataDatabaseName = 'UserData';
  final String _calibrationDataDatabaseName = 'CalibrationData';
  final String _gameplayDataDatabaseName = 'GameplayData';

  final String _idColumnName = 'id';
  final String _idColumnType = 'TEXT';
  final String _highScoreColumnName = 'highScore';
  final String _highScoreColumnType = 'INTEGER';
  final String _mostRecentActivityTimestampColumnName =
      'mostRecentActivityTimestamp';
  final String _mostRecentActivityTimestampColumnType = 'INTEGER';

  final String _timestampMillisecondsSinceEpochColumnName =
      'timestampMillisecondsSinceEpoch';
  final String _timestampMillisecondsSinceEpochColumnType = 'INTEGER';
  final String _calibrationValueColumnName = 'calibrationValue';
  final String _calibrationValueColumnType = 'INTEGER';

  final String _gameStartTimestampColumnName = 'gameStartTimestamp';
  final String _gameStartTimestampColumnType = 'INTEGER';
  final String _gameEndTimestampColumnName = 'gameEndTimestamp';
  final String _gameEndTimestampColumnType = 'INTEGER';
  final String _gameUserIdColumnName = 'userId';
  final String _gameUserIdColumnType = 'TEXT';
  final String _gameScoreColumnName = 'score';
  final String _gameScoreColumnType = 'INTEGER';

  static const String flapVelocityInScreenHeightFractionPerSecondColumnName =
      'flapVelocityInScreenHeightFractionPerSecond';
  static const String flapVelocityInScreenHeightFractionPerSecondColumnType =
      'REAL';
  static const String
      terminalVelocityInScreenHeightFractionPerSecondColumnName =
      'terminalVelocityInScreenHeightFractionPerSecond';
  static const String
      terminalVelocityInScreenHeightFractionPerSecondColumnType = 'REAL';
  static const String scrollVelocityInScreenWidthsPerSecondColumnName =
      'scrollVelocityInScreenWidthsPerSecond';
  static const String scrollVelocityInScreenWidthsPerSecondColumnType = 'REAL';
  static const String includeCherriesColumnName = 'includeCherries';
  static const String includeCherriesColumnType = 'INTEGER';
  static const String cherrySpawnRatePerSecondColumnName =
      'cherrySpawnRatePerSecond';
  static const String cherrySpawnRatePerSecondColumnType = 'REAL';
  static const String cherryWidthAsScreenWidthFractionColumnName =
      'cherryWidthAsScreenWidthFraction';
  static const String cherryWidthAsScreenWidthFractionColumnType = 'REAL';
  static const String cherryHeightAsScreenWidthFractionColumnName =
      'cherryHeightAsScreenWidthFraction';
  static const String cherryHeightAsScreenWidthFractionColumnType = 'REAL';
  static const String cherryFractionWidthForCollisionColumnName =
      'cherryFractionWidthForCollision';
  static const String cherryFractionWidthForCollisionColumnType = 'REAL';
  static const String cherryFractionHeightForCollisionColumnName =
      'cherryFractionHeightForCollision';
  static const String cherryFractionHeightForCollisionColumnType = 'REAL';
  static const String cherryLocationMinBoundFromScreenTopColumnName =
      'cherryLocationMinBoundFromScreenTop';
  static const String cherryLocationMinBoundFromScreenTopColumnType = 'REAL';
  static const String cherryLocationMaxBoundFromScreenTopColumnName =
      'cherryLocationMaxBoundFromScreenTop';
  static const String cherryLocationMaxBoundFromScreenTopColumnType = 'REAL';
  static const String includeColumnsColumnName = 'includeColumns';
  static const String includeColumnsColumnType = 'INTEGER';
  static const String columnSpawnRatePerSecondColumnName =
      'columnSpawnRatePerSecond';
  static const String columnSpawnRatePerSecondColumnType = 'REAL';
  static const String columnWidthAsScreenWidthFractionColumnName =
      'columnWidthAsScreenWidthFraction';
  static const String columnWidthAsScreenWidthFractionColumnType = 'REAL';
  static const String columnHeightAsScreenWidthFractionColumnName =
      'columnHeightAsScreenWidthFraction';
  static const String columnHeightAsScreenWidthFractionColumnType = 'REAL';
  static const String columnFractionWidthForCollisionColumnName =
      'columnFractionWidthForCollision';
  static const String columnFractionWidthForCollisionColumnType = 'REAL';
  static const String columnFractionHeightForCollisionColumnName =
      'columnFractionHeightForCollision';
  static const String columnFractionHeightForCollisionColumnType = 'REAL';
  static const String columnHeightMinBoundFromScreenTopColumnName =
      'columnHeightMinBoundFromScreenTop';
  static const String columnHeightMinBoundFromScreenTopColumnType = 'REAL';
  static const String columnHeightMaxBoundFromScreenTopColumnName =
      'columnHeightMaxBoundFromScreenTop';
  static const String columnHeightMaxBoundFromScreenTopColumnType = 'REAL';
  static const String practiceModeColumnName = 'practiceMode';
  static const String practiceModeColumnType = 'INTEGER';
  static const String playMusicColumnName = 'playMusic';
  static const String playMusicColumnType = 'INTEGER';
  static const String musicVolumeColumnName = 'musicVolume';
  static const String musicVolumeColumnType = 'REAL';
  static const String skyBackgroundFractionScreenHeightColumnName =
      'skyBackgroundFractionScreenHeight';
  static const String skyBackgroundFractionScreenHeightColumnType = 'REAL';
  static const String groundBackgroundFractionScreenHeightColumnName =
      'groundBackgroundFractionScreenHeight';
  static const String groundBackgroundFractionScreenHeightColumnType = 'REAL';

  final int _defaultInitialHighScore = 0;

  Database _database;

  Map<String, User> _userData;

  void initialize() async {
    var databasesDirectoryPath = await getDatabasesPath();

    // Make sure the directory exists.
    try {
      await Directory(databasesDirectoryPath).create(recursive: true);
    } catch (_) {}

    // Open the database file.
    _database = await openDatabase(_databaseFilename);

    // Insert user data, calibration data and gameplay databases to database
    // file if missing. They should only need adding the first time the App is
    // run.
    await _insertUserDataDatabaseIfAbsent();
    await _insertCalibrationDataDatabaseIfAbsent();
    await _insertGameplayDataDatabaseIfAbsent();

    // Load user data (this should be small enough that there won't be issues
    // storing it in memory.
    await _loadUserData();

    // TODO: Delete eventually - just rebuilds database for debugging.
    await createUserIfAbsent('first', GameSettings().userModifiableSettings);
    await createUserIfAbsent('second', GameSettings().userModifiableSettings);
    await createUserIfAbsent('third', GameSettings().userModifiableSettings);

    updateHighScoreIfBetter('first', 1);
    updateHighScoreIfBetter('first', 20);
    updateHighScoreIfBetter('first', 10);
  }

  Future<bool> _databaseHasTable(String tableName) async {
    var tableNameColumns = await _database.query('sqlite_master',
        columns: ['name'], where: 'type = ?', whereArgs: ['table']);
    return tableNameColumns
        .any((nameColumn) => nameColumn['name'] == tableName);
  }

  Future<void> _insertUserDataDatabaseIfAbsent() async {
    if (await _databaseHasTable(_userDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_userDataDatabaseName '
        '($_idColumnName $_idColumnType PRIMARY KEY, '
        '$_highScoreColumnName $_highScoreColumnType, '
        '$_mostRecentActivityTimestampColumnName '
        '$_mostRecentActivityTimestampColumnType, '
        '$scrollVelocityInScreenWidthsPerSecondColumnName '
        '$scrollVelocityInScreenWidthsPerSecondColumnType,'
        '$flapVelocityInScreenHeightFractionPerSecondColumnName '
        '$flapVelocityInScreenHeightFractionPerSecondColumnType,'
        '$terminalVelocityInScreenHeightFractionPerSecondColumnName '
        '$terminalVelocityInScreenHeightFractionPerSecondColumnType,'
        '$cherrySpawnRatePerSecondColumnName '
        '$cherrySpawnRatePerSecondColumnType,'
        '$playMusicColumnName $playMusicColumnType,'
        '$musicVolumeColumnName $musicVolumeColumnType'
        ')');
  }

  Future<void> _insertCalibrationDataDatabaseIfAbsent() async {
    if (await _databaseHasTable(_calibrationDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_calibrationDataDatabaseName '
        '($_idColumnName $_idColumnType,'
        '$_calibrationValueColumnName $_calibrationValueColumnType, '
        '$_timestampMillisecondsSinceEpochColumnName '
        '$_timestampMillisecondsSinceEpochColumnType'
        ')');
  }

  Future<void> _insertGameplayDataDatabaseIfAbsent() async {
    if (await _databaseHasTable(_gameplayDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_gameplayDataDatabaseName '
        '($_gameStartTimestampColumnName $_gameStartTimestampColumnType '
        'PRIMARY KEY, '
        '$_gameEndTimestampColumnName $_gameEndTimestampColumnType, '
        '$_gameUserIdColumnName $_gameUserIdColumnType, '
        '$_gameScoreColumnName $_gameScoreColumnType)');
  }

  Future<UnmodifiableListView<User>> _loadUserData() async {
    var tableRows = await _database.query(_userDataDatabaseName);

    // TODO: Why is this done twice here?
    _userData = Map.fromIterable(tableRows,
        key: (row) => row[_idColumnName],
        value: (row) => User(row[_idColumnName], row[_highScoreColumnName],
            row[_mostRecentActivityTimestampColumnName]));

    List<User> userList = List.of(tableRows.map((row) {
      return User(row[_idColumnName], row[_highScoreColumnName],
          row[_mostRecentActivityTimestampColumnName]);
    }));

    return UnmodifiableListView(userList);
  }

  Future<bool> containsUserWithId(String id) async {
    return _userData.containsKey(id);
  }

  // Does nothing if called with a user ID for a user that already exists.
  // TODO: Consider doing something more robust when user already present.
  Future<void> createUserIfAbsent(
      String id, UserModifiableSettings userModifiableSettings) async {
    if (await containsUserWithId(id)) {
      return;
    }

    // Add to data loaded by object.
    User newUser = User(
        id, _defaultInitialHighScore, DateTime.now().millisecondsSinceEpoch);
    _userData[id] = newUser;

    // Add to database.
    await _database.insert(_userDataDatabaseName, {
      _idColumnName: newUser.id,
      _highScoreColumnName: newUser.highScore,
      _mostRecentActivityTimestampColumnName:
          newUser.mostRecentActivityTimestamp
    });
    updateUserSettings(id, userModifiableSettings);
  }

  // Will fail ungracefully if start timestamp already exists in table.
  // TODO: Do some more robust error handling.
  Future<void> insertDataFromSingleGame(int gameStartTimestamp,
      int gameEndTimestamp, String userId, int score) async {
    var preTableRows = await _database.query(_gameplayDataDatabaseName);
    preTableRows.forEach((entry) => print(entry));

    await _database.insert(_gameplayDataDatabaseName, {
      _gameStartTimestampColumnName: gameStartTimestamp,
      _gameEndTimestampColumnName: gameEndTimestamp,
      _gameUserIdColumnName: userId,
      _gameScoreColumnName: score
    });

    var postTableRows = await _database.query(_gameplayDataDatabaseName);
    postTableRows.forEach((entry) => print(entry));
  }

  Future<void> deleteUser(String id) async {
    _userData.remove(id);
    await _database.delete(_userDataDatabaseName,
        where: '$_idColumnName = ?', whereArgs: [id]);
  }

  UnmodifiableListView<User> getUserData() {
    return UnmodifiableListView(_userData.values);
  }

  // Should only be called on user that actually exists.
  // TODO: handle case where it is called with an invalid user
  User getUserWithId(String id) {
    return _userData[id];
  }

  void updateHighScoreIfBetter(String id, int score) {
    if (score <= _userData[id].highScore) {
      return;
    }

    // Update is user data for this object.
    _userData[id].highScore = score;

    // Update in the database.
    _database.update(_userDataDatabaseName, {_highScoreColumnName: score},
        where: '$_idColumnName = ?', whereArgs: [id]);
  }

  void updateUserSettings(
      String id, UserModifiableSettings userModifiableSettings) {
    _database.update(
        _userDataDatabaseName,
        {
          flapVelocityInScreenHeightFractionPerSecondColumnName:
              userModifiableSettings
                  .flapVelocityInScreenHeightFractionPerSecond,
          terminalVelocityInScreenHeightFractionPerSecondColumnName:
              userModifiableSettings
                  .terminalVelocityInScreenHeightFractionPerSecond,
          scrollVelocityInScreenWidthsPerSecondColumnName:
              userModifiableSettings.scrollVelocityInScreenWidthsPerSecond,
          cherrySpawnRatePerSecondColumnName:
              userModifiableSettings.cherrySpawnRatePerSecond,
          playMusicColumnName: userModifiableSettings.playMusic ? 0 : 1,
          musicVolumeColumnName: userModifiableSettings.musicVolume
        },
        where: '$_idColumnName = ?',
        whereArgs: [id]);
  }

  void updateUserMostRecentActivity(String id, int timestamp) {
    // TODO: Exception if timestamp is earlier than current value?
    _userData[id].mostRecentActivityTimestamp = timestamp;
    _database.update(_userDataDatabaseName,
        {_mostRecentActivityTimestampColumnName: timestamp},
        where: '$_idColumnName = ?', whereArgs: [id]);
  }

  void addCalibrationValue(String id, int value, int timestamp) async {
    print('*************************');
    print('Adding Calibration Value:');
    print('Before Addition:');
    var preTableRows = await _database.query(_calibrationDataDatabaseName);
    preTableRows.forEach((entry) => print(entry));

    await _database.insert(_calibrationDataDatabaseName, {
      _idColumnName: id,
      _calibrationValueColumnName: value,
      _timestampMillisecondsSinceEpochColumnName: timestamp,
    });

    print('After Addition:');
    var postTableRows = await _database.query(_calibrationDataDatabaseName);
    postTableRows.forEach((entry) => print(entry));
    print('*************************');
  }

  Future<UserModifiableSettings> getUserSettings(String userId) async {
    var tableRows = await _database.query(_userDataDatabaseName,
        columns: [
          flapVelocityInScreenHeightFractionPerSecondColumnName,
          terminalVelocityInScreenHeightFractionPerSecondColumnName,
          scrollVelocityInScreenWidthsPerSecondColumnName,
          cherrySpawnRatePerSecondColumnName,
          playMusicColumnName,
          musicVolumeColumnName
        ],
        where: '$_idColumnName = ?',
        whereArgs: [userId]);

    // TODO: Throw and exception if there is more than 1 element.
    var userSettingsValues = tableRows[0];

    return UserModifiableSettings(
        userSettingsValues[
            flapVelocityInScreenHeightFractionPerSecondColumnName],
        userSettingsValues[
            terminalVelocityInScreenHeightFractionPerSecondColumnName],
        userSettingsValues[scrollVelocityInScreenWidthsPerSecondColumnName],
        userSettingsValues[cherrySpawnRatePerSecondColumnName],
        userSettingsValues[playMusicColumnName] != 0,
        userSettingsValues[musicVolumeColumnName]);
  }
}
