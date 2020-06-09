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
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:provider/provider.dart';

import 'models/game_settings.dart';

class FlappyGame extends Game with HasWidgetsOverlay {
  static const String _cherryImagePath = 'targets/cherry.png';
  static const String _columnImagePath = 'obstacles/column.png';
  static const String _skyImagePath = 'backgrounds/sky.png';
  static const String _groundImagePath = 'backgrounds/ground.png';

  Size _screenSize;
  GameSettings _gameSettings;
  TargetController _targetController;
  BirdController _birdController;
  ColumnObstacleController _columnObstacleController;
  RepeatingBackgroundController _skyBackgroundController;
  RepeatingBackgroundController _grassBackgroundController;
  BuildContext _context;

  int _currentScore;
  int _highScore = 0;
  int _gameStartMillisecondsSinceEpoch;
  bool _isGameOver = false;
  bool _practiceMode;

  final String _gameOverMenuOverlayName = 'game_over_menu';
  final String _currentScoreOverlayName = 'current_score';
  final String _endGameOverlayName = 'end_game';

  FlappyGame(this._context, {practiceMode: false}) {
    _gameSettings =
        Provider.of<SessionDataModel>(_context, listen: false).gameSettings;
    _practiceMode = practiceMode;
    _initialize();
  }

  Size get screenSize => _screenSize;

  void _restartGame() {
    removeWidgetOverlay(_gameOverMenuOverlayName);
    _initialize();
    _isGameOver = false;
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
    Rect bgRect = Rect.fromLTWH(0, 0, _screenSize.width, _screenSize.height);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff576574);
    canvas.drawRect(bgRect, bgPaint);

    _callFunctionOnControllers((controller) => controller.render(canvas));
  }

  @override
  void resize(Size size) {
    _screenSize = size;
    super.resize(size);

    _callFunctionOnControllers((controller) => controller.resizeScreen(size));
  }

  @override
  void update(double time) {
    if (_isGameOver) {
      _stopMusic();
      return;
    }

    _callFunctionOnControllers((controller) => controller.update(time));

    bool columnCollisionDetected = _gameSettings.includeColumns
        ? _columnObstacleController
            .isCollidingWithObstacle(_birdController.getBirdPosition())
        : false;

    bool gameEndingGroundCollisionDetected =
        !_practiceMode && _birdController.isBirdOnGround();

    // If a collision is detected (and it is not in practice mode), end game.
    if (!_practiceMode &&
        (gameEndingGroundCollisionDetected || columnCollisionDetected)) {
      int gameEndMillisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;

      _birdController.killBird();
      _isGameOver = true;
      _highScore = max(_highScore, _currentScore);
      print(
          Provider.of<SessionDataModel>(_context, listen: false).currentUserId);
      _showGameOverMenu();

      _addGameDataToDatabase(_gameStartMillisecondsSinceEpoch,
          gameEndMillisecondsSinceEpoch, _currentScore);
    }

    int birdCollisionCount = _gameSettings.includeCherries
        ? _targetController.removeTargetsWithCollisionAndCalculateCount(
            _birdController.getBirdPosition())
        : 0;
    _currentScore += birdCollisionCount;
    _updateScoreCounter();
  }

  void _addGameDataToDatabase(int startTimestamp, int endTimestamp, int score) {
    // TODO: Actually store activation count, app version, and sensor data path.
    GameplayData gameplayData =
        GameplayData(startTimestamp, endTimestamp, score, 0, '', '');
    Provider.of<SessionDataModel>(_context, listen: false)
        .handleGameplayData(gameplayData);
  }

  void _showGameOverMenu() {
    addWidgetOverlay(
        _gameOverMenuOverlayName,
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton.extended(
                label: Text('Restart'),
                heroTag: 'restart_game',
                onPressed: () => _restartGame(),
              ),
              SizedBox(height: 20),
              FloatingActionButton.extended(
                label: Text('Main Menu'),
                heroTag: 'main_menu_button',
                onPressed: () {
                  Navigator.pop(this._context);
                },
              )
            ],
          ),
        ));
  }

  void _initialize() async {
    if (_gameSettings.playMusic) {
      Flame.bgm.play('background_music.mp3', volume: _gameSettings.musicVolume);
    }

    _birdController = BirdController(_gameSettings);

    // Sky background will take up entire width, and its height (in terms of
    // screen height fraction) will start from the top of the screen.
    Rect skyBackgroundLocation = Rect.fromLTWH(
        0.0, 0.0, 1.0, _gameSettings.skyBackgroundFractionScreenHeight);
    _skyBackgroundController = RepeatingBackgroundController(
        _skyImagePath,
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        skyBackgroundLocation);

    // Grass background will take up entire width. Its height (in terms of
    // screen height fraction) will start from the bottom of the screen.
    Rect groundBackgroundLocation = Rect.fromLTWH(
        0.0,
        1.0 - _gameSettings.groundBackgroundFractionScreenHeight,
        1.0,
        _gameSettings.groundBackgroundFractionScreenHeight);
    _grassBackgroundController = RepeatingBackgroundController(
        _groundImagePath,
        _gameSettings.scrollVelocityInScreenWidthsPerSecond,
        groundBackgroundLocation);

    if (_gameSettings.includeCherries) {
      // Region for cherry collision will be centered.
      Rect cherryRegionForCollision = Rect.fromLTWH(
          (1.0 - _gameSettings.cherryFractionWidthForCollision) / 2.0,
          (1.0 - _gameSettings.cherryFractionHeightForCollision) / 2.0,
          _gameSettings.cherryFractionWidthForCollision,
          _gameSettings.cherryFractionHeightForCollision);
      _targetController = TargetController(
          _gameSettings.scrollVelocityInScreenWidthsPerSecond,
          _cherryImagePath,
          cherryRegionForCollision,
          _gameSettings.cherryWidthAsScreenWidthFraction,
          _gameSettings.cherryHeightAsScreenWidthFraction,
          _gameSettings.cherryLocationMinBoundFromScreenTop,
          _gameSettings.cherryLocationMaxBoundFromScreenTop,
          _gameSettings.cherrySpawnRatePerSecond);
    }

    if (_gameSettings.includeColumns) {
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
          _columnImagePath,
          columnRegionForCollision,
          _gameSettings.columnWidthAsScreenWidthFraction,
          _gameSettings.columnHeightAsScreenWidthFraction,
          _gameSettings.columnHeightMinBoundFromScreenTop,
          _gameSettings.columnHeightMaxBoundFromScreenTop);
    }

    // TODO: Is this necessary, or potentially problematic?
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
  }

  void _updateScoreCounter() {
    removeWidgetOverlay(_currentScoreOverlayName);

    List<Widget> highScoreComponents = [
      SizedBox(height: 20),
      Text('Score: $_currentScore',
          style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
              fontSize: 54,
              decoration: TextDecoration.none)),
    ];
    if (!_practiceMode) {
      highScoreComponents.add(Text('High Score: $_highScore',
          style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
              fontSize: 24,
              decoration: TextDecoration.none)));
    }

    addWidgetOverlay(
        _currentScoreOverlayName,
        Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: highScoreComponents)));
  }

  void _addEndGameButton() {
    addWidgetOverlay(
        _endGameOverlayName,
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            FloatingActionButton.extended(
              label: Text('End Game'),
              heroTag: 'end_game_button',
              onPressed: () {
                _stopMusic();
                Navigator.pop(this._context);
              },
            ),
            SizedBox(height: 20),
          ]),
          SizedBox(width: 20),
        ]));
  }

  void _stopMusic() {
    Flame.bgm.stop();
  }

  void onTapDown(TapDownDetails details) {
    _birdController.onTapDown();
  }
}
