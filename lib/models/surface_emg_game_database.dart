import 'dart:collection';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gameplayground/models/calibration_data.dart';
import 'package:gameplayground/models/game_settings.dart';
import 'package:gameplayground/models/user.dart';
import 'package:sqflite/sqflite.dart';

// TODO: If the database read is fast enough, don't cache, it's confusing.
class SurfaceEmgGameDatabase extends ChangeNotifier {
  final String _databaseFilename = 'surface_emg_game.db';

  final String _userDataDatabaseName = 'UserData';
  final String _calibrationDataDatabaseName = 'CalibrationData';
  final String _gameplayDataDatabaseName = 'GameplayData';

  final String _columnTypeText = 'TEXT';
  final String _columnTypeInteger = 'INTEGER';
  final String _columnTypeReal = 'REAL';

  final int _defaultInitialHighScore = 0;

  Database _database;

  Future<void> initialize() async {
    var databasesDirectoryPath = await getDatabasesPath();

    // Make sure the directory exists.
    try {
      await Directory(databasesDirectoryPath).create(recursive: true);
    } catch (_) {}

    // Open the database file.
    _database = await openDatabase(_databaseFilename);

    // Insert user data, calibration data and gameplay data tables into database
    // if missing. They should only need adding the first time the App is run.
    await _insertUserDataTableIfAbsent();
    await _insertCalibrationDataTableIfAbsent();
    await _insertGameplayDataTableIfAbsent();
  }

  Future<bool> _tableExists(String tableName) async {
    var tableNameColumns = await _database.query('sqlite_master',
        columns: ['name'], where: 'type = ?', whereArgs: ['table']);
    return tableNameColumns
        .any((nameColumn) => nameColumn['name'] == tableName);
  }

  Future<void> _insertUserDataTableIfAbsent() async {
    if (await _tableExists(_userDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_userDataDatabaseName '
        '(${_DatabaseColumnNames.idColumnName} '
        '$_columnTypeText PRIMARY KEY, '
        '${_DatabaseColumnNames.highScoreColumnName} $_columnTypeInteger, '
        '${_DatabaseColumnNames.mostRecentActivityTimestampColumnName} '
        '$_columnTypeInteger, '
        '${_DatabaseColumnNames.deviceNameColumnName} '
        '$_columnTypeText,'
        '${_DatabaseColumnNames.scrollVelocityInScreenWidthsPerSecondColumnName} '
        '$_columnTypeReal,'
        '${_DatabaseColumnNames.flapVelocityInScreenHeightFractionPerSecondColumnName} '
        '$_columnTypeReal,'
        '${_DatabaseColumnNames.terminalVelocityInScreenHeightFractionPerSecondColumnName} '
        '$_columnTypeReal,'
        '${_DatabaseColumnNames.cherrySpawnRatePerSecondColumnName} '
        '$_columnTypeReal,'
        '${_DatabaseColumnNames.playMusicColumnName} $_columnTypeInteger,'
        '${_DatabaseColumnNames.musicVolumeColumnName} $_columnTypeReal'
        ')');
  }

  Future<void> _insertCalibrationDataTableIfAbsent() async {
    if (await _tableExists(_calibrationDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_calibrationDataDatabaseName '
        '(${_DatabaseColumnNames.idColumnName} $_columnTypeInteger,'
        '${_DatabaseColumnNames.calibrationValueColumnName} '
        '$_columnTypeInteger, '
        '${_DatabaseColumnNames.timestampMillisecondsSinceEpochColumnName} '
        '$_columnTypeInteger'
        ')');
  }

  Future<void> _insertGameplayDataTableIfAbsent() async {
    if (await _tableExists(_gameplayDataDatabaseName)) {
      return;
    }

    _database.execute('CREATE TABLE $_gameplayDataDatabaseName '
        '(${_DatabaseColumnNames.gameStartTimestampColumnName} '
        '$_columnTypeInteger PRIMARY KEY, '
        '${_DatabaseColumnNames.gameEndTimestampColumnName} '
        '$_columnTypeInteger, '
        '${_DatabaseColumnNames.gameUserIdColumnName} $_columnTypeText, '
        '${_DatabaseColumnNames.gameScoreColumnName} $_columnTypeInteger)'
        '${_DatabaseColumnNames.numFlapsColumnName} $_columnTypeInteger)');
  }

  Future<bool> containsUserWithId(String id) async {
    var userIds = await _database.query(_userDataDatabaseName,
        columns: [_DatabaseColumnNames.idColumnName],
        where: '${_DatabaseColumnNames.idColumnName} = ?',
        whereArgs: [id],
        limit: 1);

    return userIds.length > 0;
  }

  // Does nothing if called with a user ID for a user that already exists.
  // TODO: Consider doing something more robust when user already present.
  Future<void> createUserIfAbsent(
      String id, UserModifiableSettings userModifiableSettings) async {
    if (await containsUserWithId(id)) {
      return;
    }

    // Add to database.
    await _database.insert(_userDataDatabaseName, {
      _DatabaseColumnNames.idColumnName: id,
      _DatabaseColumnNames.highScoreColumnName: _defaultInitialHighScore,
      _DatabaseColumnNames.mostRecentActivityTimestampColumnName:
          DateTime.now().millisecondsSinceEpoch
    });

    updateUserGameSettings(id, userModifiableSettings);
  }

  // Will fail ungracefully if start timestamp already exists in table.
  // TODO: Do some more robust error handling.
  Future<void> insertDataFromSingleGame(int gameStartTimestamp,
      int gameEndTimestamp, String userId, int score, int numFlaps) async {
    await _database.insert(_gameplayDataDatabaseName, {
      _DatabaseColumnNames.gameStartTimestampColumnName: gameStartTimestamp,
      _DatabaseColumnNames.gameEndTimestampColumnName: gameEndTimestamp,
      _DatabaseColumnNames.gameUserIdColumnName: userId,
      _DatabaseColumnNames.gameScoreColumnName: score,
      _DatabaseColumnNames.numFlapsColumnName: numFlaps,
    });

    updateHighScoreIfBetter(userId, score);
  }

  Future<void> deleteUser(String id) async {
    await _database.delete(_userDataDatabaseName,
        where: '${_DatabaseColumnNames.idColumnName} = ?', whereArgs: [id]);
  }

  Future<UnmodifiableListView<User>> getUserData() async {
    var tableRows = _database.query(_userDataDatabaseName, columns: [
      _DatabaseColumnNames.idColumnName,
      _DatabaseColumnNames.highScoreColumnName,
      _DatabaseColumnNames.mostRecentActivityTimestampColumnName,
      _DatabaseColumnNames.deviceNameColumnName
    ]);

    return tableRows.then((List<Map<String, dynamic>> tableData) {
      return UnmodifiableListView(tableData.map((Map<String, dynamic> row) {
        return User(
            row[_DatabaseColumnNames.idColumnName],
            row[_DatabaseColumnNames.highScoreColumnName],
            row[_DatabaseColumnNames.mostRecentActivityTimestampColumnName],
            row[_DatabaseColumnNames.deviceNameColumnName]);
      }));
    });
  }

  // Should only be called on user that actually exists.
  // TODO: handle case where it is called with an invalid user
  Future<User> getUserWithId(String id) async {
    List<Map<String, dynamic>> userQueryData =
        await _database.query(_userDataDatabaseName,
            columns: [
              _DatabaseColumnNames.highScoreColumnName,
              _DatabaseColumnNames.mostRecentActivityTimestampColumnName,
              _DatabaseColumnNames.deviceNameColumnName
            ],
            where: '${_DatabaseColumnNames.idColumnName} = ?',
            whereArgs: [id],
            limit: 1);

    Map<String, dynamic> userData = userQueryData.first;

    return User(
        id,
        userData[_DatabaseColumnNames.highScoreColumnName],
        userData[_DatabaseColumnNames.mostRecentActivityTimestampColumnName],
        userData[_DatabaseColumnNames.deviceNameColumnName]);
  }

  Future<void> updateDeviceNameForUser(String id, String deviceName) {
    return _database.update(_userDataDatabaseName,
        {_DatabaseColumnNames.deviceNameColumnName: deviceName},
        where: '${_DatabaseColumnNames.idColumnName} = ?', whereArgs: [id]);
  }

  void updateHighScoreIfBetter(String id, int score) async {
    List<Map<String, dynamic>> userHighScoreData = await _database.query(
        _userDataDatabaseName,
        columns: [_DatabaseColumnNames.highScoreColumnName],
        where: '${_DatabaseColumnNames.idColumnName} = ?',
        whereArgs: [id],
        limit: 1);

    int userCurrentHighScore =
        userHighScoreData.first[_DatabaseColumnNames.highScoreColumnName];

    if (score <= userCurrentHighScore) {
      return;
    }

    // Update in the database.
    _database.update(_userDataDatabaseName,
        {_DatabaseColumnNames.highScoreColumnName: score},
        where: '${_DatabaseColumnNames.idColumnName} = ?', whereArgs: [id]);
  }

  void updateUserGameSettings(
      String id, UserModifiableSettings userModifiableSettings) {
    _database.update(
        _userDataDatabaseName,
        {
          _DatabaseColumnNames
                  .flapVelocityInScreenHeightFractionPerSecondColumnName:
              userModifiableSettings
                  .flapVelocityInScreenHeightFractionPerSecond,
          _DatabaseColumnNames
                  .terminalVelocityInScreenHeightFractionPerSecondColumnName:
              userModifiableSettings
                  .terminalVelocityInScreenHeightFractionPerSecond,
          _DatabaseColumnNames.scrollVelocityInScreenWidthsPerSecondColumnName:
              userModifiableSettings.scrollVelocityInScreenWidthsPerSecond,
          _DatabaseColumnNames.cherrySpawnRatePerSecondColumnName:
              userModifiableSettings.cherrySpawnRatePerSecond,
          _DatabaseColumnNames.playMusicColumnName:
              userModifiableSettings.playMusic ? 0 : 1,
          _DatabaseColumnNames.musicVolumeColumnName:
              userModifiableSettings.musicVolume
        },
        where: '${_DatabaseColumnNames.idColumnName} = ?',
        whereArgs: [id]);
  }

  void updateUserMostRecentActivity(String id, int timestamp) {
    // TODO: Exception if timestamp is earlier than current value?
    _database.update(_userDataDatabaseName,
        {_DatabaseColumnNames.mostRecentActivityTimestampColumnName: timestamp},
        where: '${_DatabaseColumnNames.idColumnName} = ?', whereArgs: [id]);
  }

  Future<void> addCalibrationValue(String id, int value, int timestamp) async {
    await _database.insert(_calibrationDataDatabaseName, {
      _DatabaseColumnNames.idColumnName: id,
      _DatabaseColumnNames.calibrationValueColumnName: value,
      _DatabaseColumnNames.timestampMillisecondsSinceEpochColumnName: timestamp,
    });
  }

  Future<UserCalibrationData> getMostRecentUserCalibrationValue(
      String id) async {
    var tableRows = await _database.query(_calibrationDataDatabaseName,
        columns: [
          _DatabaseColumnNames.calibrationValueColumnName,
          _DatabaseColumnNames.timestampMillisecondsSinceEpochColumnName
        ],
        where: '${_DatabaseColumnNames.idColumnName} = ?',
        whereArgs: [id],
        orderBy:
            '${_DatabaseColumnNames.timestampMillisecondsSinceEpochColumnName}');
    if (tableRows.isEmpty) {
      return UserCalibrationData.buildNoValue();
    }

    return UserCalibrationData.buildWithValue(
        tableRows.last[_DatabaseColumnNames.calibrationValueColumnName],
        tableRows.last[
            _DatabaseColumnNames.timestampMillisecondsSinceEpochColumnName]);
  }

  Future<UserModifiableSettings> getUserSettings(String userId) async {
    var tableRows = await _database.query(_userDataDatabaseName,
        columns: [
          _DatabaseColumnNames
              .flapVelocityInScreenHeightFractionPerSecondColumnName,
          _DatabaseColumnNames
              .terminalVelocityInScreenHeightFractionPerSecondColumnName,
          _DatabaseColumnNames.scrollVelocityInScreenWidthsPerSecondColumnName,
          _DatabaseColumnNames.cherrySpawnRatePerSecondColumnName,
          _DatabaseColumnNames.playMusicColumnName,
          _DatabaseColumnNames.musicVolumeColumnName
        ],
        where: '${_DatabaseColumnNames.idColumnName} = ?',
        whereArgs: [userId]);

    // TODO: Throw and exception if there is more than 1 element.
    var userSettingsValues = tableRows.first;

    return UserModifiableSettings(
        userSettingsValues[_DatabaseColumnNames
            .flapVelocityInScreenHeightFractionPerSecondColumnName],
        userSettingsValues[_DatabaseColumnNames
            .terminalVelocityInScreenHeightFractionPerSecondColumnName],
        userSettingsValues[_DatabaseColumnNames
            .scrollVelocityInScreenWidthsPerSecondColumnName],
        userSettingsValues[
            _DatabaseColumnNames.cherrySpawnRatePerSecondColumnName],
        userSettingsValues[_DatabaseColumnNames.playMusicColumnName] != 0,
        userSettingsValues[_DatabaseColumnNames.musicVolumeColumnName]);
  }
}

class _DatabaseColumnNames {
  static const String idColumnName = 'id';
  static const String highScoreColumnName = 'highScore';
  static const String mostRecentActivityTimestampColumnName =
      'mostRecentActivityTimestamp';
  static const String timestampMillisecondsSinceEpochColumnName =
      'timestampMillisecondsSinceEpoch';
  static const String calibrationValueColumnName = 'calibrationValue';
  static const String deviceNameColumnName = 'deviceName';

  static const String gameStartTimestampColumnName = 'gameStartTimestamp';
  static const String gameEndTimestampColumnName = 'gameEndTimestamp';
  static const String gameUserIdColumnName = 'userId';
  static const String gameScoreColumnName = 'score';
  static const String numFlapsColumnName = 'numFlaps';

  static const String flapVelocityInScreenHeightFractionPerSecondColumnName =
      'flapVelocityInScreenHeightFractionPerSecond';
  static const String
      terminalVelocityInScreenHeightFractionPerSecondColumnName =
      'terminalVelocityInScreenHeightFractionPerSecond';
  static const String scrollVelocityInScreenWidthsPerSecondColumnName =
      'scrollVelocityInScreenWidthsPerSecond';
  static const String includeCherriesColumnName = 'includeCherries';
  static const String cherrySpawnRatePerSecondColumnName =
      'cherrySpawnRatePerSecond';
  static const String cherryWidthAsScreenWidthFractionColumnName =
      'cherryWidthAsScreenWidthFraction';
  static const String cherryHeightAsScreenWidthFractionColumnName =
      'cherryHeightAsScreenWidthFraction';
  static const String cherryFractionWidthForCollisionColumnName =
      'cherryFractionWidthForCollision';
  static const String cherryFractionHeightForCollisionColumnName =
      'cherryFractionHeightForCollision';
  static const String cherryLocationMinBoundFromScreenTopColumnName =
      'cherryLocationMinBoundFromScreenTop';
  static const String cherryLocationMaxBoundFromScreenTopColumnName =
      'cherryLocationMaxBoundFromScreenTop';
  static const String includeColumnsColumnName = 'includeColumns';
  static const String columnSpawnRatePerSecondColumnName =
      'columnSpawnRatePerSecond';
  static const String columnWidthAsScreenWidthFractionColumnName =
      'columnWidthAsScreenWidthFraction';
  static const String columnHeightAsScreenWidthFractionColumnName =
      'columnHeightAsScreenWidthFraction';
  static const String columnFractionWidthForCollisionColumnName =
      'columnFractionWidthForCollision';
  static const String columnFractionHeightForCollisionColumnName =
      'columnFractionHeightForCollision';
  static const String columnHeightMinBoundFromScreenTopColumnName =
      'columnHeightMinBoundFromScreenTop';
  static const String columnHeightMaxBoundFromScreenTopColumnName =
      'columnHeightMaxBoundFromScreenTop';
  static const String practiceModeColumnName = 'practiceMode';
  static const String playMusicColumnName = 'playMusic';
  static const String musicVolumeColumnName = 'musicVolume';
  static const String skyBackgroundFractionScreenHeightColumnName =
      'skyBackgroundFractionScreenHeight';
  static const String groundBackgroundFractionScreenHeightColumnName =
      'groundBackgroundFractionScreenHeight';
}
