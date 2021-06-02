import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gameplayground/components/bird_controller.dart';
import 'package:gameplayground/components/column_obstacle_controller.dart';
import 'package:gameplayground/components/repeating_background_controller.dart';
import 'package:gameplayground/components/target_controller.dart';
import 'package:gameplayground/models/asset_loading_utils.dart';
import 'package:gameplayground/models/emg_recording.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';

class FlappyGame extends Game with HasWidgetsOverlay {
  Size _screenSize;
  GameSettings _gameSettings;
  TargetController _targetController;
  BirdController _birdController;
  ColumnObstacleController _columnObstacleController;
  RepeatingBackgroundController _skyBackgroundController;
  RepeatingBackgroundController _grassBackgroundController;
  BuildContext _context;

  int _currentScore;
  int _highScore;
  int _gameStartMillisecondsSinceEpoch;
  bool _isGameOver = false;
  bool _practiceMode;

  ThresholdedTriggerDataProcessor _dataProcessor;

  final String _gameOverMenuOverlayName = 'game_over_menu';
  final String _currentScoreOverlayName = 'current_score';
  final String _endGameOverlayName = 'end_game';

  final String _labelRestart = 'Restart';
  final String _labelMainMenu = 'Main Menu';
  final String _labelEndGame = 'End Game';

  final String _heroTagRestartGameButton = 'restart_game_button';
  final String _heroTagMainMenuButton = 'main_menu_button';
  final String _heroTagEndGameButton = 'end_game_button';

  FlappyGame(this._context, this._dataProcessor, {practiceMode: false}) {
    _gameSettings = _getSessionDataModel().gameSettings;
    _practiceMode = practiceMode;
    _initialize();
  }

  Size get screenSize => _screenSize;

  void _restartGame() {
    _initialize();
  }

  void _initialize() async {
    if (_gameSettings.playMusic) {
      _startMusic();
    }

    _highScore = _getSessionDataModel().currentUserHighScore;

    _birdController = BirdController(_gameSettings);
    _createSkyBackgroundController();
    _createGrassBackgroundController();

    if (_gameSettings.includeCherries) {
      _createCherryTargetController();
    }

    if (_gameSettings.includeColumns) {
      _createColumnTargetController();
    }

    resize(await Flame.util.initialDimensions());
    _callFunctionOnControllers(
        (controller) => controller.initialize(_screenSize));

    // Add score counter.
    _currentScore = 0;
    _gameStartMillisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    _updateScoreCounter();

    if (_practiceMode) {
      _addEndGameButton();
    }

    _isGameOver = false;

    _dataProcessor.startProcessing((_) {
      _birdController.onTapDown();
    }, logData: true);

    Future.delayed(Duration(seconds:5), () {_endGame();});
  }

  void _createSkyBackgroundController() {
    // Sky background will take up entire width, and its height (in terms of
    // screen height fraction) will start from the top of the screen.
    Rect skyBackgroundLocation = Rect.fromLTWH(
        0.0, 0.0, 1.0, _gameSettings.skyBackgroundFractionScreenHeight);
    _skyBackgroundController = RepeatingBackgroundController(
        AssetPaths.imageSkyBackground,
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        skyBackgroundLocation);
  }

  void _createGrassBackgroundController() {
    // Grass background will take up entire width. Its height (in terms of
    // screen height fraction) will start from the bottom of the screen.
    Rect groundBackgroundLocation = Rect.fromLTWH(
        0.0,
        1.0 - _gameSettings.groundBackgroundFractionScreenHeight,
        1.0,
        _gameSettings.groundBackgroundFractionScreenHeight);
    _grassBackgroundController = RepeatingBackgroundController(
        AssetPaths.imageGroundBackground,
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        groundBackgroundLocation);
  }

  void _createCherryTargetController() {
    // Region for cherry collision will be centered.
    Rect cherryRegionForCollision = Rect.fromLTWH(
        (1.0 - _gameSettings.cherryFractionWidthForCollision) / 2.0,
        (1.0 - _gameSettings.cherryFractionHeightForCollision) / 2.0,
        _gameSettings.cherryFractionWidthForCollision,
        _gameSettings.cherryFractionHeightForCollision);
    _targetController = TargetController(
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        AssetPaths.imageCherry,
        cherryRegionForCollision,
        _gameSettings.cherryWidthAsScreenWidthFraction,
        _gameSettings.cherryHeightAsScreenWidthFraction,
        _gameSettings.cherryLocationMinBoundFromScreenTop,
        _gameSettings.cherryLocationMaxBoundFromScreenTop,
        _gameSettings.cherrySpawnRatePerSecond);
  }

  void _createColumnTargetController() {
    // Region for column collision will be centered in the horizontal direction.
    // All of the region to not count for collisions in the vertical direction
    // will be taken off of the top.
    Rect columnRegionForCollision = Rect.fromLTWH(
        (1.0 - _gameSettings.columnFractionWidthForCollision) / 2.0,
        1.0 - _gameSettings.columnFractionHeightForCollision,
        _gameSettings.columnFractionWidthForCollision,
        _gameSettings.columnFractionHeightForCollision);
    _columnObstacleController = ColumnObstacleController(
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        AssetPaths.imageColumn,
        columnRegionForCollision,
        _gameSettings.columnWidthAsScreenWidthFraction,
        _gameSettings.columnHeightAsScreenWidthFraction,
        _gameSettings.columnHeightMinBoundFromScreenTop,
        _gameSettings.columnHeightMaxBoundFromScreenTop);
  }

  void _callFunctionOnControllers(Function function) {
    // Note that the order here is important if the function being called is
    // doing rendering because game objects stack on top of each other in the
    // ordered they're rendered.
    function(_skyBackgroundController);
    if (_gameSettings.includeColumns) {
      function(_columnObstacleController);
    }

    function(_grassBackgroundController);

    if (_gameSettings.includeCherries) {
      function(_targetController);
    }

    function(_birdController);
  }

  @override
  void render(Canvas canvas) {
    _callFunctionOnControllers((controller) => controller.render(canvas));
  }

  @override
  void resize(Size size) {
    _screenSize = size;
    super.resize(size);

    _callFunctionOnControllers(
        (controller) => controller.resizeScreen(_screenSize));
  }

  @override
  void update(double time) {
    if (_isGameOver) {
      return;
    }

    _callFunctionOnControllers((controller) => controller.update(time));

    bool columnCollisionDetected = _gameSettings.includeColumns
        ? _columnObstacleController
            .isCollidingWithObstacle(_birdController.getBirdPosition())
        : false;

    bool gameEndingGroundCollisionDetected =
        !_practiceMode && _birdController.isBirdOnGround();

    int birdCollisionCount = _gameSettings.includeCherries
        ? _targetController.removeTargetsWithCollisionAndCalculateCount(
            _birdController.getBirdPosition())
        : 0;
    _currentScore += birdCollisionCount;
    _updateScoreCounter();

    // If a collision is detected (and it is not in practice mode), end game.
    if (!_practiceMode &&
        (gameEndingGroundCollisionDetected || columnCollisionDetected)) {
      _endGame();
    }
  }

  void _endGame() {
    _dataProcessor.stopProcessing();
    int gameEndMillisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    _isGameOver = true;

    EmgRecording emgRecording = _dataProcessor.dataLog;
    GameplayData gameplayData = GameplayData(_gameStartMillisecondsSinceEpoch,
        gameEndMillisecondsSinceEpoch, _currentScore,_birdController.numFlaps,"",_dataProcessor.deviceName);
    Future<void> handleGameplayDataFuture = _getSessionDataModel()
        .handleGameplayData(gameplayData, _gameSettings, emgRecording)
        .then((_) {
      _dataProcessor.resetDataLog();
    });

    _birdController.killBird();
    _highScore = max(_highScore, _currentScore);
    _stopMusic();
    _showGameOverMenu(handleGameplayDataFuture);
  }

  void _showGameOverMenu(Future<void> canDisplayMenuFuture) {
    addWidgetOverlay(
        _gameOverMenuOverlayName,
        Center(
            child: FutureBuilder(
          future: canDisplayMenuFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FloatingActionButton.extended(
                    label: Text(_labelRestart),
                    heroTag: _heroTagRestartGameButton,
                    onPressed: () {
                      removeWidgetOverlay(_gameOverMenuOverlayName);
                      _restartGame();
                    },
                  ),
                  SizedBox(height: 20),
                  FloatingActionButton.extended(
                    label: Text(_labelMainMenu),
                    heroTag: _heroTagMainMenuButton,
                    onPressed: () {
                      Navigator.pop(this._context);
                    },
                  )
                ],
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        )));
  }

  void _updateScoreCounter() {
    removeWidgetOverlay(_currentScoreOverlayName);

    List<Widget> highScoreComponents = [
      SizedBox(height: 20),
      Center(
          child: Text('Score: $_currentScore',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 54,
                  decoration: TextDecoration.none))),
    ];
    if (!_practiceMode) {
      highScoreComponents.add(Center(
          child: Text('High Score: $_highScore',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  decoration: TextDecoration.none))));
    }

    addWidgetOverlay(
        _currentScoreOverlayName,
        Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: highScoreComponents));
  }

  void _addEndGameButton() {
    addWidgetOverlay(
        _endGameOverlayName,
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            FloatingActionButton.extended(
              label: Text(_labelEndGame),
              heroTag: _heroTagEndGameButton,
              onPressed: () {
                _stopMusic();
                _dataProcessor.stopProcessing();
                Navigator.pop(this._context);
              },
            ),
            SizedBox(height: 20),
          ]),
          SizedBox(width: 20),
        ]));
  }

  void _startMusic() {
    if (!Flame.bgm.isPlaying) {
      Flame.bgm.play(AssetPaths.musicBackgroundSong,
          volume: _gameSettings.musicVolume);
    }
  }

  void _stopMusic() {
    if (Flame.bgm.isPlaying) {
      Flame.bgm.stop();
    }
  }

  SessionDataModel _getSessionDataModel() {
    return Provider.of<SessionDataModel>(_context, listen: false);
  }

  void onTapDown(TapDownDetails details) {
    _birdController.onTapDown();
  }
}
