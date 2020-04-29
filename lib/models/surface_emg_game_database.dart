import 'dart:collection';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gameplayground/models/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SurfaceEmgGameDatabase extends ChangeNotifier {
  final String _databaseFilename = 'surface_emg_game.db';

  final String _userDataDatabaseName = 'UserData';
  final String _gameplayDataDatabaseName = 'GameplayData';

  final String _idColumnName = 'id';
  final String _idColumnType = 'TEXT';
  final String _highScoreColumnName = 'highScore';
  final String _highScoreColumnType = 'INTEGER';
  final String _mostRecentActivityTimestampColumnName =
      'mostRecentActivityTimestamp';
  final String _mostRecentActivityTimestampColumnType = 'INTEGER';

  final String _gameStartTimestampColumnName = 'gameStartTimestamp';
  final String _gameStartTimestampColumnType = 'INTEGER';
  final String _gameEndTimestampColumnName = 'gameEndTimestamp';
  final String _gameEndTimestampColumnType = 'INTEGER';
  final String _gameUserIdColumnName = 'userId';
  final String _gameUserIdColumnType = 'TEXT';
  final String _gameScoreColumnName = 'score';
  final String _gameScoreColumnType = 'INTEGER';

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

    // Insert user data and gameplay databases to database file if missing. They
    // should only need adding the first time the App is run.
    await _insertUserDataDatabaseIfAbsent();
    await _insertGameplayDataDatabaseIfAbsent();

    // Load user data (this should be small enough that there won't be issues
    // storing it in memory.
    await _loadUserData();

    await createUserIfAbsent('first');
    await createUserIfAbsent('second');
    await createUserIfAbsent('third');

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
        '$_mostRecentActivityTimestampColumnType)');
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

    _userData = Map.fromIterable(tableRows,
        key: (row) => row[_idColumnName],
        value: (row) => User(row[_idColumnName], row[_highScoreColumnName]));

    List<User> userList = List.of(tableRows.map((row) {
      return User(row[_idColumnName], row[_highScoreColumnName]);
    }));

    return UnmodifiableListView(userList);
  }

  Future<bool> containsUserWithId(String id) async {
    return _userData.containsKey(id);
  }

  // Does nothing if called with a user ID for a user that already exists.
  // TODO: Consider doing something more robust when user already present.
  Future<void> createUserIfAbsent(String id) async {
    if (await containsUserWithId(id)) {
      return;
    }

    // Add to data loaded by object.
    User newUser = User(id, _defaultInitialHighScore);
    _userData[id] = newUser;

    // Add to database.
    await _database.insert(_userDataDatabaseName, {
      _idColumnName: newUser.id,
      _highScoreColumnName: newUser.highScore,
      _mostRecentActivityTimestampColumnName:
      DateTime
          .now()
          .millisecondsSinceEpoch
    });
  }

  // Will fail ungracefully if start timestamp already exists in table.
  // TODO: Do some more robust error handling.
  Future<void> insertDataFromSingleGame(int gameStartTimestamp,
      int gameEndTimestamp, String userId, int score) async {

    print('Before data insertion');
    var preTableRows = await _database.query(_gameplayDataDatabaseName);
    preTableRows.forEach((entry) => print(entry));
    print('*******************');

    await _database.insert(_gameplayDataDatabaseName, {
      _gameStartTimestampColumnName: gameStartTimestamp,
      _gameEndTimestampColumnName: gameEndTimestamp,
      _gameUserIdColumnName: userId,
      _gameScoreColumnName: score
    });

    print('After data insertion');
    var postTableRows = await _database.query(_gameplayDataDatabaseName);
    postTableRows.forEach((entry) => print(entry));
    print('*******************');
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
}
